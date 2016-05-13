defmodule Buzzer do
  use GenServer
  use Util

  @global_name {:global, :buzz}
  @pin 24

  defpistart "Buzzer" do
    GenServer.start_link __MODULE__, [], name: @global_name
  end

  def beep(time \\ 500) do
    GenServer.call @global_name, :on
    Util.wait(time)
    GenServer.call @global_name, :off
  end

  # Server section
  # ----------------------------------------------------------------------------
  def handle_call(:on, _from, state) do
    Pins.on @pin
    {:reply, :ok, state}
  end

  def handle_call(:off, _from, state) do
    Pins.off @pin
    {:reply, :ok, state}
  end
end
