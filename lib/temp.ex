defmodule Temp do
  @moduledoc """
  A module for reading temperature data from a device connected to a `w1`
  interface. Devices in w1 are represented as simple files in the file system
  and you can simply read them to get your reading. My thermometer looks like
  this when read:

        9c 01 4b 46 7f ff 0c 10 0c : crc=0c YES
        9c 01 4b 46 7f ff 0c 10 0c t=25750

  The last value after the last '=' sign is a temperature in 1/1000 of *C.
  """
  use Component
  use Util

  @dir "/sys/bus/w1/devices/w1_bus_master1"

  def start_link() do
    # XXX: assumes a thermometer is always listed first in the list of
    # connectied devices!
    [slave_name | _] = File.read!("#{@dir}/w1_master_slaves") |> String.split

    Component.start_link slave_name
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
