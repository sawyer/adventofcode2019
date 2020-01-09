"input.txt"
|> File.read!()
|> String.split(~r/\R/, trim: true)
|> Enum.map(fn str_mass -> String.to_integer(str_mass) end)
|> Enum.map(fn mass -> Integer.floor_div(mass, 3) - 2 end)
|> Enum.sum()
|> IO.puts()
