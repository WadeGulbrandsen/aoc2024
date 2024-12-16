import gleam/dict
import gleam/list
import gleam/pair
import gleam/set.{type Set}
import gleam/string
import utils/grid.{type Grid, type Point}
import utils/helper

fn grid_parser(grapheme: String) -> Result(String, Nil) {
  case grapheme {
    "." -> Error(Nil)
    _ -> Ok(grapheme)
  }
}

fn get_antinodes(antinodes: Set(Point), points: #(Point, Point)) -> Set(Point) {
  let difference = grid.subtract_points(points.0, points.1)
  antinodes
  |> set.insert(grid.add_points(points.0, difference))
  |> set.insert(grid.subtract_points(points.1, difference))
}

fn get_resonant(
  antinodes: Set(Point),
  points: #(Point, Point),
  grid: Grid(String),
) -> Set(Point) {
  let difference = grid.subtract_points(points.0, points.1)
  antinodes
  |> repeat_until_out_of_bounds(points.0, difference, grid.add_points, grid)
  |> repeat_until_out_of_bounds(
    points.1,
    difference,
    grid.subtract_points,
    grid,
  )
}

fn repeat_until_out_of_bounds(
  acc: Set(Point),
  point: Point,
  difference: Point,
  fun: fn(Point, Point) -> Point,
  grid: Grid(String),
) -> Set(Point) {
  case grid.in_bounds(grid, point) {
    False -> acc
    True ->
      repeat_until_out_of_bounds(
        set.insert(acc, point),
        fun(point, difference),
        difference,
        fun,
        grid,
      )
  }
}

fn part2(grid: Grid(String)) -> Int {
  grid.points
  |> dict.to_list
  |> list.group(pair.second)
  |> dict.fold(set.new(), fn(s, _, v) {
    list.map(v, pair.first)
    |> list.combination_pairs
    |> list.fold(s, fn(a, p) { get_resonant(a, p, grid) })
  })
  |> set.size
}

fn part1(grid: Grid(String)) -> Int {
  grid.points
  |> dict.to_list
  |> list.group(pair.second)
  |> dict.fold(set.new(), fn(s, _, v) {
    list.map(v, pair.first)
    |> list.combination_pairs
    |> list.fold(s, get_antinodes)
  })
  |> set.filter(grid.in_bounds(grid, _))
  |> set.size
}

pub fn solve(data: String, _visualize: helper.Visualize) -> #(Int, Int) {
  let grid = grid.from_string(data, string.to_graphemes, grid_parser)
  #(part1(grid), part2(grid))
}
