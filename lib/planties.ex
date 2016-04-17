defmodule Planties do
  use Application
  import Supervisor.Spec

  # the name used to identify the node running on actual device (Raspberry)
  # (this needs to be kept in sync with ansible/config/raspberrypi.yml)
  @rpi_name :planties@raspberrypi

  def start(_type, _args) do
    case :net_adm.ping @rpi_name do
      :pong -> :ok
      :pang ->
        IO.inspect(
          "WARNING: We're not on Raspberry and #{@rpi_name} is not running!"
        )
    end

    Supervisor.start_link children(Mix.env), strategy: :one_for_one
  end

  def children(:pi), do: [
    worker(LED, []),
    # worker(Humidity, []),
    worker(Buzzer, []),
    # worker(Ir, []),
    worker(Temp, []),
    worker(Relay, []),
    # worker(Ir.Player, []),
    worker(Pins, [])
    # worker(Fan, []),
    # worker(Pump, [])
  ]
  def children(_env), do: []
end
