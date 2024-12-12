import gleeunit/should
import solvers/day12

pub fn solve_test() {
  day12.solve(
    "AAAA
BBCD
BBCC
EEEC",
  )
  |> should.equal(#(140, 80))

  day12.solve(
    "OOOOO
OXOXO
OOOOO
OXOXO
OOOOO",
  )
  |> should.equal(#(772, 436))

  day12.solve(
    "RRRRIICCFF
RRRRIICCCF
VVRRRCCFFF
VVRCCCJFFF
VVVVCJJCFE
VVIVCCJJEE
VVIIICJJEE
MIIIIIJJEE
MIIISIJEEE
MMMISSJEEE",
  )
  |> should.equal(#(1930, 1206))

  day12.solve(
    "EEEEE
EXXXX
EEEEE
EXXXX
EEEEE",
  )
  |> should.equal(#(692, 236))

  day12.solve(
    "AAAAAA
AAABBA
AAABBA
ABBAAA
ABBAAA
AAAAAA",
  )
  |> should.equal(#(1184, 368))
}
