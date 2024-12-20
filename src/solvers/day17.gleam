import gary.{type ErlangArray as Array}
import gary/array
import gleam/bool
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
    program: Array(Int),
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

fn get_op(opcode: Int) -> Op {
  case opcode {
    0 -> Adv
    1 -> Bxl
    2 -> Bst
    3 -> Jnz
    4 -> Bxc
    5 -> Out
    6 -> Bdv
    7 -> Cdv
    _ -> INVALID
  }
}

fn init(data: String) -> Computer {
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
    |> array.from_list(-1)
    |> array.make_fixed
  Computer(a, b, c, 0, program, [])
}

fn exec(computer: Computer) -> List(Int) {
  let op =
    array.get(computer.program, computer.ip) |> result.unwrap(-1) |> get_op
  let operand = array.get(computer.program, computer.ip + 1)

  use <- bool.guard(
    op == INVALID || operand |> result.is_error,
    computer.output |> list.reverse,
  )
  let assert Ok(operand) = operand
  let combo = get_combo(operand, computer)
  let computer = case op {
    Adv ->
      Computer(
        ..computer,
        a: int.bitwise_shift_right(computer.a, combo),
        ip: computer.ip + 2,
      )
    Bxl ->
      Computer(
        ..computer,
        b: computer.b |> int.bitwise_exclusive_or(operand),
        ip: computer.ip + 2,
      )
    Bst -> Computer(..computer, b: combo % 8, ip: computer.ip + 2)
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
        output: [combo % 8, ..computer.output],
        ip: computer.ip + 2,
      )
    Bdv ->
      Computer(
        ..computer,
        b: int.bitwise_shift_right(computer.a, combo),
        ip: computer.ip + 2,
      )
    Cdv ->
      Computer(
        ..computer,
        c: int.bitwise_shift_right(computer.a, combo),
        ip: computer.ip + 2,
      )
    _ -> Computer(..computer, ip: computer.ip + 2)
  }
  exec(computer)
}

fn get_combo(operand: Int, computer: Computer) -> Int {
  case operand {
    4 -> computer.a
    5 -> computer.b
    6 -> computer.c
    _ -> operand
  }
}

fn find_quines(
  program: Array(Int),
  length: Int,
  short_program: Array(Int),
  to_check: List(#(Int, Int)),
  quines: List(Int),
) -> List(Int) {
  case to_check {
    [] -> quines
    [#(q, r), ..rest] -> {
      let #(to_check, quines) = case q < length {
        True -> {
          let digit = array.get(program, length - q) |> result.unwrap(-1)
          let next =
            list.range(0, 7)
            |> list.filter_map(fn(a) {
              let n = int.bitwise_shift_left(r, 3) + a
              let v = Computer(n, 0, 0, 0, short_program, []) |> exec
              case v == [digit] {
                True -> {
                  Ok(#(q + 1, n))
                }
                False -> Error(Nil)
              }
            })
          #(list.append(rest, next), quines)
        }
        False ->
          case
            Computer(r, 0, 0, 0, program, []) |> exec
            == program |> array.to_list
          {
            True -> #(to_check, [r, ..quines])
            False -> #(to_check, quines)
          }
      }
      find_quines(program, length, short_program, to_check, quines)
    }
  }
}

fn reverse_engineer(
  rev_program: List(Int),
  to_check: List(Int),
  runner: fn(Int) -> List(Int),
) -> Int {
  case rev_program {
    [] -> list.reduce(to_check, int.min) |> result.unwrap(0)
    [digit, ..rest] -> {
      let next =
        to_check
        |> list.flat_map(fn(a) {
          let shifted = int.bitwise_shift_left(a, 3)
          list.range(shifted, shifted + 7)
          |> list.filter_map(fn(a) {
            let output = runner(a)
            case list.first(output) {
              Ok(x) if x == digit -> Ok(a)
              _ -> Error(Nil)
            }
          })
        })
      reverse_engineer(rest, next, runner)
    }
  }
}

fn part2(computer: Computer) -> Int {
  let program = computer.program |> array.to_list
  let length = array.get_size(computer.program)
  let #(_beginning, last) = list.split(program, length - 2)
  use <- bool.guard(last != [3, 0], 0)
  let runner = fn(a) { exec(Computer(a, 0, 0, 0, computer.program, [])) }
  reverse_engineer(program |> list.reverse, [0], runner)
}

fn part1(computer: Computer, visualization: helper.Visualize) -> Int {
  let output = computer |> exec
  case visualization {
    helper.Both | helper.Part1 ->
      io.println_error(
        "Part 1 with commas: " |> helper.unnamed_blue
        <> output
        |> list.map(int.to_string)
        |> string.join(",")
        |> helper.faff_pink,
      )
    _ -> Nil
  }
  let assert Ok(part1) = output |> int.undigits(10)
  part1
}

pub fn solve(data: String, visualization: helper.Visualize) -> #(Int, Int) {
  let computer = init(data)
  #(part1(computer, visualization), part2(computer))
}
