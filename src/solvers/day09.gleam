import gleam/bool
import gleam/deque.{type Deque}
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import gleam/yielder

type FileSystem {
  Space(size: Int)
  File(size: Int, id: Int)
}

fn is_space(fs: FileSystem) -> Bool {
  case fs {
    Space(_) -> True
    _ -> False
  }
}

fn disk_map(map: List(Int), acc: List(FileSystem), id: Int) -> List(FileSystem) {
  case map {
    [] -> acc |> list.reverse
    [f] -> [File(f, id), ..acc] |> list.reverse
    [f, e, ..rest] -> disk_map(rest, [Space(e), File(f, id), ..acc], id + 1)
  }
}

fn part1(map: Deque(FileSystem)) -> Int {
  compact(map, [], 0) |> checksum
}

fn part2(map: Deque(FileSystem)) -> Int {
  move_files(map, []) |> checksum
}

fn move_files(map: Deque(FileSystem), end: List(FileSystem)) {
  case deque.pop_back(map) {
    Error(Nil) -> end
    Ok(#(fs, rest)) -> {
      let #(map, end) = fill_space(fs, rest, end)
      move_files(map, end)
    }
  }
}

fn fill_space(
  fs: FileSystem,
  map: Deque(FileSystem),
  end: List(FileSystem),
) -> #(Deque(FileSystem), List(FileSystem)) {
  use <- bool.guard(is_space(fs), #(map, [fs, ..end]))
  case get_space([], map, fs.size) {
    Ok(#(before, space, map)) -> {
      let before = case space > fs.size {
        False -> [fs, ..before]
        True -> [Space(space - fs.size), fs, ..before]
      }
      let map = before |> list.fold(map, deque.push_front)
      #(map, [Space(fs.size), ..end])
    }
    _ -> #(map, [fs, ..end])
  }
}

fn get_space(
  before: List(FileSystem),
  map: Deque(FileSystem),
  size: Int,
) -> Result(#(List(FileSystem), Int, Deque(FileSystem)), Nil) {
  case deque.pop_front(map) {
    Error(_) -> Error(Nil)
    Ok(#(Space(x), rest)) if x >= size -> Ok(#(before, x, rest))
    Ok(#(fs, rest)) -> get_space([fs, ..before], rest, size)
  }
}

fn compact(
  map: Deque(FileSystem),
  compacted: List(FileSystem),
  end: Int,
) -> List(FileSystem) {
  case deque.pop_front(map) {
    Error(Nil) -> [Space(end), ..compacted] |> list.reverse
    Ok(#(fs, rest)) -> {
      let #(map, compacted, end) = case fs {
        File(_, _) -> #(rest, [fs, ..compacted], end)
        Space(0) -> #(rest, compacted, end)
        Space(x) ->
          case deque.pop_back(rest) {
            Error(Nil) -> #(rest, compacted, end + x)
            Ok(#(Space(y), rest)) -> #(
              rest |> deque.push_front(fs),
              compacted,
              end + y,
            )
            Ok(#(File(s, i), rest)) if x < s -> #(
              rest |> deque.push_back(File(s - x, i)),
              [File(x, i), ..compacted],
              end + x,
            )
            Ok(#(File(s, i), rest)) if x == s -> #(
              rest,
              [File(s, i), ..compacted],
              end + s,
            )
            Ok(#(File(s, i), rest)) -> #(
              rest |> deque.push_front(Space(x - s)),
              [File(s, i), ..compacted],
              end + s,
            )
          }
      }
      compact(map, compacted, end)
    }
  }
}

fn checksum(map: List(FileSystem)) -> Int {
  map
  |> yielder.from_list
  |> yielder.flat_map(fn(fs) {
    case fs {
      Space(s) -> yielder.repeat(0) |> yielder.take(s)
      File(s, i) -> yielder.repeat(i) |> yielder.take(s)
    }
  })
  |> yielder.index
  |> yielder.fold(0, fn(sum, p) { sum + p.0 * p.1 })
}

pub fn solve(data: String) -> #(Int, Int) {
  let map =
    data
    |> string.to_graphemes
    |> list.map(int.parse)
    |> result.values
    |> disk_map([], 0)
    |> deque.from_list
  #(part1(map), part2(map))
}
