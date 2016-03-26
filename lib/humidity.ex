defmodule HumiditySensor do
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

  @global_name {:global, :humidity}

  @adc_id 0x6A
  @lsb 0.000625                 # A/C conversion resolution


  def start_link() do
    IO.inspect "Starting I2C handling..."
    {:ok, pid} = I2c.start_link("i2c-1", @adc_id)
    GenServer.start_link(HumiditySensor, pid, name: @global_name)
  end


  # Server API

  def handle_call(:get, _from, i2c_pid) do
    I2c.write i2c_pid, config(1) # write/send a single byte
    resp = I2c.read i2c_pid, 3   # read 3 bytes

    << _sign :: size(1), val :: size(15), _conf :: size(8) >> = resp
    input_voltage = val * @lsb

    {:reply, input_voltage, i2c_pid}
  end

  defp config(chan), do: <<
    0    :: size(1),     # ignored in continuous mode
    chan :: size(2),     # number of a channel to query
    1    :: size(1),     # 'o'ne-shot (0) or 'c'ontinuous mode (1)
    2    :: size(2),     # how many bits to use for transfer, 2 means 16 bits
    0    :: size(2)      # Programmable Gain Amplifier, 0 means 1x amplification
  >>

end
