import gary.{type ErlangArray as Array}
import gary/array
import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option
import gleam/pair
import gleam/result
import gleam/string
import gleamy/pairing_heap.{type Heap} as heap

fn checksum(files: Array(Int)) -> Int {
  files |> array.sparse_fold(0, fn(index, id, total) { index * id + total })
}

fn parse_data(data: String) -> #(Array(Int), Dict(Int, Heap(Int))) {
  let values =
    data |> string.to_graphemes |> list.map(int.parse) |> result.values
  let assert Ok(array) = array.create_fixed_size(int.sum(values), -1)
  map_disk(values, 0, 0, array, dict.new())
}

fn map_disk(
  values: List(Int),
  id: Int,
  index: Int,
  files: Array(Int),
  spaces: Dict(Int, Heap(Int)),
) -> #(Array(Int), Dict(Int, Heap(Int))) {
  case values {
    [] -> #(files, spaces)
    [file] -> #(files |> add_file(id, index, file), spaces)
    [file, space, ..rest] -> {
      let files = files |> add_file(id, index, file)
      let spaces = spaces |> add_space(index + file, space)
      map_disk(rest, id + 1, index + file + space, files, spaces)
    }
  }
}

fn add_file(files: Array(Int), id: Int, index: Int, size: Int) -> Array(Int) {
  list.range(index, index + size - 1)
  |> list.fold(files, fn(acc, i) {
    let assert Ok(acc) = array.set(acc, i, id)
    acc
  })
}

fn del_file(files: Array(Int), index: Int, size: Int) -> Array(Int) {
  list.range(index, index + size - 1)
  |> list.fold(files, fn(acc, i) {
    let assert Ok(acc) = array.drop(acc, i)
    acc
  })
}

fn add_space(
  spaces: Dict(Int, Heap(Int)),
  index: Int,
  size: Int,
) -> Dict(Int, Heap(Int)) {
  use <- bool.guard(size == 0, spaces)
  dict.upsert(spaces, size, fn(i) {
    case i {
      option.Some(h) -> h
      option.None -> heap.new(int.compare)
    }
    |> heap.insert(index)
  })
}

fn del_space(spaces: Dict(Int, Heap(Int)), size: Int) -> Dict(Int, Heap(Int)) {
  use <- bool.guard(size == 0, spaces)
  case dict.get(spaces, size) {
    Error(_) -> spaces
    Ok(h) ->
      case heap.delete_min(h) {
        Error(_) -> dict.delete(spaces, size)
        Ok(#(_, h)) -> dict.insert(spaces, size, h)
      }
  }
}

fn part1(files: Array(Int), head: Int, tail: Int) -> Array(Int) {
  use <- bool.guard(head >= tail, files)
  let #(files, head, tail) = case
    array.get(files, head) == Ok(-1),
    array.get(files, tail)
  {
    False, _ -> #(files, head + 1, tail)
    True, Error(_) -> #(files, head, tail - 1)
    True, Ok(id) if id == -1 -> #(files, head, tail - 1)
    True, Ok(id) -> {
      let assert Ok(files) =
        files |> array.set(head, id) |> result.try(array.drop(_, tail))
      #(files, head + 1, tail - 1)
    }
  }
  part1(files, head, tail)
}

fn part2(
  files: Array(Int),
  spaces: Dict(Int, Heap(Int)),
  tail: Int,
) -> Array(Int) {
  case get_file(files, tail) {
    Error(_) -> files
    Ok(#(id, f_start, f_size)) -> {
      let tail = f_start - 1
      let #(files, spaces) = case get_space(spaces, f_size, f_start) {
        Ok(#(s_start, s_size)) -> {
          let spaces =
            case s_size == f_size {
              True -> spaces
              False -> spaces |> add_space(s_start + f_size, s_size - f_size)
            }
            |> del_space(s_size)
          let files =
            files
            |> del_file(f_start, f_size)
            |> add_file(id, s_start, f_size)
          #(files, spaces)
        }
        _ -> #(files, spaces)
      }
      part2(files, spaces, tail)
    }
  }
}

fn get_space(
  spaces: Dict(Int, Heap(Int)),
  size: Int,
  max_index: Int,
) -> Result(#(Int, Int), Nil) {
  spaces
  |> dict.filter(fn(k, _) { k >= size })
  |> dict.map_values(fn(_, v) { heap.find_min(v) |> result.unwrap(9001) })
  |> dict.filter(fn(_, v) { v < max_index })
  |> dict.to_list
  |> list.map(pair.swap)
  |> list.sort(fn(a, b) { int.compare(a.0, b.0) })
  |> list.first
}

fn get_file_r(
  files: Array(Int),
  id: Int,
  end: Int,
  current: Int,
) -> #(Int, Int, Int) {
  case array.get(files, current) == Ok(id) {
    False -> #(id, current + 1, end - current)
    True -> get_file_r(files, id, end, current - 1)
  }
}

fn get_file(files: Array(Int), tail: Int) -> Result(#(Int, Int, Int), Nil) {
  case array.get(files, tail) {
    Error(_) -> Error(Nil)
    Ok(id) if id > 0 -> Ok(get_file_r(files, id, tail, tail))
    Ok(_) -> get_file(files, tail - 1)
  }
}

pub fn solve(data: String) -> #(Int, Int) {
  let #(files, spaces) = parse_data(data)
  let tail = array.get_size(files) - 1
  #(part1(files, 0, tail) |> checksum, part2(files, spaces, tail) |> checksum)
}
// fn files_debug(files: Array(Int)) -> Array(Int) {
//   files
//   |> array.to_list
//   |> list.map(fn(v) {
//     case v {
//       -1 -> "." |> helper.unnamed_blue
//       _ -> v % 36 |> int.to_base36 |> helper.faff_pink
//     }
//   })
//   |> string.concat
//   |> helper.bg_underwater_blue
//   |> io.println_error
//   files
// }
