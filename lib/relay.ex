defmodule Relay do
  use Bitwise
  use Component
  use Util

  require Logger
  defmodule State do
    defstruct i2c: nil, val: nil
  end

  @global_name {:global, :relay}
  @i2c_id 0x22


  def start_link() do
    Logger.info "Starting I2C handling for Relay Hat..."
    {:ok, pid} = I2c.start_link("i2c-1", @i2c_id)

    # TODO: Disabled, because the hardware changed, needs rewrite
    # {:ok, _} = Relay.Timer.start_link()
    # {:ok, _} = Relay.Buttons.start_link()

    init_val = bnot(read_byte(pid)) # negated because of default Relay state (off)
    state = %State{i2c: pid, val: init_val}
    Component.start_link(state)
  end


  # Main API
  def get(),          do: Component.call(:get)
  def get(relay_num), do: Component.call({:get, relay_num})

  def set(val), do: Component.call({:send, val})

  def switch(relay_num, active?) do
    Component.call({:switch, relay_num, active?})
  end

  def toggle(relay_num) do
    active? =
      case get(relay_num) do
        0 -> 1
        1 -> 0
      end

    switch relay_num, active?
  end


  # Convenience:
  def allon(),  do: set(0b0000)
  def alloff(), do: set(0b1111)

  def on(nums) when is_list(nums), do: for n <- nums, do: on(n)
  def on(num), do: switch num, 0

  def off(nums) when is_list(nums), do: for n <- nums, do: off(n)
  def off(num), do: switch num, 1

  def switch(vals) when is_list(vals) do
    for {num, active?} <- vals, do: switch(num, active? |> to_bit)
  end

  def _1(), do: toggle(1)
  def _1(active?), do: switch(1, active? |> to_bit)

  def _2(), do: toggle(0)
  def _2(active?), do: switch(0, active? |> to_bit)

  def _3(), do: toggle(2)
  def _3(active?), do: switch(2, active? |> to_bit)

  def _4(), do: toggle(3)
  def _4(active?), do: switch(3, active? |> to_bit)




  # Server API
  # ----------------------------------------------------------------------------

  def handle_call(:get, _from, state) do
    {:reply, [val: fmt(state.val),
              hw_val: fmt(read_byte(state.i2c)),
              pid: state.i2c],
     state}
  end

  def handle_call({:get, relay_num}, _from, state) do
    active? = Util.get_bit(state.val, relay_num)
    {:reply, active?, state}
  end

  def handle_call({:switch, num, 0}, _from, state) do
    new_val = Utils.set_bit(state.val, num, 0)
    send_byte(state.i2c, new_val)
    make_reply(state, new_val)
  end

  def handle_call({:switch, num, 1}, _from, state) do
    new_val = Utils.set_bit(state.val, num, 1)
    send_byte(state.i2c, new_val)
    make_reply(state, new_val)
  end

  def handle_call({:send, val}, _from, state) do
    send_byte(state.i2c, val)
    make_reply(state, val)
  end


  def terminate(_reason, state) do
    send_byte(state.i2c, 0xFF)
  end


  # Helpers
  # ----------------------------------------------------------------------------

  def send_byte(pid, val) do
    I2c.write(pid, <<0x06, val :: size(8)>>)
  end

  def read_byte(pid) do
    <<_ :: size(4), val :: size(4)>> = I2c.write_read(pid, <<0>>, 1)
    val &&& 0b1111
  end

  defp make_reply(state, val) do
    state = %State{state | val: val}
    {:reply, fmt(val), state}
  end

end
