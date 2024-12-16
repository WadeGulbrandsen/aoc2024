import gleam/dict
import gleam/list
import gleam/result
import gleam/string
import utils/grid.{type Grid, E, N, NE, NW, S, SE, SW, W}
import utils/helper

fn part1(puzzle: Grid(String)) -> Int {
  let directions = [N, S, E, W, NE, NW, SE, SW]
  puzzle.points
  |> dict.filter(fn(_, v) { v == "X" })
  |> dict.keys
  |> list.map(fn(xp) {
    list.map(directions, fn(d) {
      let mp = grid.move(xp, d, 1)
      let ap = grid.move(xp, d, 2)
      let sp = grid.move(xp, d, 3)
      case grid.get(puzzle, mp), grid.get(puzzle, ap), grid.get(puzzle, sp) {
        Ok("M"), Ok("A"), Ok("S") -> Ok([xp, mp, ap, sp])
        _, _, _ -> Error(Nil)
      }
    })
    |> result.values
  })
  |> list.flatten
  |> list.length
}

fn part2(puzzle: Grid(String)) -> Int {
  puzzle.points
  |> dict.filter(fn(_, v) { v == "A" })
  |> dict.keys
  |> list.filter(fn(ap) {
    case
      grid.get(puzzle, grid.move(ap, NE, 1)),
      grid.get(puzzle, grid.move(ap, SW, 1))
    {
      Ok("M"), Ok("S") | Ok("S"), Ok("M") -> {
        case
          grid.get(puzzle, grid.move(ap, NW, 1)),
          grid.get(puzzle, grid.move(ap, SE, 1))
        {
          Ok("M"), Ok("S") | Ok("S"), Ok("M") -> True
          _, _ -> False
        }
      }
      _, _ -> False
    }
  })
  |> list.length
}

pub fn solve(data: String, _visualize: helper.Visualize) -> #(Int, Int) {
  let puzzle = grid.from_string(data, string.to_graphemes, Ok)
  #(part1(puzzle), part2(puzzle))
}
