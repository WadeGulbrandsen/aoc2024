import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import utils/helper

type Gate {
  Gate(a: String, b: String, op: fn(Bool, Bool) -> Bool, out: String)
}

type Gates =
  Dict(String, Gate)

type Wires =
  Dict(String, Bool)

fn parse(data: String) -> #(Wires, Gates) {
  let assert Ok(#(wires, gates)) = data |> string.split_once("\n\n")
  let wires =
    wires
    |> string.split("\n")
    |> list.map(fn(str) {
      let assert Ok(#(wire, value)) = string.split_once(str, ": ")
      let value = case value {
        "1" -> True
        _ -> False
      }
      #(wire, value)
    })
    |> dict.from_list
  let gates =
    gates
    |> string.split("\n")
    |> list.map(fn(str) {
      let assert Ok(#(op, out)) = string.split_once(str, " -> ")
      let assert [a, op, b] = string.split(op, " ")
      let gate = case op {
        "AND" -> Gate(a, b, bool.and, out)
        "XOR" -> Gate(a, b, bool.exclusive_or, out)
        _ -> Gate(a, b, bool.or, out)
      }
      #(out, gate)
    })
    |> dict.from_list
  #(wires, gates)
}

fn part1(wires: Wires, gates: Gates) -> Int {
  let zs =
    gates
    |> dict.keys
    |> list.filter(string.starts_with(_, "z"))
    |> list.sort(string.compare)
    |> list.reverse
  let wires = eval(zs, wires, gates)
  zs
  |> list.map(dict.get(wires, _))
  |> result.values
  |> list.map(bool.to_int)
  |> int.undigits(2)
  |> result.unwrap(0)
}

fn eval(to_check: List(String), wires: Wires, gates: Gates) -> Wires {
  case to_check {
    [] -> wires
    [wire, ..rest] -> {
      let #(to_check, wires) = {
        use <- bool.guard(dict.has_key(wires, wire), #(rest, wires))
        let assert Ok(gate) = dict.get(gates, wire)
        case dict.get(wires, gate.a), dict.get(wires, gate.b) {
          Ok(a), Ok(b) -> #(rest, wires |> dict.insert(wire, gate.op(a, b)))
          Ok(_), _ -> #([gate.b, ..to_check], wires)
          _, Ok(_) -> #([gate.a, ..to_check], wires)
          _, _ -> #([gate.a, gate.b, ..to_check], wires)
        }
      }
      eval(to_check, wires, gates)
    }
  }
}

pub fn solve(data: String, _visualization: helper.Visualize) -> #(Int, Int) {
  let #(wires, gates) = parse(data)
  #(part1(wires, gates), 0)
}
