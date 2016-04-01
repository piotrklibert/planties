defmodule Buzzer do
  use GenServer
  use Util

  @global_name {:global, :buzz}
  @pin 24
  @gpio_path "/sys/class/gpio/"
  @val_file "#{@gpio_path}/gpio#{@pin}/value"

  defpistart "Buzzer" do
    File.write "#{@gpio_path}/export", "#{@pin}"
    File.write "#{@gpio_path}/gpio#{@pin}/direction", "out"
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
    Util.turn_on @val_file
    {:reply, :ok, state}
  end
  def handle_call(:off, _from, state) do
    Util.turn_off @val_file
    {:reply, :ok, state}
  end
end
