input = 265275..781584

input
|> Enum.reduce([[],[]], fn i, acc ->
  [first, second, third, fourth, fifth, sixth] = Integer.digits(i)
  
  [p1, p2] = acc
  if first <= second
    and second <= third
    and third <= fourth
    and fourth <= fifth
    and fifth <= sixth do

    new_p1 = if (
      (first == second) or
      (second == third) or
      (third == fourth) or 
      (fourth == fifth) or
      (fifth == sixth)
    ) do
      [i | p1]
    else
      p1
    end

    new_p2 = if (
      (first == second and second != third) or
      (second == third and third != fourth and second != first) or
      (third == fourth and fourth != fifth and third != second) or
      (fourth == fifth and fifth != sixth and fourth != third) or
      (fifth == sixth and fifth != fourth)
    ) do
      [i | p2]
    else
      p2
    end

    [new_p1, new_p2]
  else
    acc
  end
end)
|> Enum.map(&length/1)
|> IO.inspect

