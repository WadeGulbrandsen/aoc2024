import gleam/int
import gleam/list
import gleam/option
import gleam/regexp.{type Match, Match}
import gleam/result

type ClawMachine {
  ClawMachine(
    button_a_x: Int,
    button_a_y: Int,
    button_b_x: Int,
    button_b_y: Int,
    prize_x: Int,
    prize_y: Int,
  )
}

fn get_cost(cm: ClawMachine) -> Int {
  case cross_multiply(cm) {
    Error(_) -> 0
    Ok(#(a_times, b_times)) -> {
      let x = a_times * cm.button_a_x + b_times * cm.button_b_x
      let y = a_times * cm.button_a_y + b_times * cm.button_b_y
      case x == cm.prize_x && y == cm.prize_y {
        True -> a_times * 3 + b_times
        False -> 0
      }
    }
  }
}

fn cross_multiply(cm: ClawMachine) -> Result(#(Int, Int), Nil) {
  let ClawMachine(a1, a2, b1, b2, c1, c2) = cm
  let x_numerator = {
    b1 * -c2 - b2 * -c1
  }
  let x_denominator = {
    a1 * b2 - a2 * b1
  }
  let y_numerator = {
    -c1 * a2 - -c2 * a1
  }
  let y_denominator = {
    a1 * b2 - a2 * b1
  }
  case x_numerator % x_denominator, y_numerator % y_denominator {
    0, 0 -> Ok(#(x_numerator / x_denominator, y_numerator / y_denominator))
    _, _ -> Error(Nil)
  }
}

fn match_to_claw_machine(match: Match) -> Result(ClawMachine, Nil) {
  let Match(_, captured) = match
  case captured |> option.values |> list.map(int.parse) |> result.values {
    [a_x, a_y, b_x, b_y, p_x, p_y] ->
      Ok(ClawMachine(a_x, a_y, b_x, b_y, p_x, p_y))
    _ -> Error(Nil)
  }
}

fn correct_prize_location(cm: ClawMachine) -> ClawMachine {
  ClawMachine(
    ..cm,
    prize_x: cm.prize_x + 10_000_000_000_000,
    prize_y: cm.prize_y + 10_000_000_000_000,
  )
}

pub fn solve(data: String) -> #(Int, Int) {
  let assert Ok(re) =
    regexp.from_string(
      "Button A: X\\+(\\d+), Y\\+(\\d+)\\nButton B: X\\+(\\d+), Y\\+(\\d+)\\nPrize: X=(\\d+), Y=(\\d+)",
    )

  let claw_machines =
    regexp.scan(re, data)
    |> list.map(match_to_claw_machine)
    |> result.values

  let part1 = claw_machines |> list.map(get_cost) |> int.sum

  let part2 =
    claw_machines
    |> list.map(correct_prize_location)
    |> list.map(get_cost)
    |> int.sum

  #(part1, part2)
}
