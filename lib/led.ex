defmodule LED do
  use GenServer

  @global_name {:global, :led}
  @dir "/sys/class/gpio"
  @pin "18"


  def start_link() do
    case Mix.env do
      :pi ->
        export_pin()
        GenServer.start_link __MODULE__, nil, name: @global_name
      _ ->
        raise "LED server can only run on Raspberry!"
    end
  end

  def blink(time \\ 400) do
    GenServer.call @global_name, {:blink, time}
  end

  def blink_many(times, wait \\ 400) do
    for x <- 1 .. times, do: blink(wait)
  end

  def handle_call({:blink, time}, _from, state) do
    val_file = "#{@dir}/gpio#{@pin}/value"
    File.write! val_file, "1"
    receive do after time -> nil end
    File.write! val_file, "0"
    {:reply, nil, state}
  end

  def export_pin() do
    File.write @dir <> "/export", "18"
    File.write! @dir <> "/gpio18/direction", "out"
  end
end
