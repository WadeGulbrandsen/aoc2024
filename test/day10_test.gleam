import gleeunit/should
import solvers/day10
import utils/helper

pub fn solve_test() {
  day10.solve(
    "89010123
78121874
87430965
96549874
45678903
32019012
01329801
10456732",
    helper.None,
  )
  |> should.equal(#(36, 81))
}
