defmodule Aoc2019.Day24 do
  @moduledoc """
  Game of life
  """

  def gol_step(xymap, {x, y}) do
    c = xymap[{x,y}]
    surroundings = [
      Map.get(xymap, {x + 1, y}, "."),
      Map.get(xymap, {x - 1, y}, "."),
      Map.get(xymap, {x, y + 1}, "."),
      Map.get(xymap, {x, y - 1}, ".")
    ]
    bug_count = Enum.count(surroundings, fn x -> x == "#" end)
    
    case c do
      "#" -> if bug_count != 1, do: ".", else: "#"
      "." -> if bug_count == 1 or bug_count == 2, do: "#", else: "."
    end
  end

  def gol_step2(xyzmap, {x, y, z}) do
    c = xyzmap[{x,y,z}]
    srnd = []
    srnd = case {x + 1, y} do
      {5, _} -> [Map.get(xyzmap, {3, 2, z - 1}) | srnd]
      {2, 2} ->
        srnd = [Map.get(xyzmap, {0, 0, z + 1}) | srnd]
        srnd = [Map.get(xyzmap, {0, 1, z + 1}) | srnd]
        srnd = [Map.get(xyzmap, {0, 2, z + 1}) | srnd]
        srnd = [Map.get(xyzmap, {0, 3, z + 1}) | srnd]
        [Map.get(xyzmap, {0, 4, z + 1}) | srnd]
      _ -> [Map.get(xyzmap, {x + 1, y, z}) | srnd]
    end
    srnd = case {x - 1, y} do
      {-1, _} -> [Map.get(xyzmap, {1, 2, z - 1}) | srnd]
      {2, 2} ->
        srnd = [Map.get(xyzmap, {4, 0, z + 1}) | srnd]
        srnd = [Map.get(xyzmap, {4, 1, z + 1}) | srnd]
        srnd = [Map.get(xyzmap, {4, 2, z + 1}) | srnd]
        srnd = [Map.get(xyzmap, {4, 3, z + 1}) | srnd]
        [Map.get(xyzmap, {4, 4, z + 1}) | srnd]
      _ -> [Map.get(xyzmap, {x - 1, y, z}) | srnd]
    end
    srnd = case {x, y + 1} do
      {_, 5} -> [Map.get(xyzmap, {2, 3, z - 1}) | srnd]
      {2, 2} ->
        srnd = [Map.get(xyzmap, {0, 0, z + 1}) | srnd]
        srnd = [Map.get(xyzmap, {1, 0, z + 1}) | srnd]
        srnd = [Map.get(xyzmap, {2, 0, z + 1}) | srnd]
        srnd = [Map.get(xyzmap, {3, 0, z + 1}) | srnd]
        [Map.get(xyzmap, {4, 0, z + 1}) | srnd]
      _ -> [Map.get(xyzmap, {x, y + 1, z}) | srnd]
    end
    srnd = case {x, y - 1} do
      {_, -1} -> [Map.get(xyzmap, {2, 1, z - 1}) | srnd]
      {2, 2} ->
        srnd = [Map.get(xyzmap, {0, 4, z + 1}) | srnd]
        srnd = [Map.get(xyzmap, {1, 4, z + 1}) | srnd]
        srnd = [Map.get(xyzmap, {2, 4, z + 1}) | srnd]
        srnd = [Map.get(xyzmap, {3, 4, z + 1}) | srnd]
        [Map.get(xyzmap, {4, 4, z + 1}) | srnd]
      _ -> [Map.get(xyzmap, {x, y - 1, z}) | srnd]
    end
    
    bug_count = Enum.count(srnd, fn x -> x == "#" end)
    
    d = case c do
      "#" -> if bug_count != 1, do: ".", else: "#"
      "." -> if bug_count == 1 or bug_count == 2, do: "#", else: "."
    end
    if {x, y} == {2, 2} do
      "."
    else
      d
    end
  end

  def generation(xymap) do
    Enum.reduce(xymap, %{}, fn {{x, y}, _}, newmap ->
      Map.put(newmap, {x, y}, gol_step(xymap, {x, y}))
    end)
  end

  def generation2(xyzmap) do
    Enum.reduce(xyzmap, %{}, fn {{x, y, z}, _}, newmap ->
      Map.put(newmap, {x, y, z}, gol_step2(xyzmap, {x, y, z}))
    end)
  end

  def biodiversity(xymap) do
    Enum.reduce(xymap, 0, fn {{x, y}, c}, biod ->
      if c == "#" do
        biod + :math.pow(2, (y * 5) + x)
      else
        biod
      end
    end)
  end

  @doc """
  iex> Aoc2019.Day24.p1
  """
  def p1 do
    xymap = Aoc2019.input_to_xy_map("./lib/day24/input.txt")
    Enum.reduce(0..100, {xymap, MapSet.new}, fn _, {xymap, biodset} ->
      newmap = generation(xymap)
      biod = biodiversity(newmap)
      if MapSet.member?(biodset, biod) do
        exit(biod)
      end
      {newmap, MapSet.put(biodset, biod)}
    end)
  end

  @doc """
  Modify p1 to operate in an extra 'z' dimension.

  iex> Aoc2019.Day24.p2
  """
  def p2 do
    xymap = Aoc2019.input_to_xy_map("./lib/day24/input.txt")
    xyzmap = Enum.reduce(-201..201, %{}, fn z, xyzmap ->
      Map.put(xyzmap, {0, 0, z}, ".")
      |> Map.put({0, 1, z}, ".")
      |> Map.put({0, 2, z}, ".")
      |> Map.put({0, 3, z}, ".")
      |> Map.put({0, 4, z}, ".")
      |> Map.put({1, 0, z}, ".")
      |> Map.put({1, 1, z}, ".")
      |> Map.put({1, 2, z}, ".")
      |> Map.put({1, 3, z}, ".")
      |> Map.put({1, 4, z}, ".")
      |> Map.put({2, 0, z}, ".")
      |> Map.put({2, 1, z}, ".")
      |> Map.put({2, 2, z}, ".")
      |> Map.put({2, 3, z}, ".")
      |> Map.put({2, 4, z}, ".")
      |> Map.put({3, 0, z}, ".")
      |> Map.put({3, 1, z}, ".")
      |> Map.put({3, 2, z}, ".")
      |> Map.put({3, 3, z}, ".")
      |> Map.put({3, 4, z}, ".")
      |> Map.put({4, 0, z}, ".")
      |> Map.put({4, 1, z}, ".")
      |> Map.put({4, 2, z}, ".")
      |> Map.put({4, 3, z}, ".")
      |> Map.put({4, 4, z}, ".")
    end)
    xyzmap = Enum.reduce(xymap, xyzmap, fn {{x,y}, c}, xyzmap ->
      Map.put(xyzmap, {x, y, 0}, c)
    end)
    
    final = Enum.reduce(0..199, xyzmap, fn _, xyzmap ->
      generation2(xyzmap)
    end)
    Enum.count(final, fn {_, v} -> v == "#" end)
    |> IO.inspect
  end
end
