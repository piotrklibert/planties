defmodule Component do
  # defmacro __before_compile__(_env) do
  #   IO.inspect _env
  # end
  defmacro __using__([name: global_name]) do
    quote do
      import GenServer
      import Component
      import Util
      require Component
      require Logger

      @global_name {:global, unquote(global_name)}
    end
  end

  defmacro start_link() do
    quote do
      GenServer.start_link(unquote(__CALLER__.module),
                           [],
                           name: @global_name)
    end
  end

  defmacro start_link(args) do
    quote do
      GenServer.start_link(unquote(__CALLER__.module),
                           unquote(args),
                           name: @global_name)
    end
  end

  defmacro call(args) do
    quote do
      GenServer.call @global_name, unquote(args)
    end
  end
end


defmodule Util do
  defmacro __using__(_) do
    quote do
      require Util
      import Util
    end
  end
  use Bitwise

  def get_bit(val, bit_num) do
    val >>> bit_num &&& 0b0001
  end

  def set_bit(val, bit_num, 0), do: val - (1 <<< bit_num)
  def set_bit(val, bit_num, 1), do: val + (1 <<< bit_num)

  def to_bit(active?) do
    case active? do
      :on  -> 0
      :off -> 1
      any  -> any
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
