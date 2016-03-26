defmodule Util do
  defmodule Queue do
    def add([a, b, _], d), do: [d, a, b]
    def add([a, b], c), do: [c, a, b]
    def add([a], b), do: [b, a]
    def add([], a), do: [a]
  end
  def id(x), do: x
end

defmodule Planties do
  use Application
  import Supervisor.Spec

  def start(_type, _args) do
    :net_adm.ping :mon@f21
    case :net_adm.ping :planties@raspberrypi do
      :pang -> IO.inspect "We're not on raspberry and planties not running."
      _     -> nil
    end

    children = [
      worker(Humidity, [])
    ]

    children = if Mix.env == :pi do
      [worker(LED, []) | children]
    else
      children
    end

    IO.inspect children
    Supervisor.start_link children, strategy: :one_for_one, name: Planties
  end

end

defmodule LED do
  @name {:global, LED}
  @dir "/sys/class/gpio"
  @pin "18"

  use GenServer

  def start_link() do
    :pi = Mix.env
    GenServer.start_link __MODULE__, nil, name: @name
  end

  def blink(time) do
    GenServer.call @name, {:blink, time}
  end

  def handle_call({:blink, time}, _from, state) do
    val_file = "#{@dir}/gpio#{@pin}/value"
    File.write! val_file, "1"
    receive do after time -> nil end
    File.write! val_file, "0"
    {:reply, nil, state}
  end

  def export() do
    # File.write! @dir <> "/export", "18"
    File.write! @dir <> "/gpio18/direction", "out"
  end
end


defmodule Humidity do
  use GenServer
  @agent {:global, :humidity}

  def get() do
    GenServer.call(__MODULE__, :get)
  end

  def start_link() do
    if Mix.env == :pi do
      LED.export()
      Kernel.spawn_link HumiditySensor, :main, []
    end
    GenServer.start_link __MODULE__, [], name: __MODULE__
  end

  def handle_call(_msg, _from, state) do
    val = Agent.get @agent, Util, :id, []
    {:reply, val, state}
  end
end


defmodule HumiditySensor do
  @adc_id 0x6A
  @agent {:global, :humidity}


  def print_command(<<
      rdy    :: size(1),
      chan   :: size(2),
      oc     :: size(1),
      sample :: size(2),
      pga    :: size(2)
  >>) do
    IO.inspect [rdy, chan, oc, sample, pga]
  end

  def make_command(chan), do: <<
    0    :: size(1),
    chan :: size(2),
    1    :: size(1),
    2    :: size(2),
    0    :: size(2)
  >>

  def main() do
    GenServer.start_link Agent.Server, fn () -> 0 end, name: @agent
    IO.inspect "Starting I2C handling..."
    {:ok, pid} = I2c.start_link("i2c-1", @adc_id)
    loop(pid, 0)
  end


  def update_val(prev_val, val), do: val

  def loop(pid, state) do
    I2c.write(pid, make_command(1))
    << _sign :: size(1),
       val   :: size(15),
       _conf :: size(8) >> = I2c.read(pid, 3)

    # see:
    # http://www.python.rk.edu.pl/w/p/komunikacja-i2c-pomiedzy-raspberry-pi-przetwornikiem-analogowo-cyfrowym/
    # http://ww1.microchip.com/downloads/en/DeviceDoc/22088b.pdf
    # https://github.com/fhunleth/elixir_ale
    # https://github.com/abelectronicsuk/bbb/blob/master/adcpiv2/adc.py
    val = (val * 0.000154 * 10000)
    Agent.update @agent, HumiditySensor, :update_val, [val]

    receive do after 1300 -> nil end
    loop(pid, state)
  end
end
