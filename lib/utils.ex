defmodule Pin do
  def get(pin),      do: file(pin, "value") |> File.read!
  def set(pin, val), do: file(pin, "value") |> File.write!("#{val}")

  def set(pins) do
    for {pin, val} <- pins do
      export(pin)
      set_dir(pin, "out")
      set(pin, val)
    end
  end

  def export(pin), do: File.write("/sys/class/gpio/export", "#{pin}")

  def get_dir(pin),      do: file(pin, "direction") |> File.read!
  def set_dir(pin, dir), do: file(pin, "direction") |> File.write! dir

  def on(pin),  do: set pin, "1"
  def off(pin), do: set pin, "0"

  def dir(pin), do: "/sys/class/gpio/gpio#{pin}/"
  def file(pin, file), do: Path.join(dir(pin), file)
end

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

  defmodule Hist do
    def add([a, b, _], d), do: [d, a, b]
    def add([a, b], c), do: [c, a, b]
    def add([a], b), do: [b, a]
    def add([], a), do: [a]
  end

  def is_rpi, do: Mix.env == :pi
  def id(x), do: x

  def wait(time), do: wait(time, :ok)

  def wait(time, ret) when time == 0 do
    ret
  end
  def wait(time, ret) when time > 0 do
    receive do
    after time -> ret
    end
  end

  def turn_on(filename), do: File.write! filename, "1"
  def turn_off(filename), do: File.write! filename, "0"

  def set_pins([]), do: :ok
  def set_pins([{pin, val} | rest]) do
    Porcelain.shell "sudo echo #{pin} >/sys/class/gpio/export || true"
    Porcelain.shell "sudo echo out >/sys/class/gpio/gpio#{pin}/direction || true"
    Porcelain.shell "sudo echo #{val} >/sys/class/gpio/gpio#{pin}/value || true"
    set_pins rest
  end

  def gpio_path(pin) do
    "/sys/class/gpio/gpio#{pin}/value"
  end

end
