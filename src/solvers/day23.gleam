import gleam/dict.{type Dict}
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/regexp.{Match}
import gleam/set.{type Set}
import gleam/string
import utils/helper

type LAN =
  Dict(String, Set(String))

fn is_linked(c1: String, c2: String, lan: LAN) -> Bool {
  let assert Ok(c1_neighbours) = dict.get(lan, c1)
  c1_neighbours |> set.contains(c2)
}

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
  |> list.filter(string.starts_with(_, "t"))
  |> list.fold(set.new(), fn(networks, c1) {
    let assert Ok(c1_neighbours) = dict.get(lan, c1)
    c1_neighbours
    |> set.fold(networks, fn(networks, c2) {
      let assert Ok(c2_neighbours) = dict.get(lan, c2)
      c2_neighbours
      |> set.delete(c1)
      |> set.fold(networks, fn(networks, c3) {
        case is_linked(c1, c3, lan) {
          True -> networks |> set.insert([c1, c2, c3] |> set.from_list)
          False -> networks
        }
      })
    })
  })
  |> set.size
}

fn is_valid_network(computer: String, network: Set(String), lan: LAN) -> Bool {
  let assert Ok(neighbours) = dict.get(lan, computer)
  network
  |> set.to_list
  |> list.all(set.contains(neighbours, _))
}

fn get_largest_network(
  computers: List(String),
  lan: LAN,
  network: Set(String),
) -> Set(String) {
  case computers {
    [] -> network
    [computer, ..rest] -> {
      let without = get_largest_network(rest, lan, network)
      let next = network |> set.insert(computer)
      case is_valid_network(computer, network, lan) {
        False -> without
        True -> {
          let with = get_largest_network(rest, lan, next)
          case set.size(without) > set.size(with) {
            True -> without
            False -> with
          }
        }
      }
    }
  }
}

fn part2(lan: LAN, visualize: Bool) -> Int {
  let network = get_largest_network(lan |> dict.keys, lan, set.new())
  case visualize {
    False -> Nil
    True -> {
      let computers =
        network
        |> set.to_list
        |> list.sort(string.compare)
        |> string.join(",")
        |> helper.faff_pink
      io.println_error("Computers: " |> helper.unnamed_blue <> computers)
    }
  }
  network |> set.size
}

pub fn solve(data: String, visualization: helper.Visualize) -> #(Int, Int) {
  let lan = parse(data)
  #(
    part1(lan),
    part2(lan, visualization == helper.Both || visualization == helper.Part2),
  )
}
