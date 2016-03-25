defmodule Planties do
  use Supervisor

  def start(_type, _args) do
    :net_adm.ping :mon@f21
    case :net_adm.ping :planties@raspberrypi do
      :pang -> IO.inspect "We're not on raspberry and planties not running."
      _     -> nil
    end

    children = [
      worker(HumidityGetter, [])
    ]

    IO.inspect children
    Supervisor.start_link children, strategy: :one_for_one, name: Planties
  end

end

defmodule HumidityGetter do
  use GenServer
  @agent {:global, :humidity}

  def get() do
    GenServer.call(__MODULE__, :get)
  end

  def start_link() do
    if Mix.env == :pi do
      Kernel.spawn_link Humidity, :main, []
    end
    GenServer.start_link __MODULE__, [], name: __MODULE__
  end

  def ident(x), do: x

  def handle_call(_msg, _from, state) do
    val = Agent.get @agent, HumidityGetter, :ident, []
    {:reply, val, state}
  end
end


defmodule Humidity do
  @adc_id 0x6A
  @agent {:global, :humidity}

  def make_command(chan) do
    << 0 :: size(1),
    chan :: size(2),
    1 :: size(1),
    2 :: size(2),
    0 :: size(2) >>
  end

  def print_command(<< rdy :: size(1),
                    chan :: size(2),
                    oc :: size(1),
                    sample :: size(2),
                    pga :: size(2) >>) do
    IO.inspect [rdy, chan, oc, sample, pga]
  end

  def main() do
    GenServer.start_link(
      Agent.Server, fn () -> 0 end, name: @agent
    )

    IO.inspect "Writing"
    {:ok, pid} = I2c.start_link("i2c-1", @adc_id)

    loop(pid)
  end

  def loop(pid) do
    I2c.write(pid, make_command(1))
    << sign :: size(1),
       val  :: size(15),
       conf :: size(8) >> = I2c.read(pid, 3)

    # see:
    # http://www.python.rk.edu.pl/w/p/komunikacja-i2c-pomiedzy-raspberry-pi-przetwornikiem-analogowo-cyfrowym/
    # http://ww1.microchip.com/downloads/en/DeviceDoc/22088b.pdf
    # https://github.com/fhunleth/elixir_ale
    # https://github.com/abelectronicsuk/bbb/blob/master/adcpiv2/adc.py
    val = (val * 0.000154 * 10000)

    Agent.update(@agent, fn (_) -> val end)
    receive do after 1300 -> nil end
    loop(pid)
  end
end
