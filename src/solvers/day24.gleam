import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/pair
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

fn is_x_y(gate: Gate) -> Bool {
  { string.starts_with(gate.a, "x") && string.starts_with(gate.b, "y") }
  || { string.starts_with(gate.a, "y") && string.starts_with(gate.b, "x") }
}

fn is_xor(gate: Gate) -> Bool {
  gate.op == bool.exclusive_or
}

fn match_to_z(to_check: List(String), gates: Gates) -> Result(String, Nil) {
  case to_check {
    [] -> Error(Nil)
    [out, ..rest] -> {
      let next =
        gates
        |> dict.values
        |> list.filter_map(fn(gate) {
          case gate.a == out || gate.b == out {
            True -> Ok(gate.out)
            False -> Error(Nil)
          }
        })
      case list.find(next, string.starts_with(_, "z")) {
        Ok(o) -> {
          let assert Ok(val) = o |> string.drop_start(1) |> int.parse
          Ok("z" <> int.to_string(val - 1) |> string.pad_start(2, "0"))
        }
        _ -> match_to_z(next |> list.append(rest), gates)
      }
    }
  }
}

fn swap_gates(gates: Gates, a: String, b: String) -> Gates {
  let assert Ok(a_gate) = dict.get(gates, a)
  let assert Ok(b_gate) = dict.get(gates, b)
  let a_gate = Gate(..a_gate, out: b)
  let b_gate = Gate(..b_gate, out: a)
  gates |> dict.insert(a, b_gate) |> dict.insert(b, a_gate)
}

fn part2(wires: Wires, gates: Gates, visualize: Bool) -> Int {
  let assert Ok(max_z) =
    gates
    |> dict.keys
    |> list.filter(string.starts_with(_, "z"))
    |> list.sort(order.reverse(string.compare))
    |> list.first

  let #(zs, others) =
    gates
    |> dict.filter(fn(output, gate) {
      case output |> string.starts_with("z") {
        True -> output != max_z && !is_xor(gate)
        False -> !is_x_y(gate) && is_xor(gate)
      }
    })
    |> dict.keys
    |> list.partition(string.starts_with(_, "z"))

  // exit early if running with test data
  use <- bool.guard(list.length(zs) != list.length(others), 0)

  let gates =
    others
    |> list.fold(gates, fn(gates, other) {
      case match_to_z([other], gates) {
        Error(_) -> gates
        Ok(z) -> gates |> swap_gates(other, z)
      }
    })

  let #(x, y) =
    wires
    |> dict.to_list
    |> list.partition(fn(wv) { string.starts_with(wv.0, "x") })
    |> helper.map_both(fn(l) {
      l
      |> list.sort(fn(a, b) { string.compare(a.0, b.0) })
      |> list.reverse
      |> list.map(pair.second)
      |> list.map(bool.to_int)
      |> int.undigits(2)
      |> result.unwrap(0)
    })

  let z = part1(wires, gates)

  let xor = int.bitwise_exclusive_or(x + y, z)

  let trailing_zeros =
    xor
    |> int.digits(2)
    |> result.unwrap([])
    |> list.count(fn(x) { x == 0 })
    |> int.to_string
    |> string.pad_start(2, "0")

  let bad_carry =
    gates
    |> dict.filter(fn(_, gate) {
      string.ends_with(gate.a, trailing_zeros)
      && string.ends_with(gate.b, trailing_zeros)
    })
    |> dict.keys

  let assert [a, b] = bad_carry

  let gates = gates |> swap_gates(a, b)

  let bad_gates =
    list.flatten([zs, others, bad_carry])
    |> list.sort(string.compare)
    |> string.join(",")

  let corrected = part1(wires, gates)

  case visualize {
    False -> Nil
    True -> {
      io.println_error(
        "\n        x: "
        <> int.to_base2(x) |> string.pad_start(46, " ")
        <> "\n        y: "
        <> int.to_base2(y) |> string.pad_start(46, " ")
        <> "\n      x+y: "
        <> int.to_base2(x + y) |> string.pad_start(46, " ")
        <> "\n        z: "
        <> int.to_base2(z) |> string.pad_start(46, " ")
        <> "\n      xor: "
        <> int.to_base2(xor) |> string.pad_start(46, " ")
        <> "\nxor zeros: "
        <> trailing_zeros |> string.pad_start(46, " ")
        <> "\nbad gates: "
        <> bad_gates |> string.pad_start(46, " ")
        <> "\ncorrected: "
        <> int.to_base2(corrected) |> string.pad_start(46, " ")
        <> "\nx + y = z: "
        <> int.to_string(x)
        <> " + "
        <> int.to_string(y)
        <> " = "
        <> int.to_string(corrected),
      )
    }
  }
  string.length(bad_gates)
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

pub fn solve(data: String, visualization: helper.Visualize) -> #(Int, Int) {
  let #(wires, gates) = parse(data)
  #(
    part1(wires, gates),
    part2(
      wires,
      gates,
      visualization == helper.Both || visualization == helper.Part2,
    ),
  )
}
