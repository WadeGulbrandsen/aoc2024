import gleam/dict
import gleam/int
import gleam/list
import gleam/set.{type Set}
import gleam/string
import utils/grid.{type Grid, type Point}

pub fn solve(data: String, _visualize: Bool) -> #(Int, Int) {
  let map = grid.from_string(data, string.to_graphemes, int.parse)

  let paths =
    map.points
    |> dict.filter(fn(_, v) { v == 0 })
    |> dict.keys
    |> list.map(fn(pos) { get_paths([[pos]], map, set.new(), set.new()) })
    |> list.fold(set.new(), set.union)

  let part1 =
    paths
    |> set.map(fn(path) { #(list.first(path), list.last(path)) })
    |> set.size

  #(part1, set.size(paths))
}

fn get_paths(
  to_check: List(List(Point)),
  map: Grid(Int),
  seen: Set(List(Point)),
  complete: Set(List(Point)),
) -> Set(List(Point)) {
  case to_check {
    [] -> complete
    [[], ..rest] -> get_paths(rest, map, seen, complete)
    [[pos, ..] as path, ..rest] -> {
      case grid.get(map, pos), set.contains(seen, path) {
        Error(_), _ | _, True ->
          get_paths(rest, map, seen |> set.insert(path), complete)
        Ok(9), _ ->
          get_paths(
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
          get_paths(
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

fn get_next_positions(
  height: Int,
  current: Point,
  map: Grid(Int),
) -> List(Point) {
  [grid.N, grid.E, grid.S, grid.W]
  |> list.map(grid.move(current, _, 1))
  |> list.filter(fn(p) { grid.get(map, p) == Ok(height) })
}
