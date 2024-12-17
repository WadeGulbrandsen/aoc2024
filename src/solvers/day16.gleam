import gleam/bool
import gleam/dict.{type Dict}
import gleam/function
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/set.{type Set}
import gleam/string
import gleamy/priority_queue.{type Queue} as pq
import glitzer/codes
import utils/grid.{type Direction, type Grid, type Point, E, Grid, N, S, W}
import utils/helper

// it takes ~375k iterations of to find the paths so adjust frame skip as needed
const frame_skip = 500

type Map {
  Wall
  Start
  End
  Seat
  Arrow(String)
}

type Step {
  Step(dir: Direction, point: Point)
}

type Path {
  Path(to_goal: Int, cost: Int, head: Step, tail: List(Step))
}

fn char_to_map(char: String) -> Result(Map, Nil) {
  case char {
    "#" -> Ok(Wall)
    "S" -> Ok(Start)
    "E" -> Ok(End)
    _ -> Error(Nil)
  }
}

fn parse(data: String) -> #(Grid(Map), Point, Point) {
  let map = grid.from_string(data, string.to_graphemes, char_to_map)
  let assert #(Ok(start), Ok(end)) =
    dict.fold(map.points, #(Error(Nil), Error(Nil)), fn(se, p, m) {
      case m {
        Start -> #(Ok(p), se.1)
        End -> #(se.0, Ok(p))
        _ -> se
      }
    })
  #(map, start, end)
}

fn greater_than_best(g: Int, best: Option(Int)) -> Bool {
  case best {
    Some(x) -> g > x
    None -> False
  }
}

fn all_best_paths(
  map: Grid(Map),
  queue: Queue(Path),
  goal: Point,
  seen: Dict(Step, Int),
  best: Option(Int),
  acc: List(Path),
  count: Int,
  visualize: Bool,
) -> List(Path) {
  use <- bool.guard(pq.is_empty(queue), acc)
  let assert Ok(#(q, queue)) = pq.pop(queue)
  let #(found, next) = {
    use <- bool.guard(greater_than_best(q.cost, best), #([], []))
    print_map(map, q, set.new(), count, visualize)
    get_next(q)
    |> list.filter_map(fn(cost_step) {
      let #(cost, step) = cost_step
      let g = cost + q.cost
      use <- bool.guard(
        grid.get(map, step.point) == Ok(Wall) || greater_than_best(g, best),
        Error(Nil),
      )
      let h = grid.manhatten_distance(step.point, goal)
      case dict.get(seen, step) {
        Ok(x) if x < h + g -> Error(Nil)
        _ -> Ok(Path(h, g, step, [q.head, ..q.tail]))
      }
    })
    |> list.partition(fn(path) { path.head.point == goal })
  }

  let #(best, acc) = {
    use <- bool.guard(list.is_empty(found), #(best, acc))
    let acc = found |> list.append(acc)
    let assert Ok(low) =
      acc |> list.map(fn(path) { path.cost }) |> list.reduce(int.min)
    let best = Some(low)
    let acc =
      acc |> list.filter(fn(path) { !greater_than_best(path.cost, best) })
    #(best, acc)
  }

  let queue = next |> list.fold(queue, fn(queue, path) { pq.push(queue, path) })
  all_best_paths(
    map,
    queue,
    goal,
    dict.insert(seen, q.head, q.cost + q.to_goal),
    best,
    acc,
    count + 1,
    visualize,
  )
}

fn get_next(q: Path) -> List(#(Int, Step)) {
  [
    #(1, function.identity),
    #(1001, grid.rotate_left),
    #(1001, grid.rotate_right),
    #(2001, grid.reverse_direction),
  ]
  |> list.map(fn(cost_fun) {
    let #(cost, fun) = cost_fun
    let dir = fun(q.head.dir)
    let point = grid.move(q.head.point, dir, 1)
    #(cost, Step(dir, point))
  })
}

fn path_compare(a: Path, b: Path) -> order.Order {
  int.compare(a.cost + a.to_goal, b.cost + b.to_goal)
}

fn add_path(map: Grid(Map), path: Path) -> Grid(Map) {
  let points =
    [path.head, ..path.tail]
    |> list.map(fn(step) {
      let arrow = case step.dir {
        N -> "^"
        S -> "v"
        E -> ">"
        W -> "<"
        _ -> " "
      }
      #(step.point, Arrow(arrow))
    })
    |> dict.from_list
    |> dict.merge(map.points)
  Grid(..map, points: points)
}

fn add_seats(map: Grid(Map), seats: Set(Point)) -> Grid(Map) {
  let points =
    seats
    |> set.fold(dict.new(), fn(points, point) {
      dict.insert(points, point, Seat)
    })
    |> dict.merge(map.points)
  Grid(..map, points: points)
}

fn map_to_char(m: Result(Map, Nil)) -> String {
  case m {
    Ok(Wall) -> "#" |> helper.unnamed_blue
    Ok(Start) -> "S" |> helper.white
    Ok(End) -> "E" |> helper.white
    Ok(Seat) -> "O" |> helper.aged_plastic_yellow
    Ok(Arrow(c)) -> c |> helper.faff_pink
    _ -> " "
  }
}

fn print_map(
  map: Grid(Map),
  path: Path,
  seats: Set(Point),
  frame: Int,
  visualize: Bool,
) {
  use <- bool.guard(!visualize || frame % frame_skip != 0, Nil)
  let grid =
    map
    |> add_path(path)
    |> add_seats(seats)
    |> grid.to_string(map_to_char)
    |> helper.bg_underwater_blue
  io.print_error(codes.return_home_code <> grid)
}

pub fn solve(data: String, visualization: helper.Visualize) -> #(Int, Int) {
  let visualization = visualization != helper.None
  case visualization {
    True -> io.print_error(codes.hide_cursor_code <> codes.clear_screen_code)
    False -> Nil
  }
  let #(map, start, end) = parse(data)

  let initial_path =
    Path(grid.manhatten_distance(start, end), 0, Step(E, start), [])

  print_map(map, initial_path, set.new(), 0, visualization)

  let queue = pq.new(path_compare) |> pq.push(initial_path)

  let best_paths =
    all_best_paths(map, queue, end, dict.new(), None, [], 0, visualization)

  let assert Ok(best_path) = best_paths |> list.first

  print_map(map, best_path, set.new(), 0, visualization)

  let seats =
    best_paths
    |> list.fold(set.new(), fn(s, path) {
      [path.head, ..path.tail]
      |> list.map(fn(step) { step.point })
      |> set.from_list
      |> set.union(s)
    })

  print_map(map, best_path, seats, 0, visualization)

  case visualization {
    True -> io.println_error(codes.show_cursor_code)
    False -> Nil
  }

  #(best_path.cost, seats |> set.size)
}
