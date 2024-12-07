import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/pair
import gleam/result
import gleam/string

fn part1(calibrations: Dict(Int, List(Int))) -> Int {
  calibrations
  |> dict.filter(fn(k, v) { solveable(k, [v]) })
  |> dict.keys
  |> int.sum
}

fn part2(calibrations: Dict(Int, List(Int))) -> Int {
  calibrations
  |> dict.filter(fn(k, v) { with_concatenation(k, [v]) })
  |> dict.keys
  |> int.sum
}

fn concat(a: Int, b: Int) -> Int {
  let assert Ok(a_digits) = int.digits(a, 10)
  let assert Ok(b_digits) = int.digits(b, 10)

  a_digits
  |> list.append(b_digits)
  |> int.undigits(10)
  |> result.unwrap(0)
}

fn with_concatenation(result: Int, to_check: List(List(Int))) -> Bool {
  case to_check {
    [] -> False
    [[x], ..] if x == result -> True
    [calibration, ..rest] -> {
      let to_check = case calibration {
        [] | [_] -> rest
        [a, b, ..tail] -> [
          [a + b, ..tail],
          [a * b, ..tail],
          [concat(a, b), ..tail],
          ..rest
        ]
      }
      with_concatenation(result, to_check)
    }
  }
}

fn solveable(result: Int, to_check: List(List(Int))) -> Bool {
  case to_check {
    [] -> False
    [[x], ..] if x == result -> True
    [calibration, ..rest] -> {
      let to_check = case calibration {
        [] | [_] -> rest
        [a, b, ..tail] -> [[a + b, ..tail], [a * b, ..tail], ..rest]
      }
      solveable(result, to_check)
    }
  }
}

pub fn solve(data: String) -> #(Int, Int) {
  let calibrations =
    data
    |> string.split("\n")
    |> list.map(string.split_once(_, ": "))
    |> result.values
    |> list.map(fn(p) {
      #(
        p |> pair.first |> int.parse |> result.unwrap(0),
        p
          |> pair.second
          |> string.split(" ")
          |> list.map(int.parse)
          |> result.values,
      )
    })
    |> dict.from_list

  #(part1(calibrations), part2(calibrations))
}
