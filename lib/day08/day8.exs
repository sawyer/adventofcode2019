image = hd(System.argv())
          |> File.read!()
          |> String.replace(~r/\r|\n/, "")
          |> String.split("", trim: true)
          |> Enum.map(&String.to_integer/1)
          |> Enum.chunk_every(25)
          |> Enum.chunk_every(6)

# part 1
Enum.reduce(image, %{0 => 99999, 1 => 0, 2 => 0}, fn layer, acc ->
  layer = Enum.reduce(layer, %{0 => 0, 1 => 0, 2 => 0}, fn row, acc ->
    row = Enum.reduce(row, %{0 => 0, 1 => 0, 2 => 0}, fn cell, acc ->
      case cell do
        0 -> %{0 => acc[0] + 1, 1 => acc[1], 2 => acc[2]}
        1 -> %{0 => acc[0], 1 => acc[1] + 1, 2 => acc[2]}
        2 -> %{0 => acc[0], 1 => acc[1], 2 => acc[2] + 1}
      end
    end)
    %{0 => acc[0] + row[0], 1 => acc[1] + row[1], 2 => acc[2] + row[2]}
  end)

  if layer[0] < acc[0] do
    layer
  else
    acc
  end
end)
|> IO.inspect

# part 2
final_image = Enum.reduce(tl(image), hd(image), fn layer, base ->
  new_layer = Enum.reduce(Enum.zip(base, layer), [], fn row, acc ->
    {base_row, layer_row} = row
    new_row = Enum.reduce(Enum.zip(base_row, layer_row), [], fn cell, acc ->
      {a_cell, b_cell} = cell
      [(if a_cell == 2 and b_cell != 2, do: b_cell, else: a_cell) | acc]
    end)
    |> Enum.reverse()

    [new_row | acc]
  end)
  |> Enum.reverse

  new_layer
end)

for row <- final_image do
  IO.inspect(row)
end

