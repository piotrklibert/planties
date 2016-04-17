defmodule Fan do
  use Util
  use GenServer

  require Logger

  @engine 21
  @chan1 16
  @chan2 20

  @global_name {:global, :fan}

  defpistart "Fan" do
    Logger.info(
      "Fan controller starting on pins #{@engine}, #{@chan1}, #{@chan2}..."
    )

    Pins.set [{@engine, 0},
              {@chan1,  1},
              {@chan2,  0}]

    GenServer.start_link __MODULE__, nil, name: @global_name
  end

  def on(),       do: GenServer.call(@global_name, {:set_state, :on})
  def off(),      do: GenServer.call(@global_name, {:set_state, :off})

  def state(),    do: GenServer.call(@global_name, :get_state)
  def power(val), do: GenServer.call(@global_name, {:set_power, val})

  # Server section
  # ----------------------------------------------------------------------------

  def init(nil) do
    {:ok, pid} = PWM.start_link(@engine)
    {:ok, %{pid: pid}}
  end

  def handle_call(:get_state, _from, state) do
    %PWM.St{pin_state: is_on?, power: power} = PWM.get(state.pid)
    {:reply, {is_on?, power}, state}
  end

  def handle_call({:set_power, power}, _from, state) do
    state.pid |> PWM.set_power(power)
    {:reply, :ok, state}
  end

  def handle_call({:set_state, is_on?}, _from, state) do
    state.pid |> PWM.set_state(is_on?)
    {:reply, :ok, state}
  end
end
