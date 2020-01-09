defmodule Intcode do
  def spawn(parent_pid, mem) do
    receive do
      {:output_pid, output_pid} -> Process.put(:output_pid, output_pid)
    end
    Process.put(:parent_pid, parent_pid)
    Process.put(:relative_base, 0)
    run(mem)
  end

  def listener do
    receive do
      {:status, output} -> IO.inspect(output)
    end
    listener()
  end

  def run(mem), do: run(mem, 0)
  def run(_mem, -99), do: exit(99)
  def run(mem, cursor) do
    
    #send(Process.get(:parent_pid), {:status, {"Exec instruction", Integer.to_string(mem[cursor])}})

    {mem, cursor} = case rem(mem[cursor], 100) do
      1 -> exec_add(mem, cursor)
      2 -> exec_multiply(mem, cursor)
      3 -> exec_input(mem, cursor)
      4 -> exec_output(mem, cursor)
      5 -> exec_jump_true(mem, cursor)
      6 -> exec_jump_false(mem, cursor)
      7 -> exec_less_than(mem, cursor)
      8 -> exec_equals(mem, cursor)
      9 -> exec_offset_relative_base(mem, cursor)
      99 -> {[], -99}
    end

    run(mem, cursor)
  end

  @moduledoc """
  The magic number '2' in this function is the length of the opcode

  Pad the instruction with "0"s to 2+num and then mode is at position -(2+num)
  e.g. the instruction 0102 has param 1 mode at -3 (1) and param 2 mode at -4 (0)
  """
  defp get_param(mem, cursor, num) do
    mode = mem[cursor]
    |> Integer.to_string
    |> String.pad_leading(2+num, "0")
    |> String.slice(-(2+num)..-(2+num))
    case mode do
      "2" -> mem[cursor+num]+Process.get(:relative_base)
      "1" -> cursor+num
      "0" -> mem[cursor+num]
    end
  end

  defp exec_add(mem, cursor) do
    a = mem[get_param(mem, cursor, 1)]
    b = mem[get_param(mem, cursor, 2)]
    c = get_param(mem, cursor, 3)
    {Map.put(mem, c, a + b), cursor + 4}
  end

  defp exec_multiply(mem, cursor) do
    a = mem[get_param(mem, cursor, 1)]
    b = mem[get_param(mem, cursor, 2)]
    c = get_param(mem, cursor, 3)
    {Map.put(mem, c, a * b), cursor + 4}
  end

  defp exec_input(mem, cursor) do
    a = get_param(mem, cursor, 1)
    receive do
      {:input, input} -> {Map.put(mem, a, input), cursor + 2}
    after
      100 -> {Map.put(mem, a, 0), cursor + 2}
    end
  end

  defp exec_output(mem, cursor) do
    output = mem[get_param(mem, cursor, 1)]
    if Process.alive?(Process.get(:output_pid)) do
      send(Process.get(:output_pid), {:input, output})
    else
      send(Process.get(:parent_pid), {:done, output})
    end
    {mem, cursor + 2}
  end

  defp exec_jump_true(mem, cursor) do
    a = mem[get_param(mem, cursor, 1)]
    b = mem[get_param(mem, cursor, 2)]
    {mem, (if a != 0, do: b, else: cursor + 3)}
  end

  defp exec_jump_false(mem, cursor) do
    a = mem[get_param(mem, cursor, 1)]
    b = mem[get_param(mem, cursor, 2)]
    {mem, (if a == 0, do: b, else: cursor + 3)}
  end

  defp exec_less_than(mem, cursor) do
    a = mem[get_param(mem, cursor, 1)]
    b = mem[get_param(mem, cursor, 2)]
    c = get_param(mem, cursor, 3)
    result = if a < b, do: 1, else: 0
    {Map.put(mem, c, result), cursor + 4}
  end

  defp exec_equals(mem, cursor) do
    a = mem[get_param(mem, cursor, 1)]
    b = mem[get_param(mem, cursor, 2)]
    c = get_param(mem, cursor, 3)
    result = if a == b, do: 1, else: 0
    {Map.put(mem, c, result), cursor + 4}
  end

  defp exec_offset_relative_base(mem, cursor) do
    a = mem[get_param(mem, cursor, 1)]
    Process.put(:relative_base, Process.get(:relative_base) + a)
    {mem, cursor + 2}
  end
end

