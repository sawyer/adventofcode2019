defmodule Intcode do
  def run(prog, pos \\ 0) do
    case prog[pos] do
      1 ->
        prog
        |> Map.put(prog[pos+3], prog[prog[pos+1]] + prog[prog[pos+2]])
        |> run(pos+4)
      2 ->
        prog
        |> Map.put(prog[pos+3], prog[prog[pos+1]] * prog[prog[pos+2]])
        |> run(pos+4)
      99 -> prog[0]
    end
  end
end

list = "input.txt"
|> File.read!()
|> String.replace(~r/\r|\n/, "")
|> String.split(",", trim: true)
|> Enum.map(&String.to_integer/1)

program = Stream.zip(Stream.iterate(0, &(&1+1)), list)
|> Enum.into(%{})

for noun <- 0..99, verb <- 0..99 do
  output = program
           |> Map.put(1, noun)
           |> Map.put(2, verb)
           |> Intcode.run()

  if output == 19690720 do
    IO.puts(noun)
    IO.puts(verb)
  end
end

