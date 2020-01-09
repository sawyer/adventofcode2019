defmodule Fuel do
  def fuel_for_mass(mass) when mass < 0, do: 0
  def fuel_for_mass(mass) do
    fuel = Integer.floor_div(mass, 3) - 2
    if fuel <= 0, do: 0, else: fuel + fuel_for_mass(fuel)
  end
end

"input.txt"
|> File.read!()
|> String.split(~r/\R/, trim: true)
|> Enum.map(&String.to_integer/1)
|> Enum.map(&Fuel.fuel_for_mass/1)
|> Enum.sum()
|> IO.puts()
