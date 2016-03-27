defmodule Power do
  use GenServer

  @global_name {:global, :power}
  @dir "/sys/class/gpio"
  @pin "21"
  @val_file "#{@dir}/gpio#{@pin}/value"


  def start_link() do
    case Mix.env do
      :pi ->
        File.write "#{@dir}/export", "#{@pin}"
        File.write! "#{@dir}/gpio#{@pin}/direction", "out"
        GenServer.start_link __MODULE__, nil, name: @global_name
      _ ->
        raise "Power manager server can only run on Raspberry!"
    end
  end

  def switch(state) do
    GenServer.call @global_name, state
  end


  # Server section
  # ----------------------------------------------------------------------------

  def init(nil) do
    spawn_link fn ->
      Util.wait 300
      Power.switch :on
    end
    {:ok, nil}
  end

  def handle_call(:on, _from, state) do
    Util.turn_on(@val_file)
    {:reply, :ok, state}
  end

  def handle_call(:off, _from, state) do
    Util.turn_off(@val_file)
    {:reply, :ok, state}
  end

end
