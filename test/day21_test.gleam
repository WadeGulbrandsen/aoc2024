import gleeunit/should
import solvers/day21
import utils/helper

pub fn solve_test() {
  day21.solve("", helper.Both)
  |> should.equal(#(0, 0))
}
