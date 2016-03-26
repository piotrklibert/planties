defmodule Util do
  defmodule Hist do
    def add([a, b, _], d), do: [d, a, b]
    def add([a, b], c), do: [c, a, b]
    def add([a], b), do: [b, a]
    def add([], a), do: [a]
  end

  def is_rpi, do: Mix.env == :pi
  def id(x), do: x

  def wait(time, ret \\ :ok) do
    receive do
    after time -> ret
    end
  end

  def turn_on(filename) do
    File.write! filename, "1"
  end
  def turn_off(filename) do
    File.write! filename, "0"
  end
end
