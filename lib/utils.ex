defmodule Util do
  defmodule Hist do
    def add([a, b, _], d), do: [d, a, b]
    def add([a, b], c), do: [c, a, b]
    def add([a], b), do: [b, a]
    def add([], a), do: [a]
  end

  def is_rpi, do: Mix.env == :pi
  def id(x), do: x
end
