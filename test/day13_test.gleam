import gleeunit/should
import solvers/day13

pub fn solve_test() {
  day13.solve(
    "Button A: X+94, Y+34
Button B: X+22, Y+67
Prize: X=8400, Y=5400",
    False,
  )
  |> should.equal(#(280, 0))

  day13.solve(
    "Button A: X+26, Y+66
Button B: X+67, Y+21
Prize: X=12748, Y=12176",
    False,
  )
  |> should.equal(#(0, 459_236_326_669))

  day13.solve(
    "Button A: X+17, Y+86
Button B: X+84, Y+37
Prize: X=7870, Y=6450",
    False,
  )
  |> should.equal(#(200, 0))

  day13.solve(
    "Button A: X+69, Y+23
Button B: X+27, Y+71
Prize: X=18641, Y=10279",
    False,
  )
  |> should.equal(#(0, 416_082_282_239))

  day13.solve(
    "Button A: X+94, Y+34
Button B: X+22, Y+67
Prize: X=8400, Y=5400

Button A: X+26, Y+66
Button B: X+67, Y+21
Prize: X=12748, Y=12176

Button A: X+17, Y+86
Button B: X+84, Y+37
Prize: X=7870, Y=6450

Button A: X+69, Y+23
Button B: X+27, Y+71
Prize: X=18641, Y=10279",
    False,
  )
  |> should.equal(#(480, 875_318_608_908))
}
