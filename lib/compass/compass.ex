defmodule Aoc2019.Compass do
  def dirs do
    ["N", "S", "E", "W"]
  end

  def pos_in_dir({pos_x, pos_y}, dir) do
    case dir do
      "N" -> {pos_x, pos_y - 1}
      "S" -> {pos_x, pos_y + 1}
      "E" -> {pos_x + 1, pos_y}
      "W" -> {pos_x - 1, pos_y}
    end
  end

end
