import gleeunit/should
import solvers/day20
import utils/helper

pub fn solve_test() {
  day20.solve("", helper.Both)
  |> should.equal(#(0, 0))
}
