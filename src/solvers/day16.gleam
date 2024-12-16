import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/order
import gleam/result
import gleam/set
import gleam/string
import gleamy/priority_queue.{type Queue} as pq
import utils/grid.{type Direction, type Grid, type Point, E}
import utils/helper

type Map {
  Wall
  Start
  End
}

type Step {
  Advance(dir: Direction, point: Point)
  Turn(dir: Direction, point: Point)
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

fn all_best_paths(
  map: Grid(Map),
  queue: Queue(Path),
  goal: Point,
  seen: Dict(Step, Int),
  best: Int,
  acc: List(Path),
) -> List(Path) {
  use <- bool.guard(pq.is_empty(queue), acc)
  let assert Ok(#(q, queue)) = pq.pop(queue)
  let next =
    get_next(q)
    |> list.filter_map(fn(cost_step) {
      let #(cost, step) = cost_step
      let g = cost + q.cost
      use <- bool.guard(
        grid.get(map, step.point) == Ok(Wall) || g > best,
        Error(Nil),
      )
      let h = grid.manhatten_distance(step.point, goal)
      case dict.get(seen, step) {
        Ok(x) if x < h + g -> Error(Nil)
        _ -> Ok(Path(h, g, step, [q.head, ..q.tail]))
      }
    })
  let acc =
    list.filter(next, fn(path) { path.head.point == goal }) |> list.append(acc)
  let queue = next |> list.fold(queue, fn(queue, path) { pq.push(queue, path) })
  all_best_paths(
    map,
    queue,
    goal,
    dict.insert(seen, q.head, q.cost + q.to_goal),
    best,
    acc,
  )
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
    get_next(q)
    |> list.filter_map(fn(cost_step) {
      let #(cost, step) = cost_step
      use <- bool.guard(grid.get(map, step.point) == Ok(Wall), Error(Nil))
      let g = cost + q.cost
      let h = grid.manhatten_distance(step.point, goal)
      case dict.get(seen, step) {
        Ok(x) if x < h + g -> Error(Nil)
        _ -> Ok(Path(h, g, step, [q.head, ..q.tail]))
      }
    })
  let found = list.find(next, fn(path) { path.head.point == goal })
  use <- bool.guard(result.is_ok(found), found)
  let queue = next |> list.fold(queue, fn(queue, path) { pq.push(queue, path) })
  a_star(map, queue, goal, dict.insert(seen, q.head, q.cost + q.to_goal))
}

fn get_next(q: Path) -> List(#(Int, Step)) {
  [
    #(1, Advance(q.head.dir, grid.move(q.head.point, q.head.dir, 1))),
    #(1000, Turn(grid.rotate_left(q.head.dir), q.head.point)),
    #(1000, Turn(grid.rotate_right(q.head.dir), q.head.point)),
  ]
}

fn path_compare(a: Path, b: Path) -> order.Order {
  int.compare(a.cost + a.to_goal, b.cost + b.to_goal)
}

pub fn solve(data: String, _visualization: helper.Visualize) -> #(Int, Int) {
  let #(map, start, end) = parse(data)
  let initial_path =
    Path(grid.manhatten_distance(start, end), 0, Advance(E, start), [])
  let queue = pq.new(path_compare) |> pq.push(initial_path)
  let part1 =
    a_star(map, queue, end, dict.new())
    |> result.map(fn(path) { path.cost })
    |> result.unwrap(0)
  let part2 =
    all_best_paths(map, queue, end, dict.new(), part1, [])
    |> list.fold(set.new(), fn(s, path) {
      [path.head, ..path.tail]
      |> list.map(fn(step) { step.point })
      |> set.from_list
      |> set.union(s)
    })
    |> set.size
  #(part1, part2)
}
