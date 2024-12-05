import gleeunit/should
import solvers/day01

const sample = "3   4
4   3
2   5
1   3
3   9
3   3"

pub fn part1_test() {
  day01.part1(sample)
  |> should.equal(11)
}

pub fn part2_test() {
  day01.part2(sample)
  |> should.equal(31)
}
