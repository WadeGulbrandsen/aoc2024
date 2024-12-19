import gleam/list
import gleam/string
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

pub fn solve(data: String, _visualization: helper.Visualize) -> #(Int, Int) {
  let assert Ok(#(towels, displays)) = string.split_once(data, "\n\n")
  let towels = towels |> string.split(", ")
  let displays = displays |> string.split("\n")
  let possible = displays |> list.filter(is_possible(_, towels, towels))
  #(list.length(possible), 0)
}
