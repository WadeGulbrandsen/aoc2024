import gleeunit/should
import solvers/day04
import utils/helper

pub fn solve_test() {
  day04.solve(
    "MMMSXXMASM
MSAMXMSMSA
AMXSXMAAMM
MSAMASMSMX
XMASAMXAMM
XXAMMXXAMA
SMSMSASXSS
SAXAMASAAA
MAMMMXMMMM
MXMXAXMASX",
    helper.None,
  )
  |> should.equal(#(18, 9))
}
