import gleam/pair
import gleeunit/should
import solvers/day17
import utils/helper

pub fn solve1_test() {
  day17.solve(
    "Register A: 729
Register B: 0
Register C: 0

Program: 0,1,5,4,3,0",
    helper.None,
  )
  |> pair.first
  |> should.equal(4_635_635_210)
}

pub fn solve3_test() {
  day17.solve(
    "Register A: 2024
Register B: 0
Register C: 0

Program: 0,1,5,4,3,0",
    helper.None,
  )
  |> pair.first
  |> should.equal(42_567_777_310)
}

pub fn solve_part2_test() {
  day17.solve(
    "Register A: 2024
Register B: 0
Register C: 0

Program: 0,3,5,4,3,0",
    helper.None,
  )
  |> pair.second
  |> should.equal(117_440)
}
