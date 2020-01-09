defmodule Aoc2019 do
  @moduledoc """
  Documentation for Aoc2019.
  """

  def input_lines(fp) do
    fp
    |> File.read!()
    |> String.split("\n", trim: true)
  end

  @doc """
  Parse lines of input txt file into a map of x,y coordinates => the
  input character.

  ## Examples
  iex> Aoc2019.input_to_xy_map
  %{
    {3, 3} => ".",
    {23, 2} => "#",
    ...
  }
  """
  def input_to_xy_map(fp) do
    {map, _, _} = fp
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.map(&String.split(&1, "", trim: true))
    |> Enum.reduce({%{}, 0, 0}, fn row, {map, _, y} ->
      {map, _, _} = Enum.reduce(row, {map, 0, y}, fn char, {map, x, y} ->
        {Map.put(map, {x, y}, char), x+1, y}
      end)
      {map, 0, y + 1}
    end)
    map
  end
end
