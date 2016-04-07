defmodule LED do
  use Util
  use GenServer

  @global_name {:global, :led}
  @dir "/sys/class/gpio"
  @pin "18"
  @val_file "#{@dir}/gpio#{@pin}/value"

  defpistart "LED" do
    File.write "#{@dir}/export", "#{@pin}"
    File.write! "#{@dir}/gpio#{@pin}/direction", "out"
    GenServer.start_link __MODULE__, nil, name: @global_name
  end

  def blink(time \\ 400) do
    GenServer.call @global_name, {:blink, time}
  end

  def blink_many(times, wait \\ 400) do
    for _ <- 1 .. times do
      blink()
      wait(wait)
    end
    :ok
  end


  # Server section
  # ----------------------------------------------------------------------------
  def handle_call({:blink, time}, _from, state) do
    import Util
    @val_file |> turn_on
    wait(time)
    @val_file |> turn_off
    {:reply, :ok, state}
  end
end
