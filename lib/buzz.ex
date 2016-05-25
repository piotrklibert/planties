defmodule Buzzer do
  use Component, name: :buzz

  @pin 24

  def start_link() do
    Component.start_link()
  end

  def beep(time \\ 500) do
    Component.call :on
    Util.wait(time)
    Component.call :off
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
