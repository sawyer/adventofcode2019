defmodule Aoc2019.Day25 do
  @moduledoc """
  Text adventure to save Santa!
  """

  def command(ipid, buffer) do
    c = receive do
      {:input, c} -> c
    end

    buffer = if c == 10 do
      IO.puts(buffer)
      if buffer == "Command?" do
        c = IO.gets("")
        String.to_charlist(c)
        |> Enum.each(&send(ipid, {:input, &1}))
      end
      ""
    else
      buffer <> List.to_string([c])
    end

    command(ipid, buffer)
  end

  @doc """
  See solution.txt for notes while playing!
  iex> Aoc2019.Day25.p1
  """
  def p1 do
    mem = Aoc2019.Intcode.file_input_to_mem("lib/day25/input.txt")
    ipid = spawn(Aoc2019.Intcode, :spawn, [self(), mem])
    send(ipid, {:output_pid, self()})

    command(ipid, "")
  end
end

