import gleeunit/should
import solvers/day24
import utils/helper

pub fn solve_test() {
  day24.solve("", helper.Both)
  |> should.equal(#(0, 0))
}
