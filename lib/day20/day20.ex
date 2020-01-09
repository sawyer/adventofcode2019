defmodule Aoc2019.Day20 do
  @moduledoc """
  Documentation for Aoc2019 Day 20. Very similar to day 18 except the
  graph will have additional edges for the portals. Because it'll be annoying
  to parse the file for the portal locations I'll probably enumerate them
  manually.
  """

  def xy_map_to_graph_2(map, levels) do
    e = Enum.reduce(0..levels, [], fn z, e ->
      e = Enum.reduce(map, e, fn {{x,y}, c}, e ->
        if c == "." do
          e = if map[{x+1, y}] == ".", do: [{{x,y,z}, {x+1,y,z}} | e], else: e
          e = if map[{x-1, y}] == ".", do: [{{x,y,z}, {x-1,y,z}} | e], else: e
          e = if map[{x, y+1}] == ".", do: [{{x,y,z}, {x,y+1,z}} | e], else: e
          e = if map[{x, y-1}] == ".", do: [{{x,y,z}, {x,y-1,z}} | e], else: e
          e
        else
          e
        end
      end)

      Enum.reduce(portals(), e, fn {_, {{fx,fy},{tx,ty}}}, e ->
        e = [{{fx,fy,z}, {tx,ty,z-1}} | e]
        [{{tx,ty,z}, {fx,fy,z+1}} | e]
      end)
    end)

    Graph.new |> Graph.add_edges(e)
  end

  def xy_map_to_graph_1(map) do
    z = 0
    e = Enum.reduce(map, [], fn {{x,y}, c}, e ->
      if c == "." do
        e = if map[{x+1, y}] == ".", do: [{{x,y,z}, {x+1,y,z}} | e], else: e
        e = if map[{x-1, y}] == ".", do: [{{x,y,z}, {x-1,y,z}} | e], else: e
        e = if map[{x, y+1}] == ".", do: [{{x,y,z}, {x,y+1,z}} | e], else: e
        e = if map[{x, y-1}] == ".", do: [{{x,y,z}, {x,y-1,z}} | e], else: e
        e
      else
        e
      end
    end)

    e = Enum.reduce(portals(), e, fn {_, {{fx,fy},{tx,ty}}}, e ->
      e = [{{fx,fy,z}, {tx,ty,z}} | e]
      [{{tx,ty,z}, {fx,fy,z}} | e]
    end)

    Graph.new |> Graph.add_edges(e)
  end

  @doc """
  # example p2
  def portals do
    %{
      "LP" => {{15,2}, {29,28}},
      "XQ" => {{17,2}, {21,28}},
      "WB" => {{19,2}, {36,13}},
      "CK" => {{27,2}, {8,17}},
      "ZH" => {{42,13}, {31,8}},
      "IC" => {{42,17}, {23,8}},
      "RF" => {{42,25}, {36,21}},
      "NM" => {{23,34}, {36,23}},
      "FD" => {{19,34}, {13,8}},
      "OA" => {{17,34}, {8,13}},
      "RE" => {{2,25}, {21,8}},
      "XF" => {{2,21}, {17,28}},
      "CJ" => {{2,15}, {8,23}}
    }
  end
  def startp, do: {15,34,0}
  def endp, do: {13,2,0}
  """

  def portals do
    %{
      "AO" => {{2,73}, {88,55}},
      "CA" => {{118,41}, {32,73}},
      "DR" => {{73,2}, {32,39}},
      "HK" => {{51,122}, {41,92}},
      "HU" => {{2,63}, {88,79}},
      "KA" => {{35,122}, {63,92}},
      "KJ" => {{37,2}, {81,32}},
      "KM" => {{65,122}, {32,45}},
      "LU" => {{118,47}, {88,75}},
      "ME" => {{2,57}, {53,92}},
      "MH" => {{81,122}, {88,59}},
      "MU" => {{55,2}, {83,92}},
      "NH" => {{118,61}, {49,92}},
      "NI" => {{79,2}, {75,32}},
      "OP" => {{118,75}, {45,32}},
      "QC" => {{2,41}, {32,53}},
      "QD" => {{61,2}, {88,45}},
      "QH" => {{2,85}, {61,32}},
      "QL" => {{118,81}, {32,87}},
      "QN" => {{61,122}, {73,92}},
      "RB" => {{75,122}, {67,92}},
      "TJ" => {{49,122}, {43,32}},
      "VR" => {{45,2}, {59,32}},
      "WC" => {{2,79}, {88,49}},
      "WY" => {{118,67}, {32,75}},
      "XB" => {{118,57}, {88,67}},
      "XF" => {{2,45}, {32,61}}
    }
  end
  def startp, do: {118,49,0}
  def endp, do: {2,47,0}

  @doc """
  ## Solve P1
    iex> Aoc2019.Day20.p1
  """
  def p1(), do: p1("lib/day20/input.txt")
  def p1(fp) do
    xy_map = Aoc2019.input_to_xy_map(fp)
    g = xy_map_to_graph_1(xy_map)

    Graph.Pathfinding.dijkstra(g, startp(), endp())
    |> length() |> IO.inspect
  end

  @doc """
  ## Solve P2
    iex> Aoc2019.Day20.p2
  """
  def p2(), do: p2("lib/day20/input.txt")
  def p2(fp) do
    xy_map = Aoc2019.input_to_xy_map(fp)
    g = xy_map_to_graph_2(xy_map, 27) # z dimension is # of portals

    Graph.Pathfinding.dijkstra(g, startp(), endp())
    |> length() |> IO.inspect
  end

end

