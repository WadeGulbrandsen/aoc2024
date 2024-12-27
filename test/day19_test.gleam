import gleeunit/should
import solvers/day19
import utils/helper

pub fn solve_test() {
  day19.solve(
    "r, wr, b, g, bwu, rb, gb, br

brwrr
bggr
gbbr
rrbgbr
ubwu
bwurrg
brgr
bbrgwb",
    helper.None,
  )
  |> should.equal(#(6, 16))
}
