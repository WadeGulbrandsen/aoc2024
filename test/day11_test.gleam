import gleeunit/should
import solvers/day11

pub fn solve_test() {
  day11.solve("125 17", False)
  |> should.equal(#(55_312, 65_601_038_650_482))
}
