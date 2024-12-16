import gleeunit/should
import solvers/day23
import utils/helper

pub fn solve_test() {
  day23.solve("", helper.Both)
  |> should.equal(#(0, 0))
}
