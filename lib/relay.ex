defmodule Relay do
  use Bitwise
  use GenServer
  use Util

  require Logger

  @global_name {:global, :relay}
  @adc_id 0x20

  defpistart "i2c" do
    Logger.info "Starting I2C handling for Relay Hat..."
    {:ok, pid} = I2c.start_link("i2c-1", @adc_id)
    init = %{i2c_pid: pid, val: 0}
    GenServer.start_link(__MODULE__, init, name: @global_name)
  end

  def on(num),  do: switch num, true
  def off(num), do: switch num, false

  def get do
    GenServer.call(@global_name, :get)
  end
  def switch(num, state) do
    val = bor(get(), state <<< num)
    IO.inspect val
    GenServer.call(@global_name, {:switch, val})
  end

  # Server API

  def handle_call(:get, _from, state) do
    {:reply, state.val, state}
  end
  def handle_call({:switch, val}, _from, state) do
    {:reply, I2c.write(state.i2c_pid, << 0x06, val >>), %{state | val: val}}
  end

end
