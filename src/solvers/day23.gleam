import gleam/bool
import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{None, Some}
import gleam/regexp.{Match}
import gleam/set.{type Set}
import gleam/string
import utils/helper

type LAN =
  Dict(String, Set(String))

fn parse(data: String) -> LAN {
  let add_link = fn(lan, node, neighbour) {
    dict.upsert(lan, node, fn(x) {
      case x {
        Some(n) -> n |> set.insert(neighbour)
        None -> set.new() |> set.insert(neighbour)
      }
    })
  }

  let assert Ok(re) = regexp.from_string("([a-z]+)-([a-z]+)")
  regexp.scan(re, data)
  |> list.fold(dict.new(), fn(lan, match) {
    let assert Match(_, [Some(a), Some(b)]) = match
    lan |> add_link(a, b) |> add_link(b, a)
  })
}

fn part1(lan: LAN) -> Int {
  lan
  |> dict.keys
  |> list.combinations(3)
  |> list.filter(fn(triad) {
    use <- bool.guard(!list.any(triad, string.starts_with(_, "t")), False)
    triad
    |> list.combination_pairs
    |> list.all(fn(pair) {
      let #(a, b) = pair
      let assert Ok(neighbours) = dict.get(lan, a)
      set.contains(neighbours, b)
    })
  })
  |> list.length
}

pub fn solve(data: String, _visualization: helper.Visualize) -> #(Int, Int) {
  let lan = parse(data)
  #(part1(lan), 0)
}
