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
    _ -> " "
  }
}

fn debug_map(map: Grid(Map)) -> Grid(Map) {
  io.println_error(
    codes.return_home_code
    <> "\n"
    <> grid.to_string(map, map_to_char) |> helper.bg_underwater_blue,
  )
  map
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
) -> Result(Path, Nil) {
  use <- bool.guard(pq.is_empty(queue), Error(Nil))
  let assert Ok(#(q, queue)) = pq.pop(queue)
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
  use <- bool.guard(result.is_ok(found), found)
  let queue = next |> list.fold(queue, fn(queue, path) { pq.push(queue, path) })
  a_star(map, queue, goal, dict.insert(seen, q.head, q.cost))
}

fn get_next(point: Point, map: Grid(Map)) -> List(#(Int, Step)) {
  [N, E, S, W]
  |> list.filter_map(fn(dir) {
    let point = grid.move(point, dir, 1)
    case grid.in_bounds(map, point) && grid.get(map, point) != Error(Nil) {
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
) -> Result(Path, Nil) {
  let path = Path(grid.manhatten_distance(start, end), 0, Step(E, start), [])
  let queue = pq.new(path_compare) |> pq.push(path)
  a_star(map, queue, end, dict.new())
}

fn do_solve(
  data: String,
  max_x: Int,
  max_y: Int,
  fallen: Int,
  _visualization: helper.Visualize,
) -> #(Int, Int) {
  io.println_error(codes.clear_screen_code <> codes.hide_cursor_code)
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
  let part1 =
    points
    |> list.take(fallen)
    |> list.map(fn(p) { #(p, Wall) })
    |> list.prepend(#(start, Start))
    |> list.prepend(#(end, End))
    |> dict.from_list
    |> Grid(max_x + 1, max_y + 1, _)
    |> debug_map
    |> find_shortest_path(start, end)
    |> io.debug
    |> result.map(fn(path) { path.cost })
    |> result.unwrap(0)
  io.println_error(codes.show_cursor_code)
  #(part1, 0)
}
