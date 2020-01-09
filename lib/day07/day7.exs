defmodule Intcode do
  def spawn(parent_pid, mem) do
    receive do
      {:output_pid, output_pid} -> Process.put(:output_pid, output_pid)
    end
    Process.put(:parent_pid, parent_pid)
    run(mem)
  end

  def run(mem), do: run(mem, 0)
  def run(_mem, -99), do: exit(99)
  def run(mem, cursor) do
    # IO.puts("Exec instruction " <> Integer.to_string(mem[cursor]))
    {mem, cursor} = case rem(mem[cursor], 100) do
      1 -> exec_add(mem, cursor)
      2 -> exec_multiply(mem, cursor)
      3 -> exec_input(mem, cursor)
      4 -> exec_output(mem, cursor)
      5 -> exec_jump_true(mem, cursor)
      6 -> exec_jump_false(mem, cursor)
      7 -> exec_less_than(mem, cursor)
      8 -> exec_equals(mem, cursor)
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
    mem[cursor]
    |> Integer.to_string
    |> String.pad_leading(2+num, "0")
    |> String.slice(-(2+num)..-(2+num))
    |> case do
      "1" -> mem[cursor+num]
      "0" -> mem[mem[cursor+num]]
    end
  end

  defp exec_add(mem, cursor) do
    a = get_param(mem, cursor, 1)
    b = get_param(mem, cursor, 2)
    {Map.put(mem, mem[cursor + 3], a + b), cursor + 4}
  end

  defp exec_multiply(mem, cursor) do
    a = get_param(mem, cursor, 1)
    b = get_param(mem, cursor, 2)
    {Map.put(mem, mem[cursor + 3], a * b), cursor + 4}
  end

  defp exec_input(mem, cursor) do
    receive do
      {:input, input} -> {Map.put(mem, mem[cursor + 1], input), cursor + 2}
    end
  end

  defp exec_output(mem, cursor) do
    output = get_param(mem, cursor, 1)
    if Process.alive?(Process.get(:output_pid)) do
      send(Process.get(:output_pid), {:input, output})
    else
      send(Process.get(:parent_pid), {:done, output})
    end
    {mem, cursor + 2}
  end

  defp exec_jump_true(mem, cursor) do
    a = get_param(mem, cursor, 1)
    b = get_param(mem, cursor, 2)
    {mem, (if a != 0, do: b, else: cursor + 3)}
  end

  defp exec_jump_false(mem, cursor) do
    a = get_param(mem, cursor, 1)
    b = get_param(mem, cursor, 2)
    {mem, (if a == 0, do: b, else: cursor + 3)}
  end

  defp exec_less_than(mem, cursor) do
    a = get_param(mem, cursor, 1)
    b = get_param(mem, cursor, 2)
    result = if a < b, do: 1, else: 0
    {Map.put(mem, mem[cursor + 3], result), cursor + 4}
  end

  defp exec_equals(mem, cursor) do
    a = get_param(mem, cursor, 1)
    b = get_param(mem, cursor, 2)
    result = if a == b, do: 1, else: 0
    {Map.put(mem, mem[cursor + 3], result), cursor + 4}
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

mem = Stream.zip(Stream.iterate(0, &(&1+1)), program)
|> Enum.into(%{})

# part 1
#Intcode.permutations([0,1,2,3,4])

Intcode.permutations([5,6,7,8,9])
|> Enum.reduce({[], 0}, fn phase, acc ->
  {_best_phase, max_output} = acc
  [phase_a, phase_b, phase_c, phase_d, phase_e] = phase

  pid_a = spawn(Intcode, :spawn, [self(), mem])
  pid_b = spawn(Intcode, :spawn, [self(), mem])
  pid_c = spawn(Intcode, :spawn, [self(), mem])
  pid_d = spawn(Intcode, :spawn, [self(), mem])
  pid_e = spawn(Intcode, :spawn, [self(), mem])

  send(pid_a, {:output_pid, pid_b})
  send(pid_b, {:output_pid, pid_c})
  send(pid_c, {:output_pid, pid_d})
  send(pid_d, {:output_pid, pid_e})
  send(pid_e, {:output_pid, pid_a})

  send(pid_a, {:input, phase_a})
  send(pid_b, {:input, phase_b})
  send(pid_c, {:input, phase_c})
  send(pid_d, {:input, phase_d})
  send(pid_e, {:input, phase_e})
  send(pid_a, {:input, 0})

  output = receive do
    {:done, output} -> output
  end

  if output > max_output do
    {phase, output}
  else
    acc
  end
end)
|> IO.inspect()

