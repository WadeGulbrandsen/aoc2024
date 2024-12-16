import gleeunit/should
import solvers/day19
import utils/helper

pub fn solve_test() {
  day19.solve("", helper.Both)
  |> should.equal(#(0, 0))
}
