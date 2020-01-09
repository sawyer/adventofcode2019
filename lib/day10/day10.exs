defmodule Asteroids do
  def to_list(rows) do
    {_, map} = Enum.reduce(rows, {0, []}, fn row, acc ->
      {y, asteroids} = acc
      {_, _, xs} = Enum.reduce(row, {0, y, []}, fn col, acc ->
        {x, y, asteroids} = acc
        if col == "#" do
          {x + 1, y, [{x, y} | asteroids]}
        else
          {x + 1, y, asteroids}
        end
      end)

      {y + 1, asteroids ++ xs}
    end)
    map
  end

  def unit_vector(a, b) do
    {ax, ay} = a
    {bx, by} = b
    {vx, vy} = {bx - ax, by - ay}
    mag = :math.sqrt(:math.pow(vx,2) + :math.pow(vy,2))
    uv = {Float.round(vx / mag, 5), Float.round(vy / mag, 5)}
    uv
  end

  def angle_from_up(v) do
    {ax, ay} = {0, -1}
    {bx, by} = v
    angle = :math.atan2(by, bx) - :math.atan2(ay, ax)
    angle = if (angle < 0), do: angle + (2 * :math.pi), else: angle
    angle * (180 / :math.pi)
  end

  def manhattan_dist({ax,ay}, {bx,by}), do: abs(ax - bx) + abs(ay - by)

  def laser_cycle([]), do: []
  def laser_cycle(sorted) do
    this_pass = Enum.dedup_by(sorted, fn {_, uv} -> uv end)
    remaining = Enum.reject(sorted, fn {b, _} ->
      Enum.any?(this_pass, fn {c, _} -> c == b end)
    end)
    this_pass ++ laser_cycle(remaining)
  end

end

asteroid_list = hd(System.argv())
|> File.read!()
|> String.split(~r/\R/, trim: true)
|> Enum.map(&String.split(&1, "", trim: true))
|> Asteroids.to_list()

av = Enum.map(asteroid_list, fn asteroid_a ->
  vectors = Enum.reduce(asteroid_list, {MapSet.new(), []}, fn asteroid_b, acc ->
    {s, l} = acc
    unless asteroid_a == asteroid_b do
      uv = Asteroids.unit_vector(asteroid_a, asteroid_b)
      {MapSet.put(s, uv), [{asteroid_b, uv} | l]}
    else
      acc
    end
  end)
  {asteroid_a, vectors}
end)

count = Enum.map(av, fn asteroid_vector ->
  {asteroid, {vector_set, _vector_list}} = asteroid_vector
  {asteroid, MapSet.size(vector_set)}
end)

{best_station, visible} = Enum.max_by(count, fn x -> {_, count} = x; count end)

# part 1
IO.inspect(visible)

station_vectors = Enum.find(av, fn asteroid_vectors ->
  {asteroid, _} = asteroid_vectors
  asteroid == best_station
end)

{_, {_,station_vectors_list}} = station_vectors

sorted = Enum.sort_by(station_vectors_list, fn station_vector ->
  {b, _} = station_vector
  Asteroids.manhattan_dist(best_station, b)
end)
|> Enum.sort_by(fn station_vector ->
  {_, uv} = station_vector
  Asteroids.angle_from_up(uv)
end)

final = Asteroids.laser_cycle(sorted)

# part 2
IO.inspect(Enum.at(final, 199))
