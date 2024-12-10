import gleam/dict
import gleam/int
import gleam/list
import gleam/set.{type Set}
import gleam/string
import utils/grid.{type Grid, type Point}

pub fn solve(data: String) -> #(Int, Int) {
  let map = grid.from_string(data, string.to_graphemes, int.parse)
  let trailheads =
    map.points
    |> dict.filter(fn(_, v) { v == 0 })
    |> dict.keys

  let part1 =
    trailheads
    |> list.map(list.wrap)
    |> list.map(score(_, map, set.new(), set.new()))
    |> int.sum

  let part2 =
    trailheads
    |> list.map(fn(p) { rate([[p]], map, set.new(), set.new()) })
    |> int.sum

  #(part1, part2)
}

fn rate(
  to_check: List(List(Point)),
  map: Grid(Int),
  seen: Set(List(Point)),
  complete: Set(List(Point)),
) -> Int {
  case to_check {
    [] -> set.size(complete)
    [[], ..rest] -> rate(rest, map, seen, complete)
    [[pos, ..] as path, ..rest] -> {
      case grid.get(map, pos), set.contains(seen, path) {
        Error(_), _ | _, True ->
          rate(rest, map, seen |> set.insert(path), complete)
        Ok(9), _ ->
          rate(
            rest,
            map,
            seen |> set.insert(path),
            complete |> set.insert(path),
          )
        Ok(h), _ -> {
          let seen = seen |> set.insert(path)
          let next_paths =
            get_next_positions(h + 1, pos, map)
            |> list.map(fn(p) { [p, ..path] })
            |> list.filter(fn(x) { !set.contains(seen, x) })
          rate(
            next_paths |> list.append(rest) |> list.unique,
            map,
            seen,
            complete,
          )
        }
      }
    }
  }
}

fn score(
  to_check: List(Point),
  map: Grid(Int),
  seen: Set(Point),
  nines: Set(Point),
) -> Int {
  case to_check {
    [] -> set.size(nines)
    [p, ..rest] -> {
      case grid.get(map, p), set.contains(seen, p) {
        Error(_), _ | _, True -> score(rest, map, seen |> set.insert(p), nines)
        Ok(9), _ ->
          score(rest, map, seen |> set.insert(p), nines |> set.insert(p))
        Ok(h), _ -> {
          let seen = seen |> set.insert(p)
          let next_positions =
            get_next_positions(h + 1, p, map)
            |> list.filter(fn(x) { !set.contains(seen, x) })
          score(
            next_positions |> list.append(rest) |> list.unique,
            map,
            seen,
            nines,
          )
        }
      }
    }
  }
}

fn get_next_positions(
  height: Int,
  current: Point,
  map: Grid(Int),
) -> List(Point) {
  [grid.N, grid.E, grid.S, grid.W]
  |> list.map(grid.move(current, _, 1))
  |> list.filter(fn(p) { grid.get(map, p) == Ok(height) })
}
