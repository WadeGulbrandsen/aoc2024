import gleeunit/should
import solvers/day22
import utils/helper

pub fn solve_test() {
  day22.solve("", helper.Both)
  |> should.equal(#(0, 0))
}
