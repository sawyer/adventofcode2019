defmodule Aoc2019.Day19 do
  def spawn_p1(parent_pid, iprog) do
    Process.put(:parent_pid, parent_pid)

    count = 1..50 |> Enum.map(fn _ -> Enum.map(1..50, fn _ -> "0" end) end)
    |> scan(iprog)
    |> paint()
    |> Enum.reduce(0, fn row, i ->
      Enum.reduce(row, i, fn c, i -> if c == 1, do: i + 1, else: i end)
    end)
    
    send(Process.get(:parent_pid), {:status, count})
    :timer.sleep(1000); exit(count)
  end

  def spawn_p2(parent_pid, iprog, {start_x, start_y}) do
    Process.put(:parent_pid, parent_pid)

    count = 1..100 |> Enum.map(fn _ -> Enum.map(1..100, fn _ -> "0" end) end)
    |> scan(iprog, {start_x, start_y})
    |> paint()
    |> Enum.reduce(0, fn row, i ->
      Enum.reduce(row, i, fn c, i -> if c == 1, do: i + 1, else: i end)
    end)
    
    send(Process.get(:parent_pid), {:status, count})
    :timer.sleep(1000); exit(count)
  end

  def scan(xy_map, iprog), do: scan(xy_map, iprog, {0,0})
  def scan(xy_map, iprog, {start_x, start_y}) do
    {new_xy_map,_,_} = Enum.reduce(xy_map, {[], start_x, start_y}, fn row, {new_xy_map,x,y} ->
      {new_row,_,_} = Enum.reduce(row, {[], x, y}, fn _, {new_xy_map,x,y} ->
        
        ipid = spawn(Aoc2019.Intcode, :spawn, [self(), iprog])
        send(ipid, {:output_pid, self()})
        send(ipid, {:input, x})
        send(ipid, {:input, y})

        status = receive do
          {:input, status} -> status
        after
          10000 -> :timeout
        end
        if status == :timeout do
          exit("Timeout instead of status.")
        end

        {new_xy_map ++ [status], x + 1, y}
      end)
      {new_xy_map ++ [new_row], start_x, y + 1}
    end)

    new_xy_map
  end

  def paint(xy_map) do
    send(Process.get(:parent_pid), {:status, "========="})
    Enum.map(xy_map, fn row ->
      row_str = Enum.reduce(row, "", fn c, a -> a <> Integer.to_string(c) end)
      send(Process.get(:parent_pid), {:status, row_str})
    end)
    send(Process.get(:parent_pid), {:status, "========="})
    xy_map
  end

  @doc """
  ## Solve P1
  iex> Aoc2019.Day19.p1
  """
  def p1(), do: p1("lib/day19/input.txt")
  def p1(fp) do
    mem = Aoc2019.Intcode.file_input_to_mem(fp)

    spawn_link(Aoc2019.Day19, :spawn_p1, [self(), mem])

    Aoc2019.Intcode.listener()
  end

  @doc """
  The coordinates 1122, 1248 were found with trial and error over ~10 mins
  of checking different start positions and painting the results.

  ## Solve P2
  iex> Aoc2019.Day19.p2
  """
  def p2(), do: p2("lib/day19/input.txt")
  def p2(fp) do
    mem = Aoc2019.Intcode.file_input_to_mem(fp)

    spawn_link(Aoc2019.Day19, :spawn_p2, [self(), mem, {1122, 1248}])

    Aoc2019.Intcode.listener()
  end

end
