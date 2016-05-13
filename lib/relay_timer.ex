defmodule Relay.Timer do
  require Logger

  def schedule, do: [
    {20, 35},
    {8, 20}
  ]

  def toggle(:day),   do: :night
  def toggle(:night), do: :day

  def start_link do
    Logger.info "Starting timer on #{inspect :calendar.local_time()} at #{time_of_day(now)}..."
    spawn_link __MODULE__, :loop, [time_of_day(now)]
  end


  def loop(state) do
    import :timer
    should_toggle  = now in schedule
    state          = if should_toggle do toggle(state) else state end

    if should_toggle do
      case state do
        :night ->
          Relay.off [2, 3]
          apply_after(minutes(2), __MODULE__, :loop, [state])

        :day ->
          Relay.on [2, 3]
          apply_after(minutes(2), __MODULE__, :loop, [state])
      end
    else
      apply_after(seconds(25), __MODULE__, :loop, [state])
    end
  end


  def time_of_day({h, _}) do
    if h > 8 and h < 21 do
      :day
    else
      :night
    end
  end

  def now() do
    {_, {hour, minute, _}} = :calendar.local_time
    {hour, minute}
  end
end
