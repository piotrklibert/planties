defmodule Humidity do
  @moduledoc """
  See [1] for the Anolog/Digital Converter details. We use [2] as a way of
  communicating with I2C device, it needs i2c support to be enabled in the
  kernel.

  I couldn't find any data on the humidity sensor itself, other than the wetter
  the soil, the higher voltage it outputs.

  [1] http://ww1.microchip.com/downloads/en/DeviceDoc/22088b.pdf
  [2] https://github.com/fhunleth/elixir_ale
  """
  use GenServer
  use Bitwise

  require Logger

  @global_name {:global, :humidity}

  @adc_id 0x6A
  @lsb 0.000_062_5  # A/D conversion resolution (in Volts)
  @len 16           # length of the value returned by ADC in bits


  def start_link() do
    Logger.info "Starting I2C handling..."
    {:ok, pid} = I2c.start_link("i2c-1", @adc_id)
    GenServer.start_link(__MODULE__, pid, name: @global_name)
  end

  def get() do
    (GenServer.call @global_name, :get) |> Float.round(3)
  end


  # Server API

  def handle_call(:get, _from, i2c_pid) do
    I2c.write i2c_pid, config(0) # write/send a single byte
    resp = I2c.read i2c_pid, 3   # read 3 bytes

    <<val :: size(16), _conf :: size(8)>> = resp
    <<sign :: size(1), _ :: size(15)>> = <<val :: size(16)>>

    val = if sign == 0 do
      val
    else
      # See: https://en.wikipedia.org/wiki/Two%27s_complement
      0xFFFF - val + 1
    end
    input_voltage = val * @lsb  # convert to Volts
    {:reply, input_voltage, i2c_pid}
  end

  def config(chan), do: <<
    0    :: size(1),     # ignored in continuous mode
    chan :: size(2),     # number of a channel to query
    1    :: size(1),     # 'o'ne-shot (0) or 'c'ontinuous mode (1)
    2    :: size(2),     # how many bits to use for transfer, 2 means 16 bits
    0    :: size(2)      # Programmable Gain Amplifier, 0 means 1x amplification
  >>
end
