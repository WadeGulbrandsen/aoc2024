import gleam/dict.{type Dict}
import gleam/list
import gleam/result
import gleam/string

const u = #(-1, 0)

const d = #(1, 0)

const l = #(0, -1)

const r = #(0, 1)

const ul = #(-1, -1)

const ur = #(-1, 1)

const dl = #(1, -1)

const dr = #(1, 1)

type Point =
  #(Int, Int)

type Grid =
  Dict(Point, String)

fn add(a: Point, b: Point) -> Point {
  #(a.0 + b.0, a.1 + b.1)
}

fn part1(puzzle: Grid) -> Int {
  let directions = [u, d, l, r, ul, ur, dl, dr]
  puzzle
  |> dict.filter(fn(_, v) { v == "X" })
  |> dict.keys
  |> list.map(fn(xp) {
    list.map(directions, fn(d) {
      let mp = add(xp, d)
      let ap = add(mp, d)
      let sp = add(ap, d)
      case dict.get(puzzle, mp), dict.get(puzzle, ap), dict.get(puzzle, sp) {
        Ok("M"), Ok("A"), Ok("S") -> Ok([xp, mp, ap, sp])
        _, _, _ -> Error(Nil)
      }
    })
    |> result.values
  })
  |> list.flatten
  |> list.length
}

fn part2(puzzle: Grid) -> Int {
  puzzle
  |> dict.filter(fn(_, v) { v == "A" })
  |> dict.keys
  |> list.filter(fn(ap) {
    case dict.get(puzzle, add(ap, ul)), dict.get(puzzle, add(ap, dr)) {
      Ok("M"), Ok("S") | Ok("S"), Ok("M") -> {
        case dict.get(puzzle, add(ap, ur)), dict.get(puzzle, add(ap, dl)) {
          Ok("M"), Ok("S") | Ok("S"), Ok("M") -> True
          _, _ -> False
        }
      }
      _, _ -> False
    }
  })
  |> list.length
}

fn to_grid(data: String) -> Grid {
  data
  |> string.split("\n")
  |> list.map(string.to_graphemes)
  |> list.index_fold(dict.new(), fn(grid, letters, row) {
    letters
    |> list.index_fold(grid, fn(grid, letter, col) {
      dict.insert(grid, #(row, col), letter)
    })
  })
}

pub fn solve(data: String) -> #(Int, Int) {
  let puzzle = to_grid(data)
  #(part1(puzzle), part2(puzzle))
}
