defmodule GPIO do
  defstruct
      num: nil,
      val: 0,
      dir: :out,
      file: nil
end


defmodule Pins.Paths do
  def base,            do: "/sys/class/gpio/"
  def dir(pin),        do: "#{base}/gpio#{pin}/"
  def file(pin, file), do: dir(pin) |> Path.join(file)
  def val(pin),        do: file(pin, "value")
end


defmodule Pins do
  use GenServer
  import GenServer
  require Logger
  alias Pins.Paths

  @global_name {:global, :pins}

  def start_link(), do: start_link(__MODULE__, %{}, name: @global_name)


  # GETTERS
  @doc "Get a list of all currently managed pins"
  def all(),       do: call(@global_name, :get_all)

  @doc "Get given pin info"
  def pin(pin),    do: call(@global_name, {:get_pin, pin})

  @doc "Get value of given pin"
  def val(pin), do: call(@global_name, {:val, pin})

  @doc "Get direction of given pin (:in/:out)"
  def get_dir(pin), do: Pins.pin(pin).dir


  # SETTERS
  @doc "Set value for given pin to `val`"
  def set(pin, value), do: val(pin, value) # an alias for `val`
  def val(pin, val) do
    case call(@global_name, {:val, pin, val}) do
      :badarg ->
        raise(ArgumentError, message: "Can't set value of input pin #{pin}.")
      %GPIO{val: val} ->
        val
    end
  end

  @doc "Set given pin to HIGH state"
  def on(pin), do: val(pin, "1")

  @doc "Set given pin to LOWstate"
  def off(pin), do: val(pin, "0")

  @doc "Set direction of given pin to `dir`"
  def dir(pin, direction) do
    call(@global_name, {:dir, pin, direction})
  end

  @doc "Set values for all the pins given. Accepts a list of pairs: {pin_num, val}"
  def set(pins) do
    for {pin, val} <- pins do
      Pins.export(pin)
      Pins.dir(pin, "out")
      Pins.set(pin, val)
    end
  end

  # Server section
  # ----------------------------------------------------------------------------

  def handle_call(:get_all, _from, state), do: {:reply, state, state}

  def handle_call({:get_pin, pin}, _from, state) do
    state = Map.put_new(state, pin, init_pin(pin, state))
    {:reply, state[pin].val, state}
  end

  def handle_call({:dir, pin, direction}, _from, state) do
    state = Map.put_new(state, pin, init_pin(pin, state))
    Paths.file(pin, "direction") |> File.write!(direction)
    {:reply, :ok, state}
  end

  # Get pin value
  def handle_call({:val, pin}, _from, state) do
    state = Map.put_new(state, pin, init_pin(pin, state))
    ret = case state[pin].dir do
            :in ->
              val(pin) |> Pin.read! |> String.strip
            :out ->
              state[pin].val
          end
    {:reply, ret, state}
  end


  # Set pin value
  def handle_call({:val, pin, new_val}, _from, state) do
    state = Map.put_new(state, pin, init_pin(pin, state))
    pin_map = state[pin]
    case pin_map.dir do
      :out ->
        IO.write(pin_map.file, "#{new_val}")
        state = put_in(state[pin].val, new_val)
        {:reply, state[pin], state}
      :in ->
        {:reply, :badarg, state}
    end
  end


  def terminate(_reason, state) do
    for {k, %GPIO{file: io_dev}} <- Map.to_list(state) do
      Logger.info "Closing pin #{k}..."
      File.close(io_dev)
    end
  end


  # Helpers
  # ----------------------------------------------------------------------------
  @doc "Make given pin accessible in the file system"
  def export(pin), do: File.write(Paths.base <> "/export", "#{pin}")
  def out(pin), do: File.write!(Paths.file(pin, "direction"), "out")

  def init_pin(pin, state) do
    case state[pin] do
      nil ->
        Pins.export(pin)
        Pins.out(pin)
        %GPIO{
          num: pin,
          file: Paths.val(pin) |> File.open!([:write])
        }
      pin_state ->
        pin_state
    end
  end
end
