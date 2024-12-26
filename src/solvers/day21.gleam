import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/pair
import gleam/result
import gleam/set
import gleam/string
import gleamy/non_empty_list.{type NonEmptyList} as nel
import gleamy/priority_queue.{type Queue} as pq
import utils/grid.{type Direction, type Grid, type Point, E, N, S, W}
import utils/helper

type Keypad {
  Activate
  Number(Int)
  Move(Direction)
}

type Sequence =
  List(Keypad)

type Sequences =
  List(Sequence)

fn numeric_keypad() -> Grid(Keypad) {
  "789\n456\n123\n.0A" |> grid.from_string(string.to_graphemes, char_to_keypad)
}

fn directional_keypad() -> Grid(Keypad) {
  ".^A\n<v>" |> grid.from_string(string.to_graphemes, char_to_keypad)
}

fn char_to_keypad(char: String) -> Result(Keypad, Nil) {
  case int.parse(char) {
    Ok(x) -> Ok(Number(x))
    _ ->
      case char {
        "^" -> Ok(Move(N))
        "v" -> Ok(Move(S))
        "<" -> Ok(Move(W))
        ">" -> Ok(Move(E))
        "A" -> Ok(Activate)
        _ -> Error(Nil)
      }
  }
}

type Path {
  Path(to_goal: Int, cost: Int, steps: NonEmptyList(Step))
}

type Step {
  Step(direction: Direction, point: Point, content: Keypad)
}

