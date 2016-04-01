defmodule Ir do
  @moduledoc """
  This module opens a port to `ircat` program, which prints IR signal codes as
  they appear. The module maintains a list of subscribers and forwards each
  received signal to all listeners.

  This module depends on correctly configured lirc, especially `lircd.conf` and
  `.lircrc` need to be present. The former you may generate using irrecord:

      sudo irrecord -d /dev/lirc0 /etc/lirc/lircd.conf

  The latter is a mapping from signal codes to human-readable strings and you
  have to write it by hand.
  """
  use GenServer
  use Util

  @global_name {:global, :ir}
  @dev "/dev/lirc0"

  defmodule State do
    defstruct port: nil, listeners: []
  end

  defpistart "Ir" do
    GenServer.start_link __MODULE__, %State{}, name: @global_name
  end


  def subscribe(pid) do
    GenServer.call @global_name, {:subscribe, pid}
  end

  def unsubscribe(pid) do
    GenServer.call @global_name, {:unsubscribe, pid}
  end


  # Server section
  # ----------------------------------------------------------------------------

  def init(state) do
    port = Port.open {:spawn, "ircat myprog"}, line: 10
    {:ok, %State{state | port: port}}
  end


  def handle_call({:subscribe, pid}, _from, state) do
    {:reply, :ok, %State{state | listeners: [pid | state.listeners]}}
  end
  def handle_call({:unsubscribe, pid}, _from, state) do
    {:reply, :ok, %State{state | listeners: state.listeners -- [pid]}}
  end


  def handle_info({_port, {:data, {_, msg}}}, state) do
    for pid <- state.listeners do
      send pid, {:ir, msg}
    end
    {:noreply, state}
  end
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end


defmodule Ir.Mon do
  @moduledoc """
      The simplest possible monitor for incoming IR signals.

      TODO: investigate gen_event and decide if it's worth rewriting
  """
  use GenServer
  require Logger

  def start_link(), do: GenServer.start_link __MODULE__, nil, []
  def stop(pid),    do: GenServer.call pid, :die


  # Server section
  # ----------------------------------------------------------------------------
  def init(nil) do
    Logger.debug "Ir.Mon starting..."
    Ir.subscribe self()
    {:ok, nil}
  end

  def handle_call(:die, _from, state) do
    {:stop, :normal, :ok, state}
  end

  def handle_info({:ir, txt}, state) do
    IO.inspect txt
    {:noreply, state}
  end

  def terminate(_reason, _state) do
    Logger.debug "Ir.Mon terminating..."
    Ir.unsubscribe self()
  end
end
