defmodule Nanofactory do
  def create({cn, ci}, stock, reactions) do
    {rn, r_ingredients} = reactions[ci]
    num_reactions = :math.ceil(cn / rn)
    
    stock = Enum.reduce(r_ingredients, stock, fn {n, i}, stock ->
      Map.put(stock, i, stock[i] - (n * num_reactions))
    end) 
    |> Map.put(ci, stock[ci] + (rn * num_reactions))

    Enum.reduce stock, stock, fn {i, n}, stock ->
      if n < 0 and i != "ORE" do
        create({abs(n), i}, stock, reactions)
      else
        stock
      end
    end
  end

  def extract_excess(stock, reactions) do
    new_stock = Enum.reduce stock, stock, fn {i, n}, stock ->
      if i != "FUEL" and i != "ORE" do
        {rn, r_ingredients} = reactions[i]
        if n >= rn do
          num_reactions = :math.floor(n / rn)
          stock = Enum.reduce r_ingredients, stock, fn {n, i}, stock ->
            Map.put(stock, i, stock[i] + (n * num_reactions))
          end
          Map.put(stock, i, stock[i] - (rn * num_reactions))
        else
          stock
        end
      else
        stock
      end
    end

    unless Map.equal?(stock, new_stock) do
      extract_excess(new_stock, reactions)
    else
      stock
    end
  end

  def parse_reactions(input) do
    Enum.map(input, fn formula ->
      [r, out] = formula
      {String.split(r, ",", trim: true) |> Enum.map(&String.split(&1, " ", trim: true)),
        String.split(out, " ", trim: true)}
    end)
    |> Enum.reduce({%{}, %{"ORE" => 0}}, fn formula, acc ->
      {r, out} = formula
      [out_n, out] = out
      r = Enum.map(r, fn reaction ->
        [n, ingredient] = reaction
        {String.to_integer(n), ingredient}
      end)
      {reactions, stock} = acc
      {Map.put(reactions, out, {String.to_integer(out_n), r}), Map.put(stock, out, 0)}
    end)
  end
end

{reactions, stock} = hd(System.argv())
|> File.read!()
|> String.split(~r/\R/, trim: true)
|> Enum.map(&String.split(&1, "=>", trim: true))
|> Nanofactory.parse_reactions()

# part 1
Nanofactory.create({1, "FUEL"}, stock, reactions)
|> Nanofactory.extract_excess(reactions)
|> Map.fetch!("ORE")
|> abs
|> IO.inspect

# part 2
# found the number using simple binary search style trial and error
# starting with 1000000000000 / part_1_answer
Nanofactory.create({2169535, "FUEL"}, stock, reactions)
|> Nanofactory.extract_excess(reactions)
|> Map.fetch!("ORE")
|> abs
|> IO.inspect

