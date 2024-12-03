import gleam/int
import gleam/list
import gleam/option
import gleam/pair
import gleam/regexp.{type Match}
import gleam/result
import gleam/string

pub fn part1(data: String) -> Int {
  let assert Ok(re) = regexp.from_string("mul\\((\\d+),(\\d+)\\)")
  regexp.scan(re, data)
  |> list.map(mul)
  |> int.sum
}

fn mul(mul: Match) -> Int {
  mul.submatches
  |> option.values
  |> list.map(int.parse)
  |> result.values
  |> list.fold(1, int.multiply)
}

pub fn part2(data: String) -> Int {
  { "do()" <> data }
  |> string.split("don't")
  |> list.map(string.split_once(_, "do()"))
  |> result.values
  |> list.map(pair.second)
  |> list.map(part1)
  |> int.sum
}

pub fn solve(data: String) -> #(Int, Int) {
  #(part1(data), part2(data))
}
