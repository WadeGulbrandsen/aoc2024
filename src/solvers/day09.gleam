import gleam/deque.{type Deque}
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import gleam/yielder

type FileSystem {
  Empty(size: Int)
  File(size: Int, id: Int)
}

fn disk_map(map: List(Int), acc: List(FileSystem), id: Int) -> List(FileSystem) {
  case map {
    [] -> acc |> list.reverse
    [f] -> [File(f, id), ..acc] |> list.reverse
    [f, e, ..rest] -> disk_map(rest, [Empty(e), File(f, id), ..acc], id + 1)
  }
}

fn part1(map: List(FileSystem)) -> Int {
  compact(map |> deque.from_list, [], 0) |> checksum
}

fn part2(map: List(FileSystem)) -> Int {
  move_files(map |> list.reverse, []) |> checksum
}

fn move_files(
  map: List(FileSystem),
  compacted: List(FileSystem),
) -> List(FileSystem) {
  case map {
    [] -> compacted
    [fs, ..rest] -> {
      let #(rest, compacted) = case fs {
        Empty(_) -> #(rest, [fs, ..compacted])
        File(_, _) -> fill_space(fs, rest, compacted)
      }
      move_files(rest, compacted)
    }
  }
}

fn fill_space(
  file: FileSystem,
  map: List(FileSystem),
  compacted: List(FileSystem),
) -> #(List(FileSystem), List(FileSystem)) {
  let split_fn = fn(fs) {
    case fs {
      Empty(x) if x >= file.size -> False
      _ -> True
    }
  }
  let #(before, after) = map |> list.reverse |> list.split_while(split_fn)
  case after {
    [Empty(x), ..rest] if x == file.size -> #(
      list.flatten([before, [file], rest]) |> list.reverse,
      [Empty(x), ..compacted],
    )
    [Empty(x), ..rest] if x > file.size -> #(
      list.flatten([before, [file, Empty(x - file.size)], rest]) |> list.reverse,
      [Empty(file.size), ..compacted],
    )
    _ -> #(map, [file, ..compacted])
  }
}

fn compact(
  map: Deque(FileSystem),
  compacted: List(FileSystem),
  end: Int,
) -> List(FileSystem) {
  case deque.pop_front(map) {
    Error(Nil) -> [Empty(end), ..compacted] |> list.reverse
    Ok(#(fs, rest)) -> {
      let #(map, compacted, end) = case fs {
        File(_, _) -> #(rest, [fs, ..compacted], end)
        Empty(0) -> #(rest, compacted, end)
        Empty(x) ->
          case deque.pop_back(rest) {
            Error(Nil) -> #(rest, compacted, end + x)
            Ok(#(Empty(y), rest)) -> #(
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
              rest |> deque.push_front(Empty(x - s)),
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
      Empty(s) -> yielder.repeat(0) |> yielder.take(s)
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
  #(part1(map), part2(map))
}
