defmodule Temp do
  use GenServer
  use Util

  @global_name {:global, :temp}
  @dir "/sys/bus/w1/devices/w1_bus_master1"

  defpistart "Temp" do
    [slave_name | _] = File.read!("#{@dir}/w1_master_slaves") |> String.split
    GenServer.start_link __MODULE__, slave_name, name: @global_name
  end

  def get(), do: GenServer.call @global_name, :get


  # Server section
  # ----------------------------------------------------------------------------
  defp val_file(fname), do: "#{@dir}/#{fname}/w1_slave"
  def handle_call(:get, _from, slave_name) do
    {temp, _} = val_file(slave_name)
        |> File.read!
        |> String.split      |> List.last
        |> String.split("=") |> List.last
        |> Integer.parse
    temp = temp / 1000          # convert to degrees Celsius
    {:reply, temp, slave_name}
  end

  def handle_call(_any, _, slave_name) do
    {:reply, slave_name, slave_name}
  end

end
