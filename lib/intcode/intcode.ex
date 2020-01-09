defmodule Aoc2019.Intcode do
  @doc """
  Parse an input file as an intcode program and return its memory map.

  ## Examples
    iex> Aoc2019.Intcode.file_input_to_mem("lib/day19/input.txt")
  """
  def file_input_to_mem(fp) do
    program = fp
    |> File.read!()
    |> String.replace(~r/\r|\n/, "")
    |> String.split(",", trim: true)
    |> Enum.map(&String.to_integer/1)

    ram = Enum.reduce(1..100000, [], fn _, acc -> [0 | acc] end)

    Stream.zip(Stream.iterate(0, &(&1+1)), program ++ ram)
    |> Enum.into(%{})
  end

  @doc """
  Start an intcode program in a new process. The program will wait to receive
  an :output_pid message which it requires for sending output.

  ## Examples
    iex> pid_a = spawn(Intcode, :spawn, [self(), mem])
    iex> pid_b = spawn(Intcode, :spawn, [self(), mem])
    iex> send(pid_a, {:output_pid, pid_b})
    iex> send(pid_b, {:output_pid, pid_a})
  """
  def spawn(parent_pid, mem) do
    receive do
      {:output_pid, output_pid} -> Process.put(:output_pid, output_pid)
    end
    Process.put(:parent_pid, parent_pid)
    Process.put(:relative_base, 0)
    run(mem)
  end

  def run(mem), do: run(mem, 0)
  def run(_mem, -99), do: exit(99)
  def run(mem, cursor) do
    
    #IO.inspect(mem[cursor], label: "#{inspect self()} Exec instruction")

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
    input = receive do
      {:input, input} -> input
    #after # for day 23
      #1000 -> -1
    end
    #IO.inspect(input, label: "#{inspect self()} [03] Input received")
    {Map.put(mem, a, input), cursor + 2}
  end

  defp exec_output(mem, cursor) do
    output = mem[get_param(mem, cursor, 1)]
    if Process.alive?(Process.get(:output_pid)) do
      send(Process.get(:output_pid), {:input, output})
    else
      send(Process.get(:parent_pid), {:done, output})
    end
    #IO.inspect(output, label: "#{inspect self()} [04] Output sent")
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

  @doc """
  This listener is meant to be run in the parent thread of the intcode
  program. All it does is listen for :status messages that the intcode
  process or any other process cares to send.

  ## Examples
    iex> send(Process.get(:parent_pid), {:status, "Message for parent."})
  """
  def listener do
    receive do
      {:inspect, output} -> IO.inspect(output)
      {:puts, output} -> IO.puts(output)
    end
    listener()
  end

end

