defmodule Relay.Timer do
  require Logger
  def start_link do
    {_, {now, m, s}} = :calendar.local_time
    day_night = if now > 8 and now < 21 do :day else :night end
    Logger.info "Starting timer on #{now}:#{m}:#{s} at #{day_night}..."
    spawn_link __MODULE__, :loop, [day_night]
  end

  def loop(state) do
    {_, {now, _, _}} = :calendar.local_time
    new_state = case state do
      :day when now == 20 ->
        Relay.alloff()
        :night
      :night when now == 8 ->
        Relay.allon()
        :day
      any ->
        Logger.info "Timer running... (#{any})"
        state
    end

    :timer.apply_after :timer.minutes(20), __MODULE__, :loop, [new_state]
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
    Relay.Timer.start_link
    init = %{i2c: pid, val: read_byte(pid)}
    GenServer.start_link(__MODULE__, init, name: @global_name)
  end


  def get(), do: GenServer.call(@global_name, :get)

  def on(num),  do: switch num, 0
  def off(num), do: switch num, 1

  def allon(), do: GenServer.call @global_name, {:send, 0}
  def alloff(), do: GenServer.call @global_name, {:send, 0b1111}

  def switch(num, onoff_flag) do
    GenServer.call(@global_name, {:switch, num, onoff_flag})
  end

  def set(val), do: GenServer.call(@global_name, {:send, val})
  def toggle(), do: GenServer.call :toggle

  # Server API

  def handle_call(:i2c, _from, state) do
    {:reply, state.i2c, state}
  end
  def handle_call(:get, _from, state) do
    {:reply, [val: state.val,
              hw_val: read_byte(state.i2c)],
     state}
  end


  def handle_call({:switch, num, 0}, _from, state) do
    new_val = state.val &&& bnot(1 <<< num)
    send_byte(state.i2c, new_val)
    make_reply(state, new_val)
  end

  def handle_call({:switch, num, 1}, _from, state) do
    new_val = state.val ||| (1 <<< num)
    send_byte(state.i2c, new_val)
    make_reply(state, new_val)
  end

  def handle_call({:send, val}, _from, state) do
    send_byte(state.i2c, val)
    make_reply(state, val)
  end

  def handle_call(:toggle, _from, state) do
    val = case state.val do
            0 -> 0b1111
            0b1111 -> 0
          end
    send_byte(state.i2c, val)
    make_reply(state, val)
  end


  def send_byte(pid, val) do
    I2c.write(pid, <<0x06, val :: size(8)>>)
  end

  def read_byte(pid) do
    <<_ :: size(4), val :: size(4)>> = I2c.write_read(pid, <<0>>, 1)
    val &&& 0b1111
  end

  def make_reply(state, val) do
    state = %{state | val: val}
    {:reply, state.val, state}
  end
end
