import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import utils/grid.{type Direction, type Grid, type Point, E, N, S, W}
import utils/helper

const debug = False

type Map {
  Wall
  Box
  Robot
}

fn parse(data: String) -> #(Grid(Map), List(Direction)) {
  let assert Ok(#(map, moves)) = string.split_once(data, "\n\n")
  let map =
    grid.from_string(map, string.to_graphemes, fn(char) {
      case char {
        "#" -> Ok(Wall)
        "O" -> Ok(Box)
        "@" -> Ok(Robot)
        _ -> Error(Nil)
      }
    })
  let moves =
    moves
    |> string.to_graphemes
    |> list.filter_map(fn(char) {
      case char {
        "^" -> Ok(N)
        ">" -> Ok(E)
        "v" -> Ok(S)
        "<" -> Ok(W)
        _ -> Error(Nil)
      }
    })
  #(map, moves)
}

fn map_to_char(m: Result(Map, Nil)) -> String {
  case m {
    Ok(Wall) -> helper.unnamed_blue("#")
    Ok(Box) -> helper.faff_pink("O")
    Ok(Robot) -> helper.aged_plastic_yellow("@")
    Error(_) -> "."
  }
}

fn map_debug(m: Grid(Map)) -> Grid(Map) {
  case debug {
    True -> {
      io.println_error("\n" <> grid.to_string(m, map_to_char))
      m
    }
    False -> m
  }
}

fn move_robot(state: #(Grid(Map), Point), dir: Direction) -> #(Grid(Map), Point) {
  push(state.0 |> map_debug, state.1, state.1, dir)
}

fn push(
  map: Grid(Map),
  robot: Point,
  current: Point,
  dir: Direction,
) -> #(Grid(Map), Point) {
  let next = grid.move(current, dir, 1)
  case grid.get(map, next) {
    Error(_) -> {
      let new_robot = grid.move(robot, dir, 1)
      let new_map = case robot == current {
        True -> map
        False -> map |> grid.insert(next, Box) |> result.unwrap(map)
      }
      #(
        new_map
          |> grid.remove(robot)
          |> grid.insert(new_robot, Robot)
          |> result.unwrap(map),
        new_robot,
      )
    }
    Ok(Wall) -> #(map, robot)
    Ok(_) -> push(map, robot, next, dir)
  }
}

fn robot_position(map: Grid(Map)) -> Point {
  let assert [robot] =
    dict.filter(map.points, fn(_, m) { m == Robot }) |> dict.keys
  robot
}

fn gps(p: Point) -> Int {
  100 * p.y + p.x
}

pub fn solve(data: String) -> #(Int, Int) {
  let #(map, moves) = parse(data)
  let robot = robot_position(map)
  let part1 =
    moves
    |> list.fold(#(map, robot), move_robot)
    |> pair.first
    |> grid.filter(fn(_, m) { m == Box })
    |> map_debug
    |> grid.points
    |> list.map(gps)
    |> int.sum

  #(part1, 0)
}