fn best_paths(
  keypad: Grid(Keypad),
  queue: Queue(Path),
  goal: Point,
  seen: Dict(Step, Int),
  best: Option(Int),
  acc: List(Path),
) -> List(Path) {
  use <- bool.guard(pq.is_empty(queue), acc)

  let assert Ok(#(q, queue)) = pq.pop(queue)

  let #(queue, best, acc) = {
    use <- bool.guard(greater_than_best(q.cost, best), #(queue, best, acc))
    use <- bool.guard(
      q.steps.first.point == goal && best == Some(q.cost),
      #(queue, best, [q, ..acc]),
    )
    use <- bool.guard(q.steps.first.point == goal, #(queue, Some(q.cost), [q]))
    let next =
      get_next(q.steps.first.point, keypad)
      |> list.filter_map(fn(step) {
        let g = 1 + q.cost
        use <- bool.guard(greater_than_best(g, best), Error(Nil))
        let h = grid.manhatten_distance(step.point, goal)
        case dict.get(seen, step) {
          Ok(x) if x <= g -> Error(Nil)
          _ -> Ok(Path(h, g, nel.Next(step, q.steps)))
        }
      })
    let queue =
      next |> list.fold(queue, fn(queue, path) { pq.push(queue, path) })
    #(queue, best, acc)
  }
  best_paths(keypad, queue, goal, seen, best, acc)
}

fn get_next(point: Point, keypad: Grid(Keypad)) -> List(Step) {
  [N, E, S, W]
  |> list.filter_map(fn(dir) {
    let next_point = grid.move(point, dir, 1)
    grid.get(keypad, next_point)
    |> result.map(Step(dir, next_point, _))
  })
}

fn greater_than_best(g: Int, best: Option(Int)) -> Bool {
  case best {
    Some(x) -> g > x
    None -> False
  }
}

fn path_compare(a: Path, b: Path) -> order.Order {
  int.compare(a.cost + a.to_goal, b.cost + a.to_goal)
}

fn parse(data: String) -> List(#(List(Keypad), Int)) {
  data
  |> string.split("\n")
  |> list.map(fn(code) {
    #(
      code |> string.to_graphemes |> list.map(char_to_keypad) |> result.values,
      code |> string.drop_end(1) |> int.parse |> result.unwrap(0),
    )
  })
}

// fn keypad_to_char(kp: Keypad) -> String {
//   case kp {
//     Number(x) -> int.to_string(x)
//     Move(N) -> "^"
//     Move(S) -> "v"
//     Move(W) -> "<"
//     Move(E) -> ">"
//     Activate -> "A"
//     _ -> "."
//   }
// }

// fn print_sequences_and_numeric(s_num: #(Sequences, Int)) {
//   let #(s, num) = s_num
//   let s =
//     s
//     |> list.map(fn(seq) {
//       #(list.length(seq), seq |> list.map(keypad_to_char) |> string.concat)
//     })
//   pprint.styled(#(num, s)) |> io.println_error
//   s_num
// }

fn code_to_moves(
  code: List(Keypad),
  current: Keypad,
  numpad: Grid(Keypad),
  acc: List(List(Sequence)),
) -> Sequences {
  case code {
    [] -> build_sequences(acc |> list.reverse, [])
    [next, ..rest] -> {
      let paths = best_keypad_paths(current, next, numpad)
      code_to_moves(rest, next, numpad, [
        paths |> list.map(path_to_sequence),
        ..acc
      ])
    }
  }
}

fn moves_to_moves(
  moves: List(Keypad),
  current: Keypad,
  cache: Dict(#(Keypad, Keypad), Sequences),
  acc: List(List(Sequence)),
) -> Sequences {
  case moves {
    [] -> build_sequences(acc |> list.reverse, [])
    [next, ..rest] -> {
      let assert Ok(seqs) = dict.get(cache, #(current, next))
      moves_to_moves(rest, next, cache, [seqs, ..acc])
    }
  }
}

fn build_sequences(to_add: List(Sequences), acc: Sequences) -> Sequences {
  case to_add {
    [] -> acc
    [x, ..rest] -> {
      let acc = case list.is_empty(acc) {
        True -> x
        False -> {
          acc
          |> list.flat_map(fn(head) { x |> list.map(list.append(head, _)) })
        }
      }
      build_sequences(rest, acc)
    }
  }
}

fn best_keypad_paths(
  from: Keypad,
  to: Keypad,
  keypad: Grid(Keypad),
) -> List(Path) {
  let assert Ok(#(start, _)) =
    keypad.points
    |> dict.to_list
    |> list.find(fn(point_kp) { point_kp.1 == from })
  let assert Ok(#(end, _)) =
    keypad.points
    |> dict.to_list
    |> list.find(fn(point_kp) { point_kp.1 == to })
  let initial_path =
    Path(grid.manhatten_distance(start, end), 0, nel.End(Step(E, start, from)))
  let queue = pq.new(path_compare) |> pq.push(initial_path)
  best_paths(keypad, queue, end, dict.new(), None, [])
}

fn path_to_sequence(path: Path) -> Sequence {
  path.steps
  |> nel.to_list
  |> list.map(fn(step) { Move(step.direction) })
  |> list.prepend(Activate)
  |> list.reverse
  |> list.drop(1)
}

fn dir_path_cache() -> Dict(#(Keypad, Keypad), Sequences) {
  let dirpad = directional_keypad()
  let dirs =
    [N, E, S, W]
    |> list.map(Move(_))
    |> list.prepend(Activate)

  dirs
  |> list.fold(dict.new(), fn(cache, from) {
    dirs
    |> list.fold(cache, fn(cache, to) {
      dict.insert(
        cache,
        #(from, to),
        best_keypad_paths(from, to, dirpad) |> list.map(path_to_sequence),
      )
    })
  })
}

fn keep_shortest(sequences: Sequences) -> Sequences {
  use <- bool.guard(list.is_empty(sequences), [])
  let assert [first, ..rest] = sequences
  rest
  |> list.fold(
    #(list.length(first), set.from_list([first])),
    fn(lowest_acc, seq) {
      let #(lowest, acc) = lowest_acc
      let len = list.length(seq)
      case int.compare(len, lowest) {
        order.Gt -> lowest_acc
        order.Eq -> #(lowest, set.insert(acc, seq))
        order.Lt -> #(len, set.from_list([seq]))
      }
    },
  )
  |> pair.second
  |> set.to_list
}

pub fn solve(data: String, _visualization: helper.Visualize) -> #(Int, Int) {
  let numpad = numeric_keypad()
  let cache = dir_path_cache()

  let part1 =
    parse(data)
    |> helper.parallel_map(fn(p) {
      let #(code, numeric) = p
      code
      |> code_to_moves(Activate, numpad, [])
      |> helper.parallel_map(moves_to_moves(_, Activate, cache, []))
      |> list.flatten
      |> keep_shortest
      |> helper.parallel_map(moves_to_moves(_, Activate, cache, []))
      |> list.flatten
      |> keep_shortest
      |> list.first
      |> result.unwrap([])
      |> list.length
      |> int.multiply(numeric)
    })
    |> int.sum

  #(part1, 0)
}
