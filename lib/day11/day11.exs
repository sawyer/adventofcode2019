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

  def permutations([]), do: [[]]
  def permutations(list) do
    for elem <- list, rest <- permutations(list--[elem]), do: [elem|rest]
  end

end

defmodule PaintRobot do
  def spawn(parent_pid) do
    receive do
      {:output_pid, output_pid} -> Process.put(:output_pid, output_pid)
    end
    Process.put(:parent_pid, parent_pid)
    run()
  end

  def run(), do: run({{0,0}, :up, 1}, %{}, MapSet.new)
  def run(current, map, visited) do
    {_, _, cur_color} = current

    if Process.alive?(Process.get(:output_pid)) do
      send(Process.get(:output_pid), {:input, cur_color})
    else
      #min_x = Enum.min_by(visited, fn {x, _} -> x end)
      #min_y = Enum.min_by(visited, fn {_, y} -> y end)
      #max_x = Enum.max_by(visited, fn {x, _} -> x end)
      #max_y = Enum.max_by(visited, fn {_, y} -> y end)

      send(Process.get(:parent_pid), {:status, {"ROBOT DONE"}})
      Enum.each(0..-5, fn y ->
        row = Enum.map(0..42, fn x ->
          Map.get(map, {x, y}, 0)
        end)
        send(Process.get(:parent_pid), {:status, row})
      end)
      exit(1)
    end

    color = receive do
      {:input, color} -> color
    after
      1000 -> :timeout
    end
    dir = receive do
      {:input, dir} -> dir
    after
      1000 -> :timeout
    end
    if color == :timeout do
      run(current, map, visited)
    end

    {current, map, visited} = paint_and_move(current, map, visited, color, dir)
    run(current, map, visited)
  end

  def paint_and_move(current, map, visited, color, dir) do
    {cur_pos, _, _} = current
    map = Map.put(map, cur_pos, color)

    {new_pos, new_dir} = move(current, dir)
    new_color = Map.get(map, new_pos, 0)
    visited = MapSet.put(visited, new_pos)

    {{new_pos, new_dir, new_color}, map, visited}
  end

  def move(current, dir) do
    {cur_pos, cur_dir, _} = current
    new_dir = case cur_dir do
      :up -> if dir == 0, do: :left, else: :right
      :left -> if dir == 0, do: :down, else: :up
      :down -> if dir == 0, do: :right, else: :left
      :right -> if dir == 0, do: :up, else: :down
    end

    {cur_x, cur_y} = cur_pos
    new_pos = case new_dir do
      :up -> {cur_x, cur_y + 1}
      :left -> {cur_x - 1, cur_y}
      :down -> {cur_x, cur_y - 1}
      :right -> {cur_x + 1, cur_y}
    end
    {new_pos, new_dir}
  end
end

program = hd(System.argv())
          |> File.read!()
          |> String.replace(~r/\r|\n/, "")
          |> String.split(",", trim: true)
          |> Enum.map(&String.to_integer/1)

ram = Enum.reduce(1..10000, [], fn _, acc ->
  [0 | acc] 
end)

mem = Stream.zip(Stream.iterate(0, &(&1+1)), program ++ ram)
|> Enum.into(%{})

pid_a = spawn(Intcode, :spawn, [self(), mem])
pid_b = spawn(PaintRobot, :spawn, [self()])
send(pid_b, {:output_pid, pid_a})
send(pid_a, {:output_pid, pid_b})

Intcode.listener()

