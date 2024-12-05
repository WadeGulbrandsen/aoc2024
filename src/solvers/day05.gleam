import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/order.{type Order}
import gleam/pair
import gleam/result
import gleam/set.{type Set}
import gleam/string
import utils/helper

fn part1(rules: Dict(String, List(String)), updates: List(List(String))) -> Int {
  updates
  |> list.filter(in_order(set.new(), rules, _))
  |> list.map(middle_value)
  |> int.sum
}

fn part2(rules: Dict(String, List(String)), updates: List(List(String))) -> Int {
  let order_fn = fn(a, b) { order(a, b, rules) }
  updates
  |> list.filter(fn(u) { !in_order(set.new(), rules, u) })
  |> list.map(list.sort(_, order_fn))
  |> list.map(middle_value)
  |> int.sum
}

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

fn in_order(
  seen: Set(String),
  rules: Dict(String, List(String)),
  update: List(String),
) -> Bool {
  case update {
    [] -> True
    [x, ..rest] ->
      case
        dict.get(rules, x) |> result.map(list.any(_, set.contains(seen, _)))
      {
        Ok(True) -> False
        _ -> in_order(set.insert(seen, x), rules, rest)
      }
  }
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

  let updates =
    updates
    |> string.split("\n")
    |> list.map(string.split(_, ","))

  #(part1(rules, updates), part2(rules, updates))
}
