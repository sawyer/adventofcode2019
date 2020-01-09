defmodule TraceWire do
  def expand(moves) do
    moves
    |> Enum.map(fn move ->
      <<move_dir :: binary-size(1)>> <> steps_str = move
      steps_int = String.to_integer(steps_str)
      Enum.map(1..steps_int, fn _ ->
        case move_dir do
          "R" -> {1, 0}
          "L" -> {-1, 0}
          "U" -> {0, 1}
          "D" -> {0, -1}
        end
      end)
    end)
    |> List.flatten()
  end

  @doc ~S"""
  Takes a list of steps and returns a list of tuples containing the
  number of steps and each coordinate visited e.g. [{0, {0,0}}, {1, {1,0}}, ...]
  """
  def map(steps) do
    steps
    |> Enum.reduce([{0, {0,0}}], fn step, acc ->
      num_steps = elem(hd(acc),0)
      last_pos = elem(hd(acc),1)
      new_pos = last_pos
      |> put_elem(0, elem(last_pos, 0) + elem(step, 0)) 
      |> put_elem(1, elem(last_pos, 1) + elem(step, 1))
      [{num_steps + 1, new_pos} | acc]
    end)
  end

  @doc ~S"""
  a and b are tuples of the form {num_steps, {x, y}} e.g. {1, {1, 0}}
  """
  def manhattan_intersections(a, b) do
    aset = a |> Enum.map(fn t -> elem(t, 1) end) |> MapSet.new()
    bset = b |> Enum.map(fn t -> elem(t, 1) end) |> MapSet.new()

    MapSet.intersection(aset, bset) |> Enum.map(&manhattan_dist/1)
  end

  @doc ~S"""
  a and b are tuples of the form {num_steps, {x, y}} e.g. {1, {1, 0}}

  First create a MapSet of each set of coordinates then find the coordinate
  in the original step map (a and b) to retrieve the num_steps (tuple elem 0)
  """
  def step_intersections(a, b) do
    aset = a |> Enum.map(fn t -> elem(t, 1) end) |> MapSet.new()
    bset = b |> Enum.map(fn t -> elem(t, 1) end) |> MapSet.new()

    MapSet.intersection(aset, bset)
    |> Enum.map(fn intersection ->
      elem(Enum.find(a, nil, fn step -> elem(step, 1) == intersection end), 0) + 
      elem(Enum.find(b, nil, fn step -> elem(step, 1) == intersection end), 0)
    end)
  end

  defp manhattan_dist({x,y}), do: abs(x) + abs(y)
end

steps = "input.txt"
|> File.read!()
|> String.split(~r/\R/, trim: true)
|> Enum.map(&String.split(&1, ",", trim: true))
|> Enum.map(&TraceWire.expand/1)

maps = steps
|> Enum.map(&TraceWire.map/1)
|> Enum.map(&Enum.reject(&1, fn step -> elem(step, 1) == {0,0} end))

TraceWire.manhattan_intersections(hd(maps), hd(tl(maps)))
|> Enum.min()
|> IO.inspect

TraceWire.step_intersections(hd(maps), hd(tl(maps)))
|> Enum.min()
|> IO.inspect

