import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option}
import gleam/order.{type Order}
import gleam/result
import gleam/string
import gleam/yielder
import gleamy/non_empty_list.{type NonEmptyList} as nel
import gleamy/priority_queue.{type Queue} as pq
import glitzer/progress.{type ProgressStyle}
import utils/grid.{type Grid, type Point, E, Grid, N, Point, S, W}
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

fn wall_hacks(
  to_hack: List(#(Step, Int)),
  good: Int,
  step_costs: Dict(Step, Int),
  mask: List(Point),
  good_hacks: Dict(#(Step, Step), Int),
  bar: Option(ProgressStyle),
  tick: Int,
) -> Int {
  case to_hack {
    [] -> good_hacks |> dict.size
    [#(start, start_cost), ..rest] -> {
      let good_hacks =
        mask
        |> list.map(grid.add_points(_, start))
        |> list.fold(good_hacks, fn(goods, end) {
          let end_cost = dict.get(step_costs, end) |> result.unwrap(0)
          let distance = dist(start, end)
          let savings = end_cost - start_cost - distance
          use <- bool.guard(savings < good, goods)
          goods |> dict.insert(#(start, end), savings)
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
      wall_hacks(rest, good, step_costs, mask, good_hacks, bar, tick)
    }
  }
}

fn dist(a: Step, b: Step) -> Int {
  grid.manhatten_distance(a, b)
}

fn mask(size: Int) -> List(Step) {
  list.range(0, size)
  |> list.flat_map(fn(x) {
    list.range(0, size - x)
    |> list.flat_map(fn(y) {
      [Point(x, y), Point(-x, y), Point(x, -y), Point(-x, -y)]
    })
  })
  |> list.unique
}

pub fn test_solve(data: String, good: Int) -> #(Int, Int) {
  do_solve(data, good, helper.None)
}

pub fn solve(data: String, visualization: helper.Visualize) -> #(Int, Int) {
  do_solve(data, 100, visualization)
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

  let p1_mask = mask(2)
  let p2_mask = mask(20)

  let steps =
    non_cheat_path.steps
    |> nel.reverse
    |> nel.to_list
    |> list.index_map(fn(s, i) { #(s, i) })

  let step_costs = steps |> dict.from_list

  let bar1 = case
    visualization == helper.Both || visualization == helper.Part1
  {
    True ->
      option.Some(
        progress.fancy_thick_bar()
        |> progress.with_left_text(helper.faff_pink("["))
        |> progress.with_right_text(helper.faff_pink("] Part 1")),
      )
    False -> option.None
  }

  let p1 = wall_hacks(steps, good, step_costs, p1_mask, dict.new(), bar1, tick)

  case bar1 {
    option.None -> Nil
    option.Some(bar) ->
      bar
      |> progress.with_right_text(
        "] Part 1: " |> helper.faff_pink
        <> helper.int_to_string_with_commas(p1) |> helper.unnamed_blue,
      )
      |> progress.finish
      |> progress.print_bar
  }

  let bar2 = case
    visualization == helper.Both || visualization == helper.Part2
  {
    True ->
      option.Some(
        progress.fancy_thick_bar()
        |> progress.with_left_text(helper.faff_pink("["))
        |> progress.with_right_text(helper.faff_pink("] Part 2")),
      )
    False -> option.None
  }

  let p2 = wall_hacks(steps, good, step_costs, p2_mask, dict.new(), bar2, tick)

  case bar2 {
    option.None -> Nil
    option.Some(bar) ->
      bar
      |> progress.with_right_text(
        "] Part 2: " |> helper.faff_pink
        <> helper.int_to_string_with_commas(p2) |> helper.unnamed_blue,
      )
      |> progress.finish
      |> progress.print_bar
  }

  #(p1, p2)
}
