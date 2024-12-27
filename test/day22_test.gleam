import gleeunit/should
import solvers/day22
import utils/helper

pub fn solve_test() {
  day22.solve(
    "1
10
100
2024",
    helper.None,
  )
  |> should.equal(#(37_327_623, 24))
}

pub fn solve2_test() {
  day22.solve(
    "1
2
3
2024",
    helper.None,
  )
  |> should.equal(#(37_990_510, 23))
}
