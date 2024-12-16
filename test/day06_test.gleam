import gleeunit/should
import solvers/day06
import utils/helper

pub fn solve_test() {
  day06.solve(
    "....#.....
.........#
..........
..#.......
.......#..
..........
.#..^.....
........#.
#.........
......#...",
    helper.None,
  )
  |> should.equal(#(41, 6))
}
