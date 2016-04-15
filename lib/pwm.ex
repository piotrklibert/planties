defmodule PWM do
  use GenServer
  require Logger


  defmodule St do
    defstruct
        pin: nil,               # an int, number of the pin
        pin_state: :off,        # :on or :off
        power: 15               # an int, in 1 .. 101 range, interpreted as
                                # percentage
  end


  @doc "Start a PWM process and attach it to the pin with given pin number."
  def start_link(pin_num) do
    Logger.info "PWM starting on #{pin_num} pin"
    GenServer.start_link __MODULE__, %St{pin: pin_num}
  end

  def get(pid),              do: GenServer.call(pid, :get)

  # Power Setters
  def full(pid),             do: GenServer.call(pid, {:power, 100})
  def half(pid),             do: GenServer.call(pid, {:power, 50})
  def slow(pid),             do: GenServer.call(pid, {:power, 15})
  def set_power(pid, power), do: GenServer.call(pid, {:power, power})

  # State - aka switch on and off - Setters
  def on(pid),               do: set_state(:on)
  def off(pid),              do: set_state(:off)
  def set_state(pid, state), do: GenServer.call(pid, {:pin_state, state})


  # Server section
  # ----------------------------------------------------------------------------

  def init(state) do
    alias PWM.Cycle
    Cycle.start_link(self)
    {:ok, state}
  end


  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  ### Power Setter
  def handle_call({:power, power}, _from, state) do
    state = %St{state | power: power}
    Logger.info("Setting power value to #{power}")
    {:reply, state, state}
  end

  ### State Setter
  def handle_call({:pin_state, pin_state}, _from, state) do
    state = %St{state | pin_state: pin_state}
    Logger.info("Setting state to #{is_on?}")
    {:reply, state, state}
  end
end


defmodule PWM.Cycle do
  @moduledoc """
  This module implements Pulse Width Modulation timer. It takes a PID of a PWM
  server as and argument and then sends messages to that PID in intervals
  defined by the PWM state and power settings.
  """
  import Util

  @cycle 100

  def start_link(pwm_pid) do: spawn_link(PWM.Cycle, :loop, [pwm_pid])

  def loop(pwm_pid) do
    %PWM.St{power: power, pin_state: state, pin: pin} = PWM.get(pwm_pid)
    case state do
      :off ->
        wait(@cycle)
        loop(pwm_pid)

      :on ->
        pulse_time = @cycle * (power / 100) |> trunc
        Pins.on(pin);  wait(pulse_time)
        Pins.off(pin); wait(@cycle - pulse_time)
        loop(pwm_pid)
    end
  end
end
