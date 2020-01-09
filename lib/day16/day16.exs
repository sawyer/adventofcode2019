defmodule FFT do
  def phase(input, count) do
    {out, _} = Enum.map_reduce(input, 1, fn _, i ->

      modifier = List.duplicate(0, i) ++ List.duplicate(1, i) ++ List.duplicate(0, i) ++ List.duplicate(-1, i)
      modifier = if length(modifier) < length(input) do
        tl(List.flatten(List.duplicate(modifier, trunc(:math.ceil(length(input) / length(modifier))))))
      else
        tl(modifier)
      end

      out = Enum.zip(input, modifier)
      |> Enum.map(fn {a, b} -> a * b end)
      |> Enum.sum
      |> abs
      |> rem(10)
      
      {out, i + 1}
    end)

    if count + 1 == 100 do
      out
    else
      phase(out, count + 1)
    end
  end

  @moduledoc """
  The process used in phase 1 does not scale to an input of 6.5M numbers.
  Because of the offset pushing the target we're looking for into the
  later half of the input / output we can drop the offset and only calculate
  a "cumulative sum" on the reversed input set. Apparently this is something
  like a Fast Fourier Transform because most of the matrix transforms that
  are applied end up being *0 (and therefore 0).
  """
  def phase_2(input, count) do
    {out, _} = Enum.map_reduce(input, 0, fn n, last_out ->
      out = n + last_out
      |> rem(10)
      {out, out}
    end)
      
    if count + 1 == 100 do
      out
    else
      phase_2(out, count + 1)
    end
  end
end

input = hd(System.argv())
|> File.read!()
|> String.replace(~r/\r|\n/, "")
|> String.split("", trim: true)
|> Enum.map(&String.to_integer(&1))

# part 1
#FFT.phase(input, 0) |> IO.inspect

# part 2
long_input = List.flatten(List.duplicate(input, 10000))
offset = Enum.take(input, 7)
         |> Enum.reduce("", fn n, acc -> acc <> Integer.to_string(n) end)
         |> String.to_integer
offset_input = Enum.drop(long_input, offset)
out = FFT.phase_2(Enum.reverse(offset_input), 0)
IO.inspect(Enum.take(Enum.reverse(out), 8))

