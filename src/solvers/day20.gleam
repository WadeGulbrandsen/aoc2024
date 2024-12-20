import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option}
import gleam/order.{type Order}
import gleam/pair
import gleam/result
import gleam/string
import gleam/yielder
import gleamy/non_empty_list.{type NonEmptyList} as nel
import gleamy/priority_queue.{type Queue} as pq
import glitzer/progress.{type ProgressStyle}
import utils/grid.{type Grid, type Point, E, Grid, N, S, W}
import utils/helper

type Map {
  Wall
  Start
  End
  Step
}

type Path {
  Path(to_goal: Int, cost: Int, steps: NonEmptyList(Step))
}

type Step =
  Point

fn char_to_map(char: String) -> Result(Map, Nil) {
  case char {
    "#" -> Ok(Wall)
    "S" -> Ok(Start)
    "E" -> Ok(End)
    "O" -> Ok(Step)
    _ -> Error(Nil)
  }
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
    get_next(q.steps.first, map)
    |> list.filter_map(fn(cost_step) {
      let #(cost, step) = cost_step
      let g = cost + q.cost
      let h = dist(step, goal)
      case dict.get(seen, step) {
        Ok(x) if x <= g -> Error(Nil)
        _ -> Ok(Path(h, g, nel.Next(step, q.steps)))
      }
    })
  let found = list.find(next, fn(path) { path.steps.first == goal })
  use <- bool.guard(result.is_ok(found), found)
  let queue = next |> list.fold(queue, fn(queue, path) { pq.push(queue, path) })
  a_star(map, queue, goal, dict.insert(seen, q.steps.first, q.cost))
}

fn get_next(point: Point, map: Grid(Map)) -> List(#(Int, Step)) {
  [N, E, S, W]
  |> list.filter_map(fn(dir) {
    let next = grid.move(point, dir, 1)
    case grid.in_bounds(map, next) && grid.get(map, next) != Ok(Wall) {
      True -> Ok(#(1, next))
      False -> Error(Nil)
    }
  })
}

fn path_compare(a: Path, b: Path) -> Order {
  int.compare(a.cost + a.to_goal, b.cost + b.to_goal)
}

fn get_start_end(map: Grid(Map)) -> #(Point, Point) {
  let point_yielder = map.points |> dict.to_list |> yielder.from_list
  let assert Ok(#(start, _)) =
    point_yielder |> yielder.find(fn(p) { p.1 == Start })
  let assert Ok(#(end, _)) = point_yielder |> yielder.find(fn(p) { p.1 == End })
  #(start, end)
}

fn good_hacks(
  to_hack: List(#(Step, Int)),
  good: Int,
  p1_dist: Int,
  p2_dist: Int,
  p1_good: Dict(#(Step, Step), Int),
  p2_good: Dict(#(Step, Step), Int),
  bar: Option(ProgressStyle),
  tick: Int,
) -> #(Int, Int) {
  case to_hack {
    [] -> #(p1_good, p2_good) |> helper.map_both(dict.size)
    [#(start, start_cost), ..rest] -> {
      let #(p1_good, p2_good) =
        rest
        |> list.fold(#(p1_good, p2_good), fn(caches, end) {
          let #(end, end_cost) = end
          let distance = dist(start, end)
          let savings = end_cost - start_cost - distance
          use <- bool.guard(savings < good || distance <= 1, caches)
          case distance <= p1_dist, distance <= p2_dist {
            True, True ->
              caches |> helper.map_both(dict.insert(_, #(start, end), savings))
            True, _ ->
              caches |> pair.map_first(dict.insert(_, #(start, end), savings))
            _, True ->
              caches |> pair.map_second(dict.insert(_, #(start, end), savings))
            _, _ -> caches
          }
        })
      let bar = case bar {
        option.None -> bar
        option.Some(b) -> {
          use <- bool.guard(list.length(rest) % 100 != tick, bar)
          let b = progress.tick(b)
          progress.print_bar(b)
          option.Some(b)
        }
      }
      good_hacks(rest, good, p1_dist, p2_dist, p1_good, p2_good, bar, tick)
    }
  }
}

pub fn test_solve(data: String, good: Int) -> #(Int, Int) {
  do_solve(data, good, helper.None)
}

pub fn solve(data: String, visualization: helper.Visualize) -> #(Int, Int) {
  do_solve(data, 100, visualization)
}

fn dist(a: Step, b: Step) -> Int {
  grid.manhatten_distance(a, b)
}

fn do_solve(
  data: String,
  good: Int,
  visualization: helper.Visualize,
) -> #(Int, Int) {
  let map = grid.from_string(data, string.to_graphemes, char_to_map)
  let #(start, end) = get_start_end(map)
  let initial_path = Path(dist(start, end), 0, nel.End(start))
  let initial_queue = pq.new(path_compare) |> pq.push(initial_path)
  let assert Ok(non_cheat_path) = a_star(map, initial_queue, end, dict.new())

  let tick = non_cheat_path.cost / 100

  let bar = case visualization != helper.None {
    True ->
      option.Some(
        progress.fancy_thick_bar()
        |> progress.with_left_text(helper.faff_pink("["))
        |> progress.with_right_text(helper.faff_pink("] Hacking the Gibson")),
      )
    False -> option.None
  }

  let #(p1, p2) =
    non_cheat_path.steps
    |> nel.reverse
    |> nel.to_list
    |> list.index_map(fn(s, i) { #(s, i) })
    |> good_hacks(good, 2, 20, dict.new(), dict.new(), bar, tick)

  case bar {
    option.None -> Nil
    option.Some(bar) ->
      bar
      |> progress.with_right_text("] Done!" |> helper.faff_pink)
      |> progress.finish
      |> progress.print_bar
  }

  #(p1, p2)
}
