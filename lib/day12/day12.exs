defmodule Moons do
  def simulate(bodies), do: simulate(bodies, 0)
  def simulate(bodies, count) do
    new_bodies = Enum.map bodies, fn moon ->
      {name, x, y, z, xv, yv, zv} = Enum.reduce bodies, moon, fn body, moon ->
        if body == moon do
          moon
        else
          {name, ax, ay, az, axv, ayv, azv} = moon
          {_, bx, by, bz, _, _, _} = body
          cxv = calc_v(ax, bx, axv)
          cyv = calc_v(ay, by, ayv)
          czv = calc_v(az, bz, azv)
          {name, ax, ay, az, cxv, cyv, czv}
        end
      end
      {name, x + xv, y + yv, z + zv, xv, yv, zv}
    end

    # part 1
    if count == 999 do
      IO.puts("PART 1")
      IO.inspect(calc_energy(new_bodies))
    else 
      simulate(new_bodies, count + 1)
    end
  end

  defp calc_v(a, b, v) do
    cond do
      a > b -> v - 1
      a < b -> v + 1
      true -> v
    end
  end

  defp calc_energy(bodies) do
    Enum.reduce bodies, 0, fn moon, acc ->
      {_, x, y, z, xv, yv, zv} = moon
      acc + ((abs(x) + abs(y) + abs(z)) * (abs(xv) + abs(yv) + abs(zv)))
    end
  end

  def gcd(a,0), do: abs(a)
  def gcd(a,b), do: gcd(b, rem(a,b))
  def lcm(a,b), do: div(abs(a*b), gcd(a,b))

  def simulate_dim(bodies), do: simulate_dim(bodies, bodies, 0)
  def simulate_dim(start, bodies, count) do
    new_bodies = Enum.map bodies, fn moon ->
      {name, x, xv} = Enum.reduce bodies, moon, fn body, moon ->
        if body == moon do
          moon
        else
          {name, ax, axv} = moon
          {_, bx, _} = body
          cxv = calc_v(ax, bx, axv)
          {name, ax, cxv}
        end
      end
      {name, x + xv, xv}
    end

    [{_,sx1,_},{_,sx2,_},{_,sx3,_},{_,sx4,_}] = start
    [{_,x1,v1},{_,x2,v2},{_,x3,v3},{_,x4,v4}] = new_bodies
    if x1 == sx1 and x2 == sx2 and x3 == sx3 and x4 == sx4 and v1 == 0 and v2 == 0 and v3 == 0 and v4 == 0 do
      count + 1
    else
      simulate_dim(start, new_bodies, count + 1)
    end
  end
end

i = {:i, -8, -10, 0, 0, 0, 0}
e = {:e, 5, 5, 10, 0, 0, 0}
g = {:g, 2, -7, 3, 0, 0, 0}
c = {:c, 9, -8, -3, 0, 0, 0}

Moons.simulate([i,e,g,c])

x_repeats = Moons.simulate_dim([{:i, -4, 0}, {:e, -11, 0}, {:g, 2, 0}, {:c, 7, 0}])
y_repeats = Moons.simulate_dim([{:i, 3, 0}, {:e, -10, 0}, {:g, 2, 0}, {:c, -1, 0}])
z_repeats = Moons.simulate_dim([{:i, 15, 0}, {:e, 13, 0}, {:g, 18, 0}, {:c, 0, 0}])

Moons.lcm(x_repeats, y_repeats) |> Moons.lcm(z_repeats) |> IO.puts
