defmodule Pins.Macros do
  defmacro __using__(_) do
    quote do
      require Pins.Macros
      import Pins.Macros
    end
  end

  @doc """
  A helper macro which initializes the given pin if it's not initialized
  already.
  """
  defmacro with_pin(state, pin_num, do: block) do
    quote do
      num = unquote(pin_num)
      state = unquote(state)

      var!(state) = case Map.has_key?(state.pins, num) do
                      true  -> state
                      false -> start_gpio(state, num)
                    end
      var!(pin) = var!(state).pins[ num ]
      unquote(block)
    end
  end
end


defmodule Pins do
  @moduledoc """
  This module implements a (global) registry of GPIO pins we want to use. It
  initializes the pins on demand, the first time its state is read or written.

  TODO: resetting pins directions
  """

  use GenServer
  use Pins.Macros
  require Logger

  @global_name {:global, :pins}


  defmodule State do
    defstruct pins: %{}
  end


  def start_link(),
    do: GenServer.start_link(__MODULE__, %State{}, name: @global_name)


  # GETTERS
  @doc "Get a list of all currently managed pins"
  def get(), do: GenServer.call @global_name, :all
  def all(), do: get()

  @doc "Get given pin info"
  def get(pin_num), do: GenServer.call @global_name, {:get, pin_num}


  # SETTERS
  @doc "Set value for given pin to `val`"
  def set(pin_num, val), do: GenServer.call(@global_name, {:val, pin_num, val})

  @doc "Set values for all the pins given. Accepts a list of pairs: {pin_num, val}"
  def set(pins), do: for {pin_num, val} <- pins, do: set(pin_num, val)

  @doc "Release the given pin"
  def release(pin_num), do:  GenServer.call(@global_name, {:release, pin_num})


  def on(pin_num),  do: set(pin_num, 1)
  def off(pin_num), do: set(pin_num, 0)

  # Server section
  # ----------------------------------------------------------------------------

  # Return all the pins
  def handle_call(:all, _from, state), do:
    {:reply, state.pins, state}


  # Get pin value
  def handle_call({:get, pin_num}, _from, state) do
    with_pin(state, pin_num) do
      value = Gpio.read(pin)
      {:reply, value, state}
    end
  end

  # Set pin value
  def handle_call({:val, pin_num, new_val}, _from, state) do
    with_pin(state, pin_num) do
      Gpio.write(pin, new_val)
      {:reply, :ok, state}
    end
  end

  # Release the pin
  def handle_call({:release, pin_num}, _from, state) do
    if Map.has_key?(state.pins, pin_num) do
      {pin_pid, pins} = Map.pop(state.pin, pin_num)
      Gpio.release(pin_pid)
      {:reply, :ok, %State{state | pins: pins}}
    else
      {:reply, {:badarg, "We don't have the pin #{pin_num} open yet!"}, state}
    end
  end


  # Cleanup - release all the pins before exiting
  def terminate(_reason, state) do
    for {num, pid} <- Map.to_list(state.pins) do
      Gpio.release(pid)
      Logger.info "Closing pin #{num}..."
    end
  end


  # Helpers
  # ----------------------------------------------------------------------------

  def start_gpio(state, pin_num) do
    Logger.info "Starting GPIO process for pin #{pin_num}."
    {:ok, pid} = Gpio.start_link(pin_num, :output)
    pins = state.pins |> Map.put(pin_num, pid)
    %State{state | pins: pins}
  end
end
