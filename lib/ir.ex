defmodule Ir do
  @moduledoc """
  This module depends on correctly configured lirc.

  TODO: add lirc-related things to Ansible deployment
  """
  use GenServer

  defmodule State do
    defstruct port: nil, messages: [], listeners: []
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

  # Server section
  # ----------------------------------------------------------------------------

  def init(state) do
    port = Port.open {:spawn, "ircat myprog"}, line: 50
    {:ok, %State{state | port: port}}
  end

  def handle_call(_msg, _from, state) do
    {:reply, state.messages, state}
  end

  def handle_info({port, {:data, {_, msg}}}, state) do
    {:noreply, %State{state | messages: [msg | state.messages]}}
  end
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
