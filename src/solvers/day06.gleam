import gleam/bool
import gleam/dict
import gleam/list
import gleam/result
import gleam/set.{type Set}
import gleam/string
import utils/grid.{type Direction, type Grid, type Point, E, Grid, N, S, W}
import utils/helper

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

fn parse(data: String) -> #(Grid(Map), Point, Direction) {
  let map = grid.from_string(data, string.to_graphemes, map_parser)
  let assert Ok(#(position, Guard(direction))) =
    map.points
    |> dict.to_list
    |> list.find(fn(p) { p.1 != Obstacle })
  let map = grid.filter(map, fn(_, item) { item == Obstacle })
  #(map, position, direction)
}

pub fn solve(data: String, visualize: Bool) -> #(Int, Int) {
  let day_string = "Day 6: " |> helper.unnamed_blue
  let parsing_string = day_string <> "Parsing data " |> helper.faff_pink
  let p1_string =
    day_string
    <> "Part 1: " |> helper.aged_plastic_yellow
    <> "Patrolling " |> helper.faff_pink
  let p2_string =
    day_string
    <> "Part 2: " |> helper.aged_plastic_yellow
    <> "Loops " |> helper.faff_pink

  let #(map, position, direction) =
    helper.spin_it(parsing_string, parsing_string <> "✔️", visualize, fn() {
      parse(data)
    })

  let assert Ok(patrolled) =
    helper.spin_it(p1_string, p1_string <> "✔️", visualize, fn() {
      map |> patrol(position, direction, set.new(), set.new())
    })

  let loops =
    helper.spin_it(p2_string, p2_string <> "✔️", visualize, fn() {
      patrolled
      |> set.to_list
      |> helper.parallel_filter(is_loop(_, map, position, direction))
      |> list.length
    })
  #(set.size(patrolled), loops)
}
