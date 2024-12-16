import gleam/bool
import gleam/dict.{type Dict}
import gleam/function
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/result
import gleam/set
import gleam/string
import gleamy/priority_queue.{type Queue} as pq
import utils/grid.{type Direction, type Grid, type Point, E}
import utils/helper

// Optimization possibilities:
// - Improve hueristic
//   - Check if a turn is required and add 1000 to h if so
//     - Done: 4305.484ms to 3653.943ms on Crustini VM
// - Combine turns with movement
//   - This will add a 4th possiblibilty of going backwards
//     - Done: 4305.484ms to 1008.417ms on Crustini VM
//       - Borat Great Success! meme goes here
// - Get all best paths in at once
//   - Done: 1008.417ms to 604.874ms on Crustini VM
// - If the above doesn't work look into Parallel A*
//   - https://cse.buffalo.edu/faculty/miller/Courses/CSE633/Weijin-Zhu-Spring-2020.pdf
//   - https://medium.com/analytics-vidhya/parallel-a-search-on-gpu-ceb3bfe2cf51
//   - https://ojs.aaai.org/index.php/AAAI/article/view/9367/9226

type Map {
  Wall
  Start
  End
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
) -> List(Path) {
  use <- bool.guard(pq.is_empty(queue), acc)
  let assert Ok(#(q, queue)) = pq.pop(queue)
  let #(found, next) = {
    use <- bool.guard(greater_than_best(q.cost, best), #([], []))
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
  )
}

// Original A* used in part 1
//
// fn a_star(
//   map: Grid(Map),
//   queue: Queue(Path),
//   goal: Point,
//   seen: Dict(Step, Int),
// ) -> Result(Path, Nil) {
//   use <- bool.guard(pq.is_empty(queue), Error(Nil))
//   let assert Ok(#(q, queue)) = pq.pop(queue)
//   let next =
//     get_next(q)
//     |> list.filter_map(fn(cost_step) {
//       let #(cost, step) = cost_step
//       use <- bool.guard(grid.get(map, step.point) == Ok(Wall), Error(Nil))
//       let g = cost + q.cost
//       let h =
//         grid.manhatten_distance(step.point, goal)
//         + 1000
//         * bool.to_int(step.point.x != goal.x || step.point.y != step.point.y)
//       case dict.get(seen, step) {
//         Ok(x) if x < h + g -> Error(Nil)
//         _ -> Ok(Path(h, g, step, [q.head, ..q.tail]))
//       }
//     })
//   let found = list.find(next, fn(path) { path.head.point == goal })
//   use <- bool.guard(result.is_ok(found), found)
//   let queue = next |> list.fold(queue, fn(queue, path) { pq.push(queue, path) })
//   a_star(map, queue, goal, dict.insert(seen, q.head, q.cost + q.to_goal))
// }

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

pub fn solve(data: String, _visualization: helper.Visualize) -> #(Int, Int) {
  let #(map, start, end) = parse(data)
  let initial_path =
    Path(grid.manhatten_distance(start, end), 0, Step(E, start), [])
  let queue = pq.new(path_compare) |> pq.push(initial_path)

  let best_paths = all_best_paths(map, queue, end, dict.new(), None, [])

  let part1 =
    best_paths
    |> list.first
    |> result.map(fn(path) { path.cost })
    |> result.unwrap(0)

  let part2 =
    best_paths
    |> list.fold(set.new(), fn(s, path) {
      [path.head, ..path.tail]
      |> list.map(fn(step) { step.point })
      |> set.from_list
      |> set.union(s)
    })
    |> set.size

  #(part1, part2)
}
