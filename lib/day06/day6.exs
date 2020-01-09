defmodule Orbits do
  def find_vertex(tree, label) do
    Enum.find(:digraph.vertices(tree), false, fn v ->
      elem(:digraph.vertex(tree, v), 1) == label
    end)
  end

  def find_or_create_vertex(tree, label) do
    Enum.find(:digraph.vertices(tree), false, fn v ->
      elem(:digraph.vertex(tree, v), 1) == label
    end) || :digraph.add_vertex(tree, :digraph.add_vertex(tree), label)
  end

  def set_xor_size(a, b) do
    a_set = MapSet.new(a)
    b_set = MapSet.new(b)
    both_set = MapSet.new(a ++ b)
    MapSet.size(both_set) - MapSet.size(MapSet.intersection(a_set, b_set))
  end

end

tree = :digraph.new()

hd(System.argv())
|> File.read!()
|> String.split(~r/\R/, trim: true)
|> Enum.each(fn orbit ->
  [left_label, right_label] = String.split(orbit, ")", trim: true)
  l = Orbits.find_or_create_vertex(tree, left_label)
  r = Orbits.find_or_create_vertex(tree, right_label)
  :digraph.add_edge(tree, l, r)
end)

{:yes, root} = :digraph_utils.arborescence_root(tree)

:digraph.vertices(tree)
|> Enum.reduce(0, fn v, i ->
  i + length(:digraph.get_path(tree, root, v) || [:root]) - 1 # 1 = omit root
end)
|> IO.puts

youpath = :digraph.get_path(tree, root, Orbits.find_vertex(tree, "YOU"))
sanpath = :digraph.get_path(tree, root, Orbits.find_vertex(tree, "SAN"))
Orbits.set_xor_size(youpath, sanpath) - 2 # 2 = omit YOU and SAN
|> IO.puts

