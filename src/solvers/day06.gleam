import gleam/bool
import gleam/dict
import gleam/list
import gleam/result
import gleam/set.{type Set}
import gleam/string
import utils/grid.{type Direction, type Grid, type Point, E, Grid, N, S, W}

type Map {
  Obstacle
  Guard(Direction)
}

fn map_parser(g: String) -> Result(Map, Nil) {
  case g {
    "#" -> Ok(Obstacle)
    "^" -> Ok(Guard(N))
    "<" -> Ok(Guard(W))
    "v" -> Ok(Guard(S))
    ">" -> Ok(Guard(E))
    _ -> Error(Nil)
  }
}

fn patrol(
  map: Grid(Map),
  position: Point,
  direction: Direction,
  patrolled: Set(Point),
  seen: Set(#(Point, Direction)),
) -> Result(Set(Point), Nil) {
  use <- bool.guard(!grid.in_bounds(map, position), Ok(patrolled))
  use <- bool.guard(set.contains(seen, #(position, direction)), Error(Nil))
  let patrolled = patrolled |> set.insert(position)
  let seen = seen |> set.insert(#(position, direction))
  let next_position = grid.move(position, direction, 1)
  let #(position, direction) = case grid.get(map, next_position) {
    Ok(Obstacle) -> #(position, grid.rotate_right(direction))
    _ -> #(next_position, direction)
  }
  patrol(map, position, direction, patrolled, seen)
}

fn is_loop(
  new_obstacle: Point,
  map: Grid(Map),
  position: Point,
  direction: Direction,
) -> Bool {
  let assert Ok(map) = map |> grid.insert(new_obstacle, Obstacle)
  map
  |> patrol(position, direction, set.new(), set.new())
  |> result.is_error
}

pub fn solve(data: String) -> #(Int, Int) {
  let map = grid.from_string(data, string.to_graphemes, map_parser)
  let assert Ok(#(position, Guard(direction))) =
    map.points
    |> dict.to_list
    |> list.find(fn(p) { p.1 != Obstacle })
  let map = grid.filter(map, fn(_, item) { item == Obstacle })
  let assert Ok(patrolled) =
    map |> patrol(position, direction, set.new(), set.new())
  let loops =
    patrolled
    |> set.filter(is_loop(_, map, position, direction))
    |> set.size
  #(set.size(patrolled), loops)
}
