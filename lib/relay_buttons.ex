defmodule Relay.Buttons do
  alias Relay.Buttons.Monitor
  use GenServer
  require Logger

  # buttons:  1,  2,  3,  4
  @pins     [20, 21, 26, 16]

  def start_link() do
    Logger.info "Relay.Buttons handler starting..."
    GenServer.start_link __MODULE__, nil
  end

  def init(nil) do
    for pin <- @pins do
      Monitor.start_link pin, self()
    end
    {:ok, nil}
  end

  def handle_info({     _, 0}, nil), do: {:noreply, nil}
  def handle_info({button, 1}, nil) do
    Util.find_value_index(@pins, button) |> Relay.toggle
    {:noreply, nil}
  end
end


defmodule Relay.Buttons.Monitor do
  import Keyword, only: [put: 3]

  def start_link(pin_number, parent) do
    state = [
      pin_pid: nil,
      pin_number: pin_number,
      parent: parent,
      prev_val: 0
    ]
    spawn_link __MODULE__, :init, [state]
  end

  def init(state) do
    {:ok, btn_pid} = Gpio.start_link state[:pin_number], :input

    state
    |> put(:pin_pid, btn_pid)
    |> loop()
  end

  def loop(state) do
    val = Gpio.read state[:pin_pid]

    if val != state[:prev_val], do:
      send state[:parent], {state[:pin_number], val}

    Util.wait 200

    state
    |> put(:prev_val, val)
    |> loop()
  end
end
