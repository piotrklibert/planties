defmodule LED do
  use GenServer

  @global_name {:global, :led}
  @dir "/sys/class/gpio"
  @pin "18"
  @val_file "#{@dir}/gpio#{@pin}/value"


  def start_link() do
    case Mix.env do
      :pi ->
        File.write "#{@dir}/export", "#{@pin}"
        File.write! "#{@dir}/gpio#{@pin}/direction", "out"
        GenServer.start_link __MODULE__, nil, name: @global_name
      _ ->
        raise "LED server can only run on Raspberry!"
    end
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
    Util.turn_on(@val_file)
    receive do after time -> :ok end
    Util.turn_off(@val_file)
    {:reply, :ok, state}
  end
end
