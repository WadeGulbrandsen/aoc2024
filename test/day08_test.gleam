import gleeunit/should
import solvers/day08

pub fn solve_test() {
  day08.solve(
    "............
........0...
.....0......
.......0....
....0.......
......A.....
............
............
........A...
.........A..
............
............",
  )
  |> should.equal(#(14, 34))
}