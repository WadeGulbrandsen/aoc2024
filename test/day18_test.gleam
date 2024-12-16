import gleeunit/should
import solvers/day18
import utils/helper

pub fn solve_test() {
  day18.solve("", helper.Both)
  |> should.equal(#(0, 0))
}
