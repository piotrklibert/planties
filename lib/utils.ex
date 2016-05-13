defmodule Util do
  defmacro __using__(_) do
    quote do
      require Util
      import Util
    end
  end

  defmacro defpistart(server_name,  do: body) do
    quote do
      def start_link do
        case Mix.env do
          :pi ->
            unquote(body)
          _ ->
            raise "#{unquote(server_name)} server can only run on Raspberry!"
        end
      end
    end
  end

  def fmt(val) do
    # this is needed because 0xFF, when read as a single byte, looks like -1
    # (ie. it has MSB set).
    << val :: size(16) >> = << 0 ::size(8), val :: size(8) >>
    base_2 = Integer.to_string(val, 2) |> String.rjust(8, ?0)
    "#{val} (0b#{base_2})"
  end

  def is_rpi, do: Mix.env == :pi
  def id(x), do: x

  def wait(time), do: wait(time, :ok)

  def wait(time, ret) when time == 0, do: ret
  def wait(time, ret) when time > 0 do
    receive do
    after time -> ret
    end
  end

  def find_value_index(enum, val) do
    enum |> Enum.find_index fn (el) -> el == val end
  end

end
