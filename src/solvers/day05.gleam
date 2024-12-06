import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/order.{type Order}
import gleam/pair
import gleam/result
import gleam/string
import utils/helper

fn order(a: String, b: String, rules: Dict(String, List(String))) -> Order {
  let after_a = dict.get(rules, a) |> result.unwrap([]) |> list.contains(b)
  let after_b = dict.get(rules, b) |> result.unwrap([]) |> list.contains(a)
  case after_a, after_b {
    True, _ -> order.Lt
    _, True -> order.Gt
    _, _ -> order.Eq
  }
}

fn middle_value(update: List(String)) -> Int {
  update
  |> helper.at_index(list.length(update) / 2)
  |> result.try(int.parse)
  |> result.unwrap(0)
}

fn in_order(update: List(String), rules: Dict(String, List(String))) -> Bool {
  update
  |> list.window_by_2
  |> list.all(fn(p) { order(pair.first(p), pair.second(p), rules) != order.Gt })
}

pub fn solve(data: String) -> #(Int, Int) {
  let assert Ok(#(rules, updates)) = string.split_once(data, "\n\n")

  let rules =
    rules
    |> string.split("\n")
    |> list.map(string.split_once(_, "|"))
    |> result.values
    |> list.group(pair.first)
    |> dict.map_values(fn(_, v) { v |> list.map(pair.second) })

  let order_fn = fn(a, b) { order(a, b, rules) }

  updates
  |> string.split("\n")
  |> list.map(string.split(_, ","))
  |> list.partition(in_order(_, rules))
  |> pair.map_second(list.map(_, list.sort(_, order_fn)))
  |> helper.map_both(list.map(_, middle_value))
  |> helper.map_both(int.sum)
}
