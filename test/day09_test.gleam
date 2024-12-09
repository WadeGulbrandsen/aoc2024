import gleeunit/should
import solvers/day09

pub fn solve_test() {
  day09.solve("2333133121414131402")
  |> should.equal(#(1928, 2858))
}
