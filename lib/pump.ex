defmodule Pump do
  use Util
  use GenServer

  require Logger

  @engine 13
  @chan1  19
  @chan2  26

  @global_name {:global, :pump}
  @dir "/sys/class/gpio"

  defpistart "Pump" do
    Logger.info(
      "Pump controller starting on pins #{@engine}, #{@chan1}, #{@chan2}..."
    )

    Pin.set [{@engine, 0},
             {@chan1,  1},
             {@chan2,  0}]

    GenServer.start_link __MODULE__, nil, name: @global_name
  end

  def on(),       do: GenServer.call(@global_name, {:set_state, :on})
  def off(),      do: GenServer.call(@global_name, {:set_state, :off})
  def power(val), do: GenServer.call(@global_name, {:set_power, val})

  # Server section
  # ----------------------------------------------------------------------------

  def init(nil) do
    {:ok, pid} = PWM.start_link(@engine)
    {:ok, %{pid: pid}}
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


defmodule PWM do
  use GenServer
  require Logger

  defmodule St do
    defstruct state: :off, power: 15, pin: nil
  end

  def start_link(pin) do
    Logger.info "PWM starting on #{pin} pin"
    GenServer.start_link __MODULE__, %St{pin: pin}
  end

  def get(pid),              do: GenServer.call(pid, :get)
  def set_power(pid, power), do: GenServer.call(pid, {:power, power})
  def set_state(pid, state), do: GenServer.call(pid, {:state, state})


  # Server section
  # ----------------------------------------------------------------------------

  def init(state) do
    spawn_link PWM.Cycle, :loop, [self()]
    {:ok, state}
  end


  def handle_call(:get, _from, state), do: {:reply, state, state}

  ### Power Setter
  def handle_call({:power, power}, _from, state) do
    state = %St{state | power: power}
    Logger.info("Setting power value to #{power}")
    {:reply, state, state}
  end

  ### State Setter
  def handle_call({:state, is_on?}, _from, state) do
    state = %St{state | state: is_on?}
    Logger.info("Setting state to #{is_on?}")
    {:reply, state, state}
  end
end


defmodule PWM.Cycle do
  @moduledoc """
  This module implements Pulse Width Modulation.
  """
  import Util

  @cycle 100

  def loop(parent) do
    %PWM.St{power: power, state: state, pin: pin} = PWM.get(parent)
    case state do
      :off ->
        wait(@cycle)
        loop(parent)

      :on ->
        pulse_time = @cycle * (power / 100) |> trunc
        Pin.on(pin);  wait(pulse_time)
        Pin.off(pin); wait(@cycle - pulse_time)
        loop(parent)
    end
  end
end
