import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import utils/helper

type Computer {
  Computer(
    a: Int,
    b: Int,
    c: Int,
    ip: Int,
    program: Dict(Int, Int),
    output: List(Int),
  )
}

type Op {
  Adv
  Bxl
  Bst
  Jnz
  Bxc
  Out
  Bdv
  Cdv
  INVALID
}

fn get_op(opcode: Result(Int, Nil)) -> Op {
  case opcode {
    Ok(0) -> Adv
    Ok(1) -> Bxl
    Ok(2) -> Bst
    Ok(3) -> Jnz
    Ok(4) -> Bxc
    Ok(5) -> Out
    Ok(6) -> Bdv
    Ok(7) -> Cdv
    _ -> INVALID
  }
}

fn init(data: String) -> #(Computer, List(Int)) {
  let assert Ok(#(registers, program)) = data |> string.split_once("\n\n")
  let assert [a, b, c] =
    registers
    |> string.split("\n")
    |> list.map(fn(r) {
      r
      |> string.split_once(": ")
      |> result.map(pair.second)
      |> result.try(int.parse)
      |> result.unwrap(0)
    })
  let program =
    program
    |> string.split_once(": ")
    |> result.map(pair.second)
    |> result.map(string.split(_, ","))
    |> result.unwrap([])
    |> list.map(int.parse)
    |> result.values
  let stack =
    program
    |> list.index_fold(dict.new(), fn(d, v, k) { dict.insert(d, k, v) })
  #(Computer(a, b, c, 0, stack, []), program)
}

fn exec(computer: Computer) -> List(Int) {
  let op = dict.get(computer.program, computer.ip) |> get_op
  let operand = dict.get(computer.program, computer.ip + 1)
  // io.debug(#(computer, op, operand))
  use <- bool.guard(
    op == INVALID || operand |> result.is_error,
    computer.output |> list.reverse,
  )
  let assert Ok(operand) = operand
  let computer = case op {
    Adv -> Computer(..computer, a: div(operand, computer), ip: computer.ip + 2)
    Bxl ->
      Computer(
        ..computer,
        b: computer.b |> int.bitwise_exclusive_or(operand),
        ip: computer.ip + 2,
      )
    Bst ->
      Computer(
        ..computer,
        b: get_combo(operand, computer) % 8,
        ip: computer.ip + 2,
      )
    Jnz if computer.a != 0 -> Computer(..computer, ip: operand)
    Bxc ->
      Computer(
        ..computer,
        b: computer.b |> int.bitwise_exclusive_or(computer.c),
        ip: computer.ip + 2,
      )
    Out ->
      Computer(
        ..computer,
        output: [get_combo(operand, computer) % 8, ..computer.output],
        ip: computer.ip + 2,
      )
    Bdv -> Computer(..computer, b: div(operand, computer), ip: computer.ip + 2)
    Cdv -> Computer(..computer, c: div(operand, computer), ip: computer.ip + 2)
    _ -> Computer(..computer, ip: computer.ip + 2)
  }
  exec(computer)
}

fn div(operand: Int, computer: Computer) -> Int {
  let exp = get_combo(operand, computer)
  use <- bool.guard(exp < 1, computer.a)
  let denominator = 2 |> int.bitwise_shift_left(exp - 1)
  computer.a / denominator
}

fn get_combo(operand: Int, computer: Computer) -> Int {
  case operand {
    4 -> computer.a
    5 -> computer.b
    6 -> computer.c
    _ -> operand
  }
}

pub fn solve(data: String, visualization: helper.Visualize) -> #(Int, Int) {
  let #(computer, _program) = init(data)
  let output = computer |> exec
  case visualization {
    helper.Both | helper.Part1 ->
      io.println_error(
        "Part 1: " |> helper.unnamed_blue
        <> output
        |> list.map(int.to_string)
        |> string.join(",")
        |> helper.faff_pink,
      )
    _ -> Nil
  }
  let assert Ok(part1) = output |> int.undigits(10)

  #(part1, 0)
}
