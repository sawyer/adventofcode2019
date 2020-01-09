defmodule Aoc2019.Day18 do
  @moduledoc """
  Documentation for Aoc2019 Day 18.
  """

  @doc """
  Parse lines of input txt file into a map of x,y coordinates => the
  input character.

  ## Examples
    iex> Aoc2019.Day18.input_to_xy_map
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

  def xy_map_to_graph(map) do
    edges = Enum.reduce(map, [], fn {{x,y}, c}, e ->
      if c != "#" do
        e = if map[{x+1, y}] != "#", do: [{{x, y}, {x+1, y}} | e], else: e
        e = if map[{x-1, y}] != "#", do: [{{x, y}, {x-1, y}} | e], else: e
        e = if map[{x, y+1}] != "#", do: [{{x, y}, {x, y+1}} | e], else: e
        e = if map[{x, y-1}] != "#", do: [{{x, y}, {x, y-1}} | e], else: e
        e
      else
        e
      end
    end)
    Graph.new |> Graph.add_edges(edges)
  end

  @doc """
  Transform an xy map %{ {x,y} => c } into a path map by using a graph
  to map all paths between points of interest.

  ## Examples
    iex> Aoc2019.Day18.xy_map_to_path_map(xy_map, g)
    %{
      {"@", "a"} => {path, doors_in_path, keys_in_path},
      ...
    }
  """
  def xy_map_to_path_map(xy_map, g) do
    {km, dm} = Enum.reduce(xy_map, {%{}, %{}}, fn {{x,y}, c}, {k, d} ->
      k = if c in keys() or c == "@" or c =="$" or c=="&" or c=="*" do
        Map.put(k, c, {x, y})
      else
        k
      end
      d = if c in doors() do
        Map.put(d, c, {x, y})
      else
        d
      end
      {k, d}
    end)

    Enum.reduce(km, %{}, fn {to_k, {to_x, to_y}}, key_paths ->
      Enum.reduce(km, key_paths, fn {from_k, {from_x, from_y}}, key_paths ->
        path = Graph.Pathfinding.dijkstra(g, {from_x, from_y}, {to_x, to_y})
          
        if path != nil do
          keys_in_path = Enum.reduce(path, [], fn step, acc ->
            if step in Map.values(Map.drop(km, ["@","$","&","*"])) do
              [xy_map[step] | acc]
            else
              acc
            end
          end) 
          doors_in_path = Enum.reduce(path, [], fn step, acc ->
            if step in Map.values(dm) do
              [xy_map[step] | acc]
            else
              acc
            end
          end)
          Map.put(key_paths, {from_k, to_k}, {path, doors_in_path, keys_in_path})
        else
          key_paths
        end
      end)
    end)
  end

  def keys, do: ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]

  def doors, do: ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]

  def unlocked(c, cur_keys) do
    if String.downcase(c) in cur_keys do
     true
    else
     false
    end
  end

  def all_unlocked(doors_in_path, cur_keys) do
    Enum.all?(doors_in_path, fn d ->
      String.downcase(d) in cur_keys
    end)
  end

  @doc """
  A proper BFS, the first step we take to the final key is guaranteed
  to be the shortest, so echo it and exit.
  """
  def bfs(q, v, map) do
    {{:value, {cur_pos, cur_keys}}, q} = :queue.out(q)
    d = Map.fetch!(v, {cur_pos, cur_keys})

    {q, v} = Enum.reduce(Aoc2019.Compass.dirs, {q, v}, fn dir, {q, v} ->
      pos = Aoc2019.Compass.pos_in_dir(cur_pos, dir)
      c = map[pos]
      cond do
        c == "#" -> {q, v}
        c in doors() and not unlocked(c, cur_keys) -> {q, v}
        c == "." or c == "@" or unlocked(c, cur_keys) or c in keys() ->
          new_keys = if c in keys() and c not in cur_keys do
            Enum.sort([c | cur_keys])
          else
            cur_keys
          end
          if new_keys == keys() do
            IO.inspect(d + 1)
            exit(1)
          end
          if Map.has_key?(v, {pos, new_keys}) do
            {q, v}
          else
            {:queue.in({pos, new_keys}, q), Map.put(v, {pos, new_keys}, d+1)}
          end
      end
    end)

    bfs(q, v, map)
  end

  @doc """
  This version of BFS operates on precomputed paths so it will find more
  than one path to the goal. It returns the visited map so that we can
  inspect it for the best path to the goal in part2.

  State is {pos_1, pos_2, pos_3, pos_4, collected_keys}
  where pos_1 - 4 are key names, not coordinates which can be used
  with the key_path map we generated in xy_map_to_path_map.
  """
  def bfs2(q, v, map, key_paths) do
    {{:value, cur_state}, q} = :queue.out(q)
    {cp1, cp2, cp3, cp4, cur_keys} = cur_state

    d = Map.fetch!(v, cur_state)

    # map and key_paths stay static each call of bfs2 but we prune
    # the key_path space to remove keys we don't need so that the
    # search space is reduced somewhat
    drop_paths = Enum.zip(keys() ++ ["@", "$", "&", "*"], cur_keys)
    new_key_paths = Map.drop(key_paths, drop_paths)

    {q, v} = Enum.reduce(1..4, {q, v}, fn ab, {q, v} ->
      ck = case ab do # ab = active bot
        1 -> cp1
        2 -> cp2
        3 -> cp3
        4 -> cp4
      end
      Enum.reduce(new_key_paths, {q, v}, fn {{fk, tk}, {p, dip, kip}}, {q, v} ->
        if fk == ck and all_unlocked(dip, cur_keys) and tk not in cur_keys and tk in keys() do
          # pick up all keys in path that we don't already have
          add_keys = Enum.filter(kip, fn k -> k not in cur_keys end)
          new_keys = Enum.sort(add_keys ++ cur_keys)

          new_d = d + (length(p) - 1) # path includes the cur_pos so minus 1

          new_state = case ab do
            1 -> {tk, cp2, cp3, cp4, new_keys}
            2 -> {cp1, tk, cp3, cp4, new_keys}
            3 -> {cp1, cp2, tk, cp4, new_keys}
            4 -> {cp1, cp2, cp3, tk, new_keys}
          end

          # only queue the new state if the path to it is better than our
          # current best
          case Map.fetch(v, new_state) do
            {:ok, old_d} ->
              if old_d <= new_d do
                {q, v}
              else
                {:queue.in(new_state, q), Map.put(v, new_state, new_d)}
              end
            :error ->
              {:queue.in(new_state, q), Map.put(v, new_state, new_d)}
          end
        else
          {q, v}
        end
      end)
    end)
   
    if :queue.is_empty(q) do
      v
    else
      bfs2(q, v, map, key_paths)
    end
  end

  @doc """
  Could be optimized to use the paths generated for part2
  but preserved as a demonstration of a purer BFS.

  ## Solve P1
    iex> Aoc2019.Day18.part1
  """
  def part1 do
    xy_map = input_to_xy_map("lib/day18/input.txt")

    {start_pos, _} = Enum.find(xy_map, fn {_, v} -> v == "@" end)
    start_keys = []

    q = :queue.in({start_pos, start_keys}, :queue.new)
    v = %{{start_pos, start_keys} => 0}

    bfs(q, v, xy_map) |> IO.inspect
  end

  @doc """
  Manually replace the 4 starting "@" symbols with unique symbols:
  @, $, &, *

  ## Solve P2
    iex> Aoc2019.Day18.part2
  """
  def part2 do
    xy_map = input_to_xy_map("lib/day18/input2.txt")
    g = xy_map_to_graph(xy_map)
    key_paths = xy_map_to_path_map(xy_map, g)

    start_state = {"@", "$", "&", "*", []}
    q = :queue.in(start_state, :queue.new)
    v = %{start_state => 0}

    all_visited = bfs2(q, v, xy_map, key_paths)
    Enum.filter(all_visited, fn {{_,_,_,_,keys},_} ->
      keys == keys()
    end)
    |> Enum.min_by(fn {{_,_,_,_,_}, steps} -> steps end)
    |> IO.inspect
  end

end

