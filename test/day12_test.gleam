import gleeunit/should
import solvers/day12

pub fn solve_test() {
  day12.solve(
    "AAAA
BBCD
BBCC
EEEC",
    False,
  )
  |> should.equal(#(140, 80))

  day12.solve(
    "OOOOO
OXOXO
OOOOO
OXOXO
OOOOO",
    False,
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
    False,
  )
  |> should.equal(#(1930, 1206))

  day12.solve(
    "EEEEE
EXXXX
EEEEE
EXXXX
EEEEE",
    False,
  )
  |> should.equal(#(692, 236))

  day12.solve(
    "AAAAAA
AAABBA
AAABBA
ABBAAA
ABBAAA
AAAAAA",
    False,
  )
  |> should.equal(#(1184, 368))
}
