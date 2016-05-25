defmodule LED do
  use Util
  use GenServer

  @global_name {:global, :led}
  @pin 18

  defpistart "LED" do
    GenServer.start_link __MODULE__, nil, name: @global_name
  end

  def blink(time \\ 400) do
    GenServer.call @global_name, {:blink, time}
  end

  def blink_many(times, wait \\ 400) do
    for _ <- 1 .. times do
      blink()
      Util.wait(wait)
    end
    :ok
  end


  # Server section
  # ----------------------------------------------------------------------------
  def handle_call({:blink, time}, _from, state) do
    Pins.on @pin
    Util.wait(time)
    Pins.off @pin
    {:reply, :ok, state}
  end
end
