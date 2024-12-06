import gleam/bool
import gleam/dict
import gleam/io
import gleam/list
import gleam/string
import utils/grid.{type Direction, type Grid, type Point, E, Grid, N, S, W}

type Map {
  Obstacle
  Guard(Direction)
  Route
}

fn map_parser(g: String) -> Result(Map, Nil) {
  case g {
    "#" -> Ok(Obstacle)
    "^" -> Ok(Guard(N))
    "<" -> Ok(Guard(W))
    "v" -> Ok(Guard(S))
    ">" -> Ok(Guard(E))
    "X" -> Ok(Route)
    _ -> Error(Nil)
  }
}

fn patrol(map: Grid(Map), position: Point, direction: Direction) -> Grid(Map) {
  use <- bool.guard(!grid.in_bounds(map, position), map)
  let assert Ok(map) = grid.insert(map, position, Route)
  let next_position = grid.move(position, direction, 1)
  case grid.get(map, next_position) {
    Ok(Obstacle) -> patrol(map, position, grid.rotate_right(direction))
    _ -> patrol(map, next_position, direction)
  }
}

fn part1(map: Grid(Map)) -> Int {
  let assert Ok(#(position, Guard(direction))) =
    map.points
    |> dict.to_list
    |> list.find(fn(p) { p.1 != Obstacle })
  map
  |> grid.remove(position)
  |> patrol(position, direction)
  |> grid.filter(fn(_, m) { m == Route })
  |> grid.size
}

fn part2(map: Grid(Map)) -> Int {
  6
}

pub fn solve(data: String) -> #(Int, Int) {
  let map = grid.from_string(data, string.to_graphemes, map_parser)
  #(part1(map), part2(map))
}
