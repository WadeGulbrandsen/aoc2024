import gleam/bool
import gleam/int
import gleam/list
import gleam/string
import rememo/memo
import utils/helper

fn is_possible(
  display: String,
  to_check: List(String),
  towels: List(String),
) -> Bool {
  case to_check {
    [] -> False
    [t, ..] if t == display -> True
    [t, ..rest] -> {
      case string.starts_with(display, t) {
        True ->
          is_possible(
            string.drop_start(display, string.length(t)),
            towels,
            towels,
          )
        False -> False
      }
      || is_possible(display, rest, towels)
    }
  }
}

fn all_combinations(display: String, towels: List(String), cache) -> Int {
  use <- memo.memoize(cache, display)
  use <- bool.guard(string.is_empty(display), 1)
  towels
  |> list.filter_map(fn(towel) {
    case display |> string.starts_with(towel) {
      False -> Error(Nil)
      True ->
        Ok(all_combinations(
          display |> string.drop_start(string.length(towel)),
          towels,
          cache,
        ))
    }
  })
  |> int.sum
}

pub fn solve(data: String, _visualization: helper.Visualize) -> #(Int, Int) {
  let assert Ok(#(towels, displays)) = string.split_once(data, "\n\n")
  let towels = towels |> string.split(", ")
  let displays = displays |> string.split("\n")
  let possible =
    displays |> helper.parallel_filter(is_possible(_, towels, towels))
  use cache <- memo.create()
  let all_combinations =
    possible |> list.map(all_combinations(_, towels, cache))
  #(list.length(possible), all_combinations |> int.sum)
}
