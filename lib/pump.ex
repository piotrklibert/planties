defmodule Pump.PWM do
  require Logger
  use GenServer
  @cycle 100

  defmodule St do
    defstruct state: :off, power: 25, pin: nil
  end

  def start_link(pin) do
    IO.inspect "PWM pin: #{pin}"
    GenServer.start_link __MODULE__, %St{pin: pin}
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  def set_power(pid, power) do
    GenServer.call pid, {:power, power}
  end

  def init(state) do
    pid = self()
    # spawn_link fn () -> loop(pid) end
    spawn_link Pump.PWM.Loop, :loop, [pid]
    {:ok, state}
  end

  defmodule Loop do
    @cycle 100

    def loop(parent) do
      import Util
      state = Pump.PWM.get(parent)
      pulse_time = @cycle * (state.power / 100) |> trunc

      turn_on(Util.gpio_path state.pin)
      wait pulse_time

      turn_off(Util.gpio_path state.pin)
      wait(@cycle - pulse_time)

      loop(parent)
    end
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:power, power}, _from, state) do
    {:reply, power, %St{state | power: power}}
  end

end

defmodule Pump do
  require Logger
  use GenServer

  use Util

  @engine 21
  @chan1  26
  @chan2  20

  @global_name {:global, :pump}
  @dir "/sys/class/gpio"

  defpistart "Pump" do
    Logger.info "Pump controller starting..."

    Util.set_pins [
      {@engine, 0},
      {@chan1,  0},
      {@chan2,  1}
    ]

    GenServer.start_link __MODULE__, nil, name: @global_name
  end

  def power(val) do
    GenServer.call(@global_name, {:power, val})
  end

  def off() do
    power(0)
  end
  def on() do
    power(100)
  end

  # Server section
  # ----------------------------------------------------------------------------

  def init(nil) do
    {:ok, pid} = Pump.PWM.start_link(@engine)
    {:ok, %{pid: pid}}
  end

  def handle_call({:power, power}, _from, state) do
    Pump.PWM.set_power state.pid, power
    {:reply, :ok, state}
  end

  def handle_call(:off, _from, state) do
    {:reply, :ok, state}
  end

end
