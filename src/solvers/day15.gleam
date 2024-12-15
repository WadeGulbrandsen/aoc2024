import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/string
import utils/grid.{type Direction, type Grid, type Point, E, Grid, N, S, W}
import utils/helper

const debug = False

type Warehouse {
  Wall
  Box
  BoxL
  BoxR
  Robot
}

fn is_box(m: Warehouse) -> Bool {
  case m {
    Box | BoxL -> True
    _ -> False
  }
}

fn expand(map: Grid(Warehouse)) -> Grid(Warehouse) {
  map
  |> grid.to_string(fn(r) {
    case r {
      Ok(Wall) -> "##"
      Ok(Box) -> "[]"
      Ok(Robot) -> "@."
      _ -> ".."
    }
  })
  |> grid.from_string(string.to_graphemes, fn(char) {
    case char {
      "#" -> Ok(Wall)
      "[" -> Ok(BoxL)
      "]" -> Ok(BoxR)
      "@" -> Ok(Robot)
      _ -> Error(Nil)
    }
  })
}

fn parse(data: String) -> #(Grid(Warehouse), List(Direction)) {
  let assert Ok(#(map, moves)) = string.split_once(data, "\n\n")
  let map =
    grid.from_string(map, string.to_graphemes, fn(char) {
      case char {
        "#" -> Ok(Wall)
        "O" -> Ok(Box)
        "[" -> Ok(BoxL)
        "]" -> Ok(BoxR)
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

fn map_to_char(m: Result(Warehouse, Nil)) -> String {
  case m {
    Ok(Wall) -> helper.unnamed_blue("#")
    Ok(Box) -> helper.faff_pink("O")
    Ok(BoxL) -> helper.faff_pink("[")
    Ok(BoxR) -> helper.faff_pink("]")
    Ok(Robot) -> helper.aged_plastic_yellow("@")
    Error(_) -> "."
  }
}

fn map_debug(m: Grid(Warehouse)) -> Grid(Warehouse) {
  case debug {
    True -> {
      io.println_error("\n" <> grid.to_string(m, map_to_char))
      m
    }
    False -> m
  }
  m
}

fn move_robot(
  state: #(Grid(Warehouse), Point),
  dir: Direction,
) -> #(Grid(Warehouse), Point) {
  push(state.0, [#(state.1, Robot)], state.1, dir)
}

fn push(
  map: Grid(Warehouse),
  stack: List(#(Point, Warehouse)),
  robot: Point,
  dir: Direction,
) -> #(Grid(Warehouse), Point) {
  let assert Ok(#(current, _)) = list.first(stack)
  let next = grid.move(current, dir, 1)
  case grid.get(map, next) {
    Error(_) -> {
      let new_robot = grid.move(robot, dir, 1)
      #(move_stack(map, stack, dir), new_robot)
    }
    Ok(Wall) -> #(map, robot)
    Ok(item) -> push(map, [#(next, item), ..stack], robot, dir)
  }
}

fn push_verticle(
  map: Grid(Warehouse),
  stack: List(Dict(Point, Warehouse)),
  robot: Point,
  dir: Direction,
) -> #(Grid(Warehouse), Point) {
  let assert Ok(current) = list.first(stack)
  let next =
    current
    |> dict.fold(dict.new(), fn(next, point, _item) {
      let next_point = grid.move(point, dir, 1)
      case grid.get(map, next_point) {
        Ok(item) -> next |> dict.insert(next_point, item)
        Error(_) -> next
      }
    })

  use <- bool.lazy_guard(dict.is_empty(next), fn() {
    let moved = move_stack(map, list.flat_map(stack, dict.to_list), dir)
    #(moved, grid.move(robot, dir, 1))
  })
  use <- bool.guard(list.any(dict.values(next), fn(i) { i == Wall }), {
    #(map, robot)
  })
  let next =
    next
    |> dict.fold(next, fn(boxes, point, item) {
      case item {
        BoxL -> boxes |> dict.insert(grid.move(point, E, 1), BoxR)
        BoxR -> boxes |> dict.insert(grid.move(point, W, 1), BoxL)
        _ -> boxes
      }
    })
  push_verticle(map, [next, ..stack], robot, dir)
}

fn move_stack(
  map: Grid(Warehouse),
  stack: List(#(Point, Warehouse)),
  dir: Direction,
) -> Grid(Warehouse) {
  use map, #(current, item) <- list.fold(stack, map)
  let next = grid.move(current, dir, 1)
  let next_points =
    map.points |> dict.delete(current) |> dict.insert(next, item)
  Grid(..map, points: next_points)
}

fn wide_move_robot(
  state: #(Grid(Warehouse), Point),
  dir: Direction,
) -> #(Grid(Warehouse), Point) {
  case dir {
    E | W -> push(state.0, [#(state.1, Robot)], state.1, dir)
    _ ->
      push_verticle(
        state.0,
        [dict.from_list([#(state.1, Robot)])],
        state.1,
        dir,
      )
  }
}

fn robot_position(map: Grid(Warehouse)) -> Point {
  let assert [robot] =
    dict.filter(map.points, fn(_, m) { m == Robot }) |> dict.keys
  robot
}

fn gps(p: Point) -> Int {
  100 * p.y + p.x
}

pub fn solve(data: String) -> #(Int, Int) {
  let #(map, moves) = parse(data)
  let part1 =
    moves
    |> list.fold(#(map |> map_debug, robot_position(map)), move_robot)
    |> pair.first
    |> map_debug
    |> grid.filter(fn(_, m) { m |> is_box })
    |> grid.points
    |> list.map(gps)
    |> int.sum
  let wide_map = expand(map) |> map_debug
  let part2 =
    moves
    |> list.fold(#(wide_map, robot_position(wide_map)), wide_move_robot)
    |> pair.first
    |> map_debug
    |> grid.filter(fn(_, m) { m |> is_box })
    |> grid.points
    |> list.map(gps)
    |> int.sum

  #(part1, part2)
}