defmodule RemoteRobot do
  def spawn(parent_pid) do
    receive do
      {:output_pid, output_pid} -> Process.put(:output_pid, output_pid)
    end
    Process.put(:parent_pid, parent_pid)
    run()
  end

  def run(), do: run(1..61 |> Enum.map(fn(_) -> Enum.map(1..61, fn(_) -> " " end) end), {30,30}, 0)
  def run(map, {cur_x, cur_y}, count) do

    rand_dir = :rand.uniform(4)
    send(Process.get(:output_pid), {:input, rand_dir})
    status = receive do
      {:input, status} -> status
    after
      10000 -> :timeout
    end
    if status == :timeout do
      run(map, {cur_x, cur_y}, count)
    end

    
    {map, {new_x, new_y}} = update(map, {cur_x, cur_y}, rand_dir, status)
    if rem(count, 1000) == 0 do
      paint(map)
    end
    run(map, {new_x, new_y}, count + 1)
  end

  def paint(map) do
    send(Process.get(:parent_pid), {:status, "========="})
    Enum.map map, fn row ->
      send(Process.get(:parent_pid), {:status, Enum.reduce(row, "", fn a, b -> b <> a end)})
    end
    send(Process.get(:parent_pid), {:status, "========="})
  end

  def update(map, {cur_x, cur_y}, dir, status) do
    {tar_x, tar_y} = case dir do
      1 -> {cur_x, cur_y - 1}
      2 -> {cur_x, cur_y + 1}
      3 -> {cur_x - 1, cur_y}
      4 -> {cur_x + 1, cur_y}
    end
    case status do
      0 -> {List.replace_at(map, tar_y, List.replace_at(Enum.at(map, tar_y), tar_x, "#")), {cur_x, cur_y}}
      1 -> {List.replace_at(map, tar_y, List.replace_at(Enum.at(map, tar_y), tar_x, ".")), {tar_x, tar_y}}
      2 -> {List.replace_at(map, tar_y, List.replace_at(Enum.at(map, tar_y), tar_x, "O")), {tar_x, tar_y}}
    end
  end

  def fill_oxygen(map, time) do
    map = Enum.reduce(map, map, fn {{x,y}, contents}, map ->
      if contents == "O" do
        map
        |> Map.put({x+1,y}, (if map[{x+1,y}] == ".", do: "O", else: map[{x+1,y}]))
        |> Map.put({x-1,y}, (if map[{x-1,y}] == ".", do: "O", else: map[{x-1,y}]))
        |> Map.put({x,y+1}, (if map[{x,y+1}] == ".", do: "O", else: map[{x,y+1}]))
        |> Map.put({x,y-1}, (if map[{x,y-1}] == ".", do: "O", else: map[{x,y-1}]))
      else
        map
      end
    end)
    no_oxygen = Enum.reduce(map, 0, fn {_, contents}, acc ->
      case contents do
        "." -> acc + 1
        _ -> acc
      end
    end) 
    if no_oxygen == 0 do
      time
    else
      fill_oxygen(map, time + 1)
    end
  end

end

#part 1
#program = hd(System.argv())
          #|> File.read!()
          #|> String.replace(~r/\r|\n/, "")
          #|> String.split(",", trim: true)
          #|> Enum.map(&String.to_integer/1)

#ram = Enum.reduce(1..10000, [], fn _, acc ->
  #[0 | acc] 
#end)

#mem = Stream.zip(Stream.iterate(0, &(&1+1)), program ++ ram)
#|> Enum.into(%{})

#pid_a = spawn(Intcode, :spawn, [self(), mem])
#pid_b = spawn(RemoteRobot, :spawn, [self()])
#send(pid_a, {:output_pid, pid_b})
#send(pid_b, {:output_pid, pid_a})
#Intcode.listener()

# part 2, run against the map in input2.txt created in part 1
{map, _, _} = hd(System.argv())
|> File.read!()
|> String.split(~r/\R/, trim: true)
|> Enum.map(&String.split(&1, "", trim: true))
|> Enum.reduce({%{}, 0, 0}, fn row, {map, x, y} ->
  {map, _, y} = Enum.reduce row, {map, x, y}, fn cell, {map, x, y} ->
    {Map.put(map, {x, y}, cell), x + 1, y}
  end
  {map, 0, y + 1}
end)

RemoteRobot.fill_oxygen(map, 1) |> IO.inspect
