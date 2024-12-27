import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import rememo/memo
import tote/bag.{type Bag}
import utils/grid.{type Direction, type Grid, E, N, S, W}
import utils/helper

type Keypad {
  Activate
  Number(Int)
  Move(Direction)
}

type Sequence =
  List(Keypad)

type Sequences =
  Bag(Sequence)

type Path {
  Left(Int)
  Right(Int)
  Up(Int)
  Down(Int)
}

fn sequences_size(seqs: Sequences) -> Int {
  bag.fold(seqs, 0, fn(total, seq, count) { total + list.length(seq) * count })
}

fn get_sequence(
  from f: Keypad,
  to t: Keypad,
  keypad kp: Grid(Keypad),
) -> Sequence {
  let assert Ok(#(start, _)) =
    kp.points
    |> dict.to_list
    |> list.find(fn(point_kp) { point_kp.1 == f })
  let assert Ok(#(end, _)) =
    kp.points
    |> dict.to_list
    |> list.find(fn(point_kp) { point_kp.1 == t })
  let horizontal = {
    let diff = end.x - start.x
    case diff < 0 {
      True -> Left(-diff)
      False -> Right(diff)
    }
  }
  let verticle = {
    let diff = end.y - start.y
    case diff < 0 {
      True -> Up(-diff)
      False -> Down(diff)
    }
  }
  let ordered = case horizontal {
    _ if end.x == 0 && start.y == 3 -> [verticle, horizontal]
    _ if start.x == 0 && end.y == 3 -> [horizontal, verticle]
    _ if f == Move(W) -> [horizontal, verticle]
    _ if t == Move(W) -> [verticle, horizontal]
    Left(_) -> [horizontal, verticle]
    _ -> [verticle, horizontal]
  }
  ordered |> list.flat_map(path_to_sequence) |> list.append([Activate])
}

fn path_to_sequence(path p: Path) -> Sequence {
  case p {
    Left(x) -> list.repeat(Move(W), x)
    Right(x) -> list.repeat(Move(E), x)
    Up(x) -> list.repeat(Move(N), x)
    Down(x) -> list.repeat(Move(S), x)
  }
}

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

fn moves_to_moves(
  moves: Sequences,
  times: Int,
  kp_cache: Dict(#(Keypad, Keypad), Sequence),
  cache,
) -> Sequences {
  use <- bool.guard(times <= 0 || bag.is_empty(moves), moves)
  let next =
    moves
    |> bag.fold(bag.new(), fn(b, s, i) {
      s
      |> next_sequence(kp_cache, cache)
      |> split_sequence
      |> list.fold(b, fn(bag, seq) { bag |> bag.insert(i, seq) })
    })
  moves_to_moves(next, times - 1, kp_cache, cache)
}

fn split_sequence(sequence: Sequence) -> List(Sequence) {
  sequence
  |> list.fold(#([], []), fn(p, move) {
    let #(acc, current) = p
    let current = current |> list.append([move])
    case move {
      Activate -> #(acc |> list.append([current]), [])
      _ -> #(acc, current)
    }
  })
  |> pair.first
}

fn next_sequence(
  sequence: Sequence,
  kp_cache: Dict(#(Keypad, Keypad), Sequence),
  cache,
) -> Sequence {
  use <- memo.memoize(cache, sequence)
  [Activate, ..sequence]
  |> list.window_by_2
  |> list.map(dict.get(kp_cache, _))
  |> result.values
  |> list.flatten
}

fn kp_cache() -> Dict(#(Keypad, Keypad), Sequence) {
  let dirpad = directional_keypad()
  let dirs = [N, E, S, W] |> list.map(Move(_)) |> list.prepend(Activate)
  let dir_cache =
    dirs
    |> list.fold(dict.new(), fn(cache, from) {
      dirs
      |> list.fold(cache, fn(cache, to) {
        dict.insert(cache, #(from, to), get_sequence(from, to, dirpad))
      })
    })
  let numpad = numeric_keypad()
  let nums = list.range(0, 9) |> list.map(Number(_)) |> list.prepend(Activate)
  let num_cache =
    nums
    |> list.fold(dict.new(), fn(cache, from) {
      nums
      |> list.fold(cache, fn(cache, to) {
        dict.insert(cache, #(from, to), get_sequence(from, to, numpad))
      })
    })
  dir_cache |> dict.merge(num_cache)
}

pub fn solve(data: String, _visualization: helper.Visualize) -> #(Int, Int) {
  use cache <- memo.create()
  let kp_cache = kp_cache()

  let #(codes, numerics) = list.unzip(parse(data))

  let first_pass =
    codes
    |> list.map(fn(code) { bag.from_list([code]) })
    |> list.map(moves_to_moves(_, 3, kp_cache, cache))

  let part1 =
    first_pass
    |> list.map(sequences_size)
    |> list.map2(numerics, int.multiply)
    |> int.sum

  let part2 =
    first_pass
    |> list.map(moves_to_moves(_, 23, kp_cache, cache))
    |> list.map(sequences_size)
    |> list.map2(numerics, int.multiply)
    |> int.sum

  #(part1, part2)
}
