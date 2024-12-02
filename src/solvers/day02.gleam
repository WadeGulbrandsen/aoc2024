import gleam/int
import gleam/list
import gleam/result
import gleam/string

pub fn part1(reports: List(List(Int))) -> Int {
  reports |> list.filter(is_safe) |> list.length
}

pub fn part2(reports: List(List(Int))) -> Int {
  reports |> list.filter(problem_dampener) |> list.length
}

fn is_safe(levels: List(Int)) -> Bool {
  let differences = levels |> list.window_by_2 |> list.map(fn(p) { p.0 - p.1 })
  case differences |> list.first {
    Ok(d) if d > 0 -> list.all(differences, fn(x) { x >= 1 && x <= 3 })
    Ok(_) -> list.all(differences, fn(x) { x >= -3 && x <= -1 })
    _ -> False
  }
}

fn problem_dampener(levels: List(Int)) -> Bool {
  case is_safe(levels) {
    True -> True
    _ ->
      levels |> list.combinations(list.length(levels) - 1) |> list.any(is_safe)
  }
}

pub fn solve(data: String) -> #(Int, Int) {
  let reports =
    data
    |> string.split("\n")
    |> list.map(fn(report) {
      report |> string.split(" ") |> list.map(int.parse) |> result.values
    })
  #(part1(reports), part2(reports))
}
