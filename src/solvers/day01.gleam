import gleam/dict
import gleam/int
import gleam/list
import gleam/regexp
import gleam/result
import gleam/string

fn get_lists(data: String) -> #(List(Int), List(Int)) {
  let assert Ok(re) = regexp.from_string("\\s+")
  case
    data
    |> string.split("\n")
    |> list.map(regexp.split(re, _))
    |> list.transpose
    |> list.map(list.map(_, fn(x) { int.parse(x) }))
    |> list.map(result.values)
  {
    [a, b, ..] -> #(a, b)
    _ -> #([], [])
  }
}

pub fn part1(data: String) -> Int {
  let #(a, b) = get_lists(data)
  list.map2(
    a |> list.sort(int.compare),
    b |> list.sort(int.compare),
    int.subtract,
  )
  |> list.map(int.absolute_value)
  |> int.sum
}

pub fn part2(data: String) -> Int {
  let #(left, right) = get_lists(data)
  let right_counts =
    right
    |> list.group(fn(x) { x })
    |> dict.map_values(fn(_, v) { list.length(v) })
  left
  |> list.map(fn(x) { { dict.get(right_counts, x) |> result.unwrap(0) } * x })
  |> int.sum
}

pub fn solve(data: String) -> #(Int, Int) {
  #(part1(data), part2(data))
}
