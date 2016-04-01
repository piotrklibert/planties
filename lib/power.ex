defmodule Power do
  use GenServer
  use Util

  @global_name {:global, :power}
  @dir "/sys/class/gpio"
  @pin "21"
  @val_file "#{@dir}/gpio#{@pin}/value"


  defpistart "AC" do
    File.write "#{@dir}/export", "#{@pin}"
    File.write! "#{@dir}/gpio#{@pin}/direction", "out"
    GenServer.start_link __MODULE__, nil, name: @global_name
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
