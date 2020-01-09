defmodule Intcode do
  def run(mem, cursor \\ 0) do
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
      99 -> exit(99)
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
    input = IO.gets([Integer.to_string(cursor), " input: "])
            |> String.trim("\n")
            |> String.to_integer
    {Map.put(mem, mem[cursor + 1], input), cursor + 2}
  end

  defp exec_output(mem, cursor) do
    get_param(mem, cursor, 1) |> IO.puts()
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

end

program = hd(System.argv())
          |> File.read!()
          |> String.replace(~r/\r|\n/, "")
          |> String.split(",", trim: true)
          |> Enum.map(&String.to_integer/1)

_mem = Stream.zip(Stream.iterate(0, &(&1+1)), program)
|> Enum.into(%{})
|> Intcode.run

