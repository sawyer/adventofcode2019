defmodule Aoc2019.Day22 do
  @moduledoc """
  # Part 1

  Each shuffle type can be represented as a linear transformation that takes 
  the initial position and returns the new position (x).
  """

  @doc """
  ## Solve P1
  iex> Aoc2019.Day22.p1
  """
  def p1 do
    deck_size = 10007
    functions = input_to_functions("./lib/day22/input.txt", deck_size)

    composition = compose_functions(functions, deck_size)

    shuffle(composition, 2019, deck_size)
  end

  @doc """
  ## Solve P2
  iex> Aoc2019.Day22.p2
  """
  def p2 do
    deck_size = 119315717514047
    num_shuffles = 101741582076661
    functions = input_to_functions("./lib/day22/input.txt", deck_size)

    inverted_composition = compose_inverse(functions, deck_size)
                           |> shuffle_many_times(num_shuffles, deck_size)

    shuffle(inverted_composition, 2020, deck_size)
  end

  def input_to_functions(fp, ds) do
    Stream.map(Aoc2019.input_lines(fp), &fx(&1, ds))
  end

  @doc """
  ## Deal into new stack
  new_position = -1 * x + (deck_size - 1)
  new_position = -(4) + 10 - 1 = 5

  ## Cut
  new_position = 1 * x + (-1 * cut_position)
  new_position = 2 - 3 = -1 (needs to be normalized) -> 10 - rem(-(-1), 10) = 9

  ## Deal with increment
  new_position = increment * x + 0
  new_position = 3 * 5 = 15 -> rem(15, 10) = 5
  new_position = 3 * 9 = 27 -> rem(27, 10) = 7
  """
  def fx("deal into new stack", ds), do: {-1, ds - 1}
  def fx("cut " <> b, _ds), do: {1, -String.to_integer(b)}
  def fx("deal with increment " <> a, _ds), do: {String.to_integer(a), 0}

  def compose_functions(functions, deck_size) do
    Enum.reduce(functions, &compose(&1, &2, deck_size))
  end

  @doc """
  ## Normalize positive
  new_position = rem(position, deck_size)

  ## Normalize negative
  new_position = deck_size - rem(-position, deck_size)
  """
  def normalize(p, ds) when p < 0, do: ds - rem(-p, ds)
  def normalize(p, ds), do: rem(p, ds)
  
  @doc """
  ## Linear transformations
  Transformations can be composed: given two functions
  f()=a*x+b and g()=c*x+d, composition g(f(x)) is c*a*x + c*b + d
  """
  def compose({gc, gd}, {fa, fb}, ds) do
    {normalize(gc * fa, ds), normalize(gc * fb + gd, ds)}
  end

  def shuffle({a, b}, x, ds), do: normalize(a * x + b, ds)

  @doc """
  Normalize as we do the division to avoid operating on huge numbers
  """
  def normalized_div(a, b, deck_size) do
    a
    |> Stream.iterate(&(&1 + deck_size))
    |> Enum.find(&(rem(&1, b) == 0))
    |> div(b)
    |> normalize(deck_size)
  end

  @doc """
  The inverted version of our linear functions: f(x) = 1/a - b/a
  """
  def inverse({a, b}, deck_size) do
    {normalized_div(1, a, deck_size), normalized_div(-b, a, deck_size)}
  end

  def compose_inverse(functions, deck_size) do
    functions
    |> Stream.map(&inverse(&1, deck_size))
    |> Enum.reduce(&compose(&2, &1, deck_size))
  end

  @doc """
  Use exponentiation by squaring to create a function which shuffles n times
  """
  def shuffle_many_times(fx, n, deck_size) do
    binary_digits = n
                    |> Integer.to_string(2)
                    |> to_charlist()
                    |> Stream.map(&(&1 - ?0))

    functions = Stream.iterate(fx, &compose(&1, &1, deck_size))

    binary_digits
    |> Enum.reverse()
    |> Stream.zip(functions)
    |> Stream.reject(fn {digit, _fx} -> digit == 0 end)
    |> Stream.map(fn {_digit, fx} -> fx end)
    |> Enum.reduce(&compose(&1, &2, deck_size))
  end

end
