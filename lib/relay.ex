defmodule Relay.Timer do
  require Logger

  def start_link do
    {_, {now, m, s}} = :calendar.local_time()
    day_night = if now > 8 and now < 21 do :day else :night end
    Logger.info "Starting timer on #{now}:#{m}:#{s} at #{day_night}..."
    spawn_link __MODULE__, :loop, [day_night]
  end

  def loop(state) do
    {_, {now_h, now_m, _}} = :calendar.local_time
    new_state =
      case state do
        :day when now_h == 20 and now_m == 35 ->
          Relay.alloff()
          :night
        :night when now_h == 8 ->
          Relay.allon()
          :day
        _ -> state
      end

    :timer.apply_after :timer.seconds(25), __MODULE__, :loop, [new_state]
  end
end


defmodule Relay do
  use Bitwise
  use GenServer
  use Util

  require Logger


  @global_name {:global, :relay}
  @i2c_id 0x20


  defpistart "i2c" do
    Logger.info "Starting I2C handling for Relay Hat..."
    {:ok, pid} = I2c.start_link("i2c-1", @i2c_id)
    Relay.Timer.start_link()
    init_val = bnot(read_byte(pid))
    GenServer.start_link(__MODULE__,
                         %{i2c: pid, val: init_val},
                         name: @global_name)
  end


  # Main API
  def get(),          do: GenServer.call(@global_name, :get)
  def get(relay_num), do: GenServer.call(@global_name, {:get, relay_num})

  def set(val), do: GenServer.call(@global_name, {:send, val})

  def switch(relay_num, active?) do
    GenServer.call(@global_name, {:switch, relay_num, active?})
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

  def on(num) when is_list(num), do: for n <- num, do: on(n)
  def on(num), do: switch num, 0

  def off(num) when is_list(num), do: for n <- num, do: off(n)
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
    active? = (state.val &&& (1 <<< relay_num)) >>> relay_num
    {:reply, active?, state}
  end

  def handle_call({:switch, num, 0}, _from, state) do
    log(state.val, "switch0-1")
    new_val = state.val &&& bnot(1 <<< num)
    log(new_val, "switch0-2")
    send_byte(state.i2c, new_val)
    log(read_byte(state.i2c))
    make_reply(state, new_val)
  end

  def handle_call({:switch, num, 1}, _from, state) do
    log(state.val, "switch1-1")
    new_val = state.val ||| (1 <<< num)
    log(new_val, "switch1-2")
    send_byte(state.i2c, new_val)
    log(read_byte(state.i2c))
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
    log(val, "sending: ")
    I2c.write(pid, <<0x06, val :: size(8)>>)
  end

  def read_byte(pid) do
    <<_ :: size(4), val :: size(4)>> = I2c.write_read(pid, <<0>>, 1)
    val &&& 0b1111
  end

  defp make_reply(state, val) do
    state = %{state | val: val}
    {:reply, fmt(val), state}
  end

  defp log(val, msg \\ "Binary val: ") do
    # IO.write(msg)
    # IO.inspect(fmt(val))
  end

  defp fmt(val) do
    # this is needed, because 0xFF, when read as a single byte, looks like -1
    # (ie. it has MSB set).
    << val :: size(16) >> = << 0 ::size(8), val :: size(8) >>
    base_2 = Integer.to_string(val, 2) |> String.rjust(8, ?0)
    "#{val} (0b#{base_2})"
  end

  defp to_bit(active?) do
    case active? do
      :on  -> 0
      :off -> 1
      any  -> any
    end
  end
end
