defmodule Aoc2019.Day21 do
  @moduledoc """
  Aoc2019 Day 21. Input is Intcode program for interfacing with the springdroid.
  We need to program the springdroid using springscript, up to 15 instructions.
  """

  def spawn(parent_pid, script) do
    receive do
      {:output_pid, output_pid} -> Process.put(:output_pid, output_pid)
    end
    Process.put(:parent_pid, parent_pid)
    run(script, 0, "")
  end

  def run(script, dmg, buffer) do
    String.to_charlist(script)
    |> Enum.each(&send(Process.get(:output_pid), {:input, &1}))

    output = receive do
      {:input, output} -> output
    after
      3000 -> :timeout
    end
    if output == :timeout do
      :timer.sleep(1000); exit(1)
    end

    dmg = if output > 255 do
      dmg + output
    else
      dmg
    end
    buffer = if output < 255 do
      buffer <> List.to_string([output])
    else
      buffer
    end

    send(Process.get(:parent_pid), {:puts, "DAMAGE:" <> Integer.to_string(dmg)})
    send(Process.get(:parent_pid), {:puts, "BUFFER:" <> buffer})
    run("", dmg, buffer)
  end

  @doc """
  ## Solve P1
    iex> Aoc2019.Day21.p1
  """
  def p1(), do: p1("lib/day21/input.txt")
  def p1(fp) do
    mem = Aoc2019.Intcode.file_input_to_mem(fp)

    script = Enum.join([
      "NOT A J",
      "NOT C T",
      "OR T J",
      "AND D J",
      "WALK\n",
    ], "\n")

    IO.inspect(script)

    pid_a = spawn(Aoc2019.Intcode, :spawn, [self(), mem])
    pid_b = spawn_link(Aoc2019.Day21, :spawn, [self(), script])
    send(pid_a, {:output_pid, pid_b})
    send(pid_b, {:output_pid, pid_a})

    Aoc2019.Intcode.listener()
  end

  @doc """
  Jump:
     ABCDEFGHI
  1 @ ********
  2 @* ** ****
  3 @** *  ***
  4 @*  * ****
  5 @ * **  **
  6 @   ******
  
  Don't jump:
     ABCDEFGHI
  7 @** * **
  
  ## Solve P2
    iex> Aoc2019.Day21.p2
  """
  def p2(), do: p2("lib/day21/input.txt")
  def p2(fp) do
    mem = Aoc2019.Intcode.file_input_to_mem(fp)

    script = Enum.join([
      "NOT A J", # 1
      "NOT C T", # 3-6
      "AND H T", # exclude 7
      "OR T J",
      "NOT B T", # 2
      "OR T J",
      "AND D J", # land
      "RUN\n",
    ], "\n")

    pid_a = spawn(Aoc2019.Intcode, :spawn, [self(), mem])
    pid_b = spawn_link(Aoc2019.Day21, :spawn, [self(), script])
    send(pid_a, {:output_pid, pid_b})
    send(pid_b, {:output_pid, pid_a})

    Aoc2019.Intcode.listener()
  end
end
