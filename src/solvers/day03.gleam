import gleam/int
import gleam/list
import gleam/option
import gleam/regexp.{type Match}
import gleam/result

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
  let assert Ok(re) =
    regexp.from_string("mul\\((\\d+),(\\d+)\\)|do(?:n't)?\\(\\)")
  regexp.scan(re, data) |> process(True, 0)
}

fn process(instructions: List(Match), enabled: Bool, sum: Int) -> Int {
  case instructions {
    [] -> sum
    [m, ..rest] -> {
      let #(enabled, sum) = case m.content {
        "do()" -> #(True, sum)
        "don't()" -> #(False, sum)
        "mul" <> _ if enabled -> #(enabled, sum + mul(m))
        _ -> #(enabled, sum)
      }
      process(rest, enabled, sum)
    }
  }
}

pub fn solve(data: String) -> #(Int, Int) {
  #(part1(data), part2(data))
}
