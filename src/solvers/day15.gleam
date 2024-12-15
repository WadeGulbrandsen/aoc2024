import gleam/bool
import gleam/dict.{type Dict}
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/string
import glitzer/codes
import utils/grid.{type Direction, type Grid, type Point, E, Grid, N, S, W}
import utils/helper

const debug = False

const frame_skip = 5

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

fn dir_to_char(dir: Direction) -> String {
  case dir {
    N -> "^"
    E -> ">"
    S -> "v"
    W -> "<"
    _ -> " "
  }
}

fn print_move(m: Grid(Warehouse), dir: Direction, move: Int, move_count: Int) {
  use <- bool.guard({ move + 1 } % frame_skip != 0, Nil)
  let direction_string = "Moving: " <> dir_to_char(dir)
  let count_string = helper.int_to_string_with_commas(move_count)
  let move_string =
    move + 1
    |> helper.int_to_string_with_commas
    |> string.pad_start(count_string |> string.length, " ")
  let move_status = "Move: " <> move_string <> "\n  Of: " <> count_string
  io.println_error(
    codes.return_home_code
    <> direction_string |> helper.faff_pink
    <> "\n"
    <> move_status |> helper.aged_plastic_yellow
    <> "\n"
    <> grid.to_string(m, map_to_char) |> helper.bg_underwater_blue,
  )
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

fn push_horizontal(
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
    Ok(item) -> push_horizontal(map, [#(next, item), ..stack], robot, dir)
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

fn move_robot(
  state: #(Grid(Warehouse), Point),
  dir: Direction,
  move: Int,
  move_count: Int,
  visualize: Bool,
) -> #(Grid(Warehouse), Point) {
  let state = case dir {
    E | W -> push_horizontal(state.0, [#(state.1, Robot)], state.1, dir)
    _ ->
      push_verticle(
        state.0,
        [dict.from_list([#(state.1, Robot)])],
        state.1,
        dir,
      )
  }
  use <- bool.guard(!visualize, state)
  print_move(state.0, dir, move, move_count)
  state
}

fn robot_position(map: Grid(Warehouse)) -> Point {
  let assert [robot] =
    dict.filter(map.points, fn(_, m) { m == Robot }) |> dict.keys
  robot
}

fn gps(p: Point) -> Int {
  100 * p.y + p.x
}

pub fn solve(data: String, visualize: Bool) -> #(Int, Int) {
  let #(map, moves) = parse(data)
  let move_count = list.length(moves)

  case visualize {
    True -> io.print_error(codes.hide_cursor_code <> codes.clear_screen_code)
    False -> Nil
  }

  let part1 =
    moves
    |> list.index_fold(
      #(map |> map_debug, robot_position(map)),
      fn(state, direction, index) {
        move_robot(state, direction, index, move_count, visualize)
      },
    )
    |> pair.first
    |> map_debug
    |> grid.filter(fn(_, m) { m |> is_box })
    |> grid.points
    |> list.map(gps)
    |> int.sum

  case visualize {
    True -> {
      io.print_error(
        "\nPart 1 complete: " <> helper.int_to_string_with_commas(part1),
      )
      process.sleep(1000)
      io.print_error(codes.clear_screen_code)
    }
    False -> Nil
  }

  let wide_map = expand(map) |> map_debug
  let part2 =
    moves
    |> list.index_fold(
      #(wide_map, robot_position(wide_map)),
      fn(state, direction, index) {
        move_robot(state, direction, index, move_count, visualize)
      },
    )
    |> pair.first
    |> map_debug
    |> grid.filter(fn(_, m) { m |> is_box })
    |> grid.points
    |> list.map(gps)
    |> int.sum

  case visualize {
    True -> io.print_error(codes.show_cursor_code)
    False -> Nil
  }

  #(part1, part2)
}
