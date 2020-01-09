defmodule Aoc2019.Day23 do
  @moduledoc """
  Documentation for Aoc2019 Day 23.
  """

  @doc """
  ## Solve P1 & P2
  iex> Aoc2019.Day23.p12
  """
  def p12 do
    mem = Aoc2019.Intcode.file_input_to_mem("lib/day23/input.txt")

    nics = Enum.reduce(0..49, %{}, fn i, map ->
      nic_pid = spawn(Aoc2019.Nic, :spawn_nic, [self(), mem, i])
      Map.put(map, i, nic_pid)
    end)

    route(nics, {0, 0})
  end

  def route(nics, {nat_x, nat_y}) do
    {address, x, y} = receive do
      {:route, {address, x, y}} -> {address, x, y}
    after
      3000 ->
        # p2 answer is first packet duplicated
        IO.inspect({nat_x, nat_y}, label: "NAT DELIVERED")
        {0, nat_x, nat_y}
    end

    {nat_x, nat_y} = if address == 255 do
      # p1 answer is first packet received by the NAT
      # IO.inspect({x, y}, label: "NAT RECEIVED")
      {x, y}
    else
      send(Map.get(nics, address), {:external, {x, y}})
      {nat_x, nat_y}
    end

    route(nics, {nat_x, nat_y})
  end
end

defmodule Aoc2019.Nic do
  def spawn_nic(parent_pid, iprog, address) do
    Process.put(:parent_pid, parent_pid)

    ipid = spawn_link(Aoc2019.Intcode, :spawn, [self(), iprog])
    send(ipid, {:output_pid, self()})
    send(ipid, {:input, address})

    listen(ipid)
  end

  def listen(ipid) do
    {type, data} = receive do
      {:input, address} -> {:input, address}
      {:external, {x, y}} -> {:external, {x, y}}
    after
      1000 -> {:timeout, :ok}
    end

    case type do
      :input ->
        x = receive do
          {:input, x} -> x
        end
        y = receive do
          {:input, y} -> y
        end
        send(Process.get(:parent_pid), {:route, {data, x, y}})
      :external ->
        {x, y} = data
        send(ipid, {:input, x})
        send(ipid, {:input, y})
      :timeout -> :ok
    end

    listen(ipid)
  end
end
