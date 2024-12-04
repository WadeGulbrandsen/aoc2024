import gleeunit
import gleeunit/should
import solvers/day04

pub fn main() {
  gleeunit.main()
}

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
  )
  |> should.equal(#(18, 9))
}
