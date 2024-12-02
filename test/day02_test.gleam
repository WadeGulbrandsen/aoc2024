import gleeunit
import gleeunit/should
import solvers/day02

pub fn main() {
  gleeunit.main()
}

const sample = "7 6 4 2 1
1 2 7 8 9
9 7 6 2 1
1 3 2 4 5
8 6 4 4 1
1 3 6 7 9"

pub fn solve_test() {
  day02.solve(sample)
  |> should.equal(#(2, 4))
}
