defmodule Ir do
  @moduledoc """
  This module depends on correctly configured lirc.
  """
  use GenServer

  defmodule State do
    defstruct port: nil, listeners: []
  end

  @global_name {:global, :ir}
  @dev "/dev/lirc0"

  def start_link() do
    case Mix.env do
      :pi ->
        GenServer.start_link __MODULE__, %State{}, name: @global_name
      _ ->
        raise "Ir server can only run on Raspberry!"
    end
  end

  def get() do
    GenServer.call @global_name, :get
  end

  def subscribe(pid) do
    GenServer.call @global_name, {:register, self()}
  end


  # Server section
  # ----------------------------------------------------------------------------

  def init(state) do
    port = Port.open {:spawn, "ircat myprog"}, line: 10
    IO.inspect [port, state]
    {:ok, %State{state | port: port}}
  end

  def handle_call({:register, pid}, _from, state) do
    IO.inspect state.listeners
    {:reply, :ok, %State{state | listeners: [pid | state.listeners]}}
  end

  def handle_info({port, {:data, {_, msg}}}, state) do
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
  use GenServer

  def start_link() do
    GenServer.start_link __MODULE__, nil, []
  end

  def init(nil) do
    Ir.subscribe self()
    {:ok, nil}
  end

  def handle_info({:ir, txt}, state) do
    IO.inspect txt
    {:noreply, state}
  end
end
