import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/result
import gleam/string
import gleamy/priority_queue.{type Queue} as pq
import glitzer/codes
import utils/grid.{
  type Direction, type Grid, type Point, E, Grid, N, Point, S, W,
}
import utils/helper

const frame_skip = 1000

type Map {
  Wall
  Start
  End
  Arrow(String)
}

type Step {
  Step(dir: Direction, point: Point)
}

type Path {
  Path(to_goal: Int, cost: Int, head: Step, tail: List(Step))
}

fn map_to_char(m: Result(Map, Nil)) -> String {
  case m {
    Ok(Wall) -> "#" |> helper.unnamed_blue
    Ok(Start) -> "S" |> helper.white
    Ok(End) -> "E" |> helper.white
    Ok(Arrow(c)) -> c |> helper.faff_pink
    _ -> "." |> helper.aged_plastic_yellow
  }
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

fn print_map(map: Grid(Map), path: Path, frame: Int, visualize: Bool) {
  use <- bool.guard(!visualize || frame % frame_skip != 0, Nil)
  let grid =
    map
    |> add_path(path)
    |> grid.to_string(map_to_char)
    |> helper.bg_underwater_blue
  io.print_error(codes.return_home_code <> grid)
}

pub fn test_solve(data: String, visualization: helper.Visualize) -> #(Int, Int) {
  do_solve(data, 6, 6, 12, visualization)
}

pub fn solve(data: String, visualization: helper.Visualize) -> #(Int, Int) {
  do_solve(data, 70, 70, 1024, visualization)
}

fn a_star(
  map: Grid(Map),
  queue: Queue(Path),
  goal: Point,
  seen: Dict(Step, Int),
  frame: Int,
  visualize: Bool,
) -> Result(Path, Nil) {
  use <- bool.guard(pq.is_empty(queue), Error(Nil))
  let assert Ok(#(q, queue)) = pq.pop(queue)
  print_map(map, q, frame, visualize)
  let next =
    get_next(q.head.point, map)
    |> list.filter_map(fn(cost_step) {
      let #(cost, step) = cost_step
      let g = cost + q.cost
      let h = grid.manhatten_distance(step.point, goal)
      case dict.get(seen, step) {
        Ok(x) if x <= g -> Error(Nil)
        _ -> Ok(Path(h, g, step, [q.head, ..q.tail]))
      }
    })
  let found = list.find(next, fn(path) { path.head.point == goal })
  use <- bool.lazy_guard(result.is_ok(found), fn() {
    print_map(map, q, 0, visualize)
    found
  })
  let queue = next |> list.fold(queue, fn(queue, path) { pq.push(queue, path) })
  a_star(
    map,
    queue,
    goal,
    dict.insert(seen, q.head, q.cost),
    frame + 1,
    visualize,
  )
}

fn get_next(point: Point, map: Grid(Map)) -> List(#(Int, Step)) {
  [N, E, S, W]
  |> list.filter_map(fn(dir) {
    let point = grid.move(point, dir, 1)
    case grid.in_bounds(map, point) && grid.get(map, point) != Ok(Wall) {
      True -> Ok(#(1, Step(dir, point)))
      False -> Error(Nil)
    }
  })
}

fn path_compare(a: Path, b: Path) -> order.Order {
  int.compare(a.cost + a.to_goal, b.cost + b.to_goal)
}

fn find_shortest_path(
  map: Grid(Map),
  start: Point,
  end: Point,
  visualize: Bool,
) -> Result(Path, Nil) {
  let path = Path(grid.manhatten_distance(start, end), 0, Step(E, start), [])
  let queue = pq.new(path_compare) |> pq.push(path)
  a_star(map, queue, end, dict.new(), 0, visualize)
}

fn find_first_blocker(
  map: Grid(Map),
  start: Point,
  end: Point,
  to_fall: List(Point),
  shortest_path: Path,
  visualize: Bool,
) -> Point {
  case to_fall {
    [] -> start
    [p, ..rest] -> {
      let assert Ok(map) = map |> grid.insert(p, Wall)
      let new_path = case on_path(shortest_path, p) {
        False -> Ok(shortest_path)
        True -> find_shortest_path(map, start, end, visualize)
      }
      case new_path {
        Error(_) -> {
          print_map(
            map,
            Path(grid.manhatten_distance(start, end), 0, Step(E, start), []),
            0,
            visualize,
          )
          p
        }
        Ok(path) -> find_first_blocker(map, start, end, rest, path, visualize)
      }
    }
  }
}

fn on_path(path: Path, point: Point) -> Bool {
  [path.head, ..path.tail]
  |> list.map(fn(s) { s.point })
  |> list.any(fn(p) { p == point })
}

fn do_solve(
  data: String,
  max_x: Int,
  max_y: Int,
  fallen: Int,
  visualization: helper.Visualize,
) -> #(Int, Int) {
  case visualization != helper.None {
    True -> io.println_error(codes.clear_screen_code <> codes.hide_cursor_code)
    False -> Nil
  }

  let points =
    data
    |> string.split("\n")
    |> list.map(fn(s) {
      s
      |> string.split_once(",")
      |> result.map(fn(p) {
        p
        |> helper.map_both(int.parse)
        |> helper.map_both(result.unwrap(_, 0))
        |> fn(p) { Point(p.0, p.1) }
      })
    })
    |> result.values

  let start = Point(0, 0)
  let end = Point(max_x, max_y)

  let #(fallen, to_fall) = list.split(points, fallen)

  let map =
    fallen
    |> list.map(fn(p) { #(p, Wall) })
    |> list.prepend(#(start, Start))
    |> list.prepend(#(end, End))
    |> dict.from_list
    |> Grid(max_x + 1, max_y + 1, _)

  let assert Ok(shortest_path) =
    find_shortest_path(
      map,
      start,
      end,
      visualization == helper.Both || visualization == helper.Part1,
    )

  let blocker =
    find_first_blocker(
      map,
      start,
      end,
      to_fall,
      shortest_path,
      visualization == helper.Both || visualization == helper.Part2,
    )

  case visualization == helper.Both {
    True ->
      io.println_error(
        "\n"
        <> "Part 2: " |> helper.faff_pink
        <> [blocker.x, blocker.y]
        |> list.map(int.to_string)
        |> string.join(",")
        |> helper.unnamed_blue,
      )
    False -> Nil
  }

  case visualization != helper.None {
    True -> io.println_error(codes.show_cursor_code)
    False -> Nil
  }

  let part2 =
    [blocker.x, blocker.y]
    |> list.map(int.digits(_, 10))
    |> result.values
    |> list.flatten
    |> int.undigits(10)
    |> result.unwrap(0)

  #(shortest_path.cost, part2)
}
