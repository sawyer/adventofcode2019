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
      {:done, output} -> IO.puts(output)
    end
    listener()
  end

  def run(mem), do: run(mem, 0)
  def run(_mem, -99), do: exit(99)
  def run(mem, cursor) do
    #IO.puts("Exec instruction " <> Integer.to_string(mem[cursor]))
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
    #IO.inspect(mem)

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
pid_b = spawn fn -> :ok end
send(pid_a, {:output_pid, pid_b})
send(pid_a, {:input, 2})

Intcode.listener()

