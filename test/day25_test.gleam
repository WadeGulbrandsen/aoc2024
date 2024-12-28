import gleeunit/should
import solvers/day25
import utils/helper

pub fn solve_test() {
  day25.solve(
    "#####
.####
.####
.####
.#.#.
.#...
.....

#####
##.##
.#.##
...##
...#.
...#.
.....

.....
#....
#....
#...#
#.#.#
#.###
#####

.....
.....
#.#..
###..
###.#
###.#
#####

.....
.....
.....
#....
#.#..
#.#.#
#####",
    helper.None,
  )
  |> should.equal(#(3, 50))
}
