import gleam/int
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import gleam/yielder

fn check_calibrations(
  calibrations: List(#(Int, List(Int))),
  ops: List(fn(Int, Int) -> Int),
) -> Int {
  calibrations
  |> yielder.from_list
  |> yielder.filter(fn(c) { is_solveable(c.0, [c.1], ops) })
  |> yielder.map(pair.first)
  |> yielder.fold(0, int.add)
}

fn concat(a: Int, b: Int) -> Int {
  let assert Ok(a_digits) = int.digits(a, 10)
  let assert Ok(b_digits) = int.digits(b, 10)
  a_digits
  |> list.append(b_digits)
  |> int.undigits(10)
  |> result.unwrap(0)
}

fn is_solveable(
  result: Int,
  to_check: List(List(Int)),
  ops: List(fn(Int, Int) -> Int),
) -> Bool {
  case to_check {
    [] -> False
    [[x], ..] if x == result -> True
    [calibration, ..rest] -> {
      let to_check = case calibration {
        [] | [_] -> rest
        [a, b, ..tail] ->
          ops |> list.map(fn(op) { [op(a, b), ..tail] }) |> list.append(rest)
      }
      is_solveable(result, to_check, ops)
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

  #(
    check_calibrations(calibrations, [int.add, int.multiply]),
    check_calibrations(calibrations, [int.add, int.multiply, concat]),
  )
}
