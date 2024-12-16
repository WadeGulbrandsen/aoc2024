import gleeunit/should
import solvers/day17
import utils/helper

pub fn solve_test() {
  day17.solve("", helper.Both)
  |> should.equal(#(0, 0))
}
