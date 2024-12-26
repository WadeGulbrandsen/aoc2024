import gleeunit/should
import solvers/day21
import utils/helper

pub fn solve_test() {
  day21.solve(
    "029A
980A
179A
456A
379A",
    helper.Both,
  )
  |> should.equal(#(126_384, 0))
}
