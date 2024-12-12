import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/set.{type Set}
import gleam/string
import utils/grid.{type Grid, type Point, E, N, S, W}

type Region {
  Region(plant: String, inside: Set(Point), perimeter: Int, sides: Int)
}

fn new_region(plant: String) {
  Region(plant, set.new(), 0, 0)
}

fn get_regions(
  to_check: List(#(Point, String)),
  garden: Grid(String),
  regions: List(Region),
  seen: Set(Point),
) -> List(Region) {
  case to_check {
    [] -> regions
    [#(point, plant), ..rest] -> {
      let #(to_check, regions, seen) = {
        use <- bool.guard(seen |> set.contains(point), #(rest, regions, seen))
        let region = get_region([point], garden, new_region(plant), set.new())
        let to_check =
          rest |> list.filter(fn(p) { !set.contains(region.inside, p.0) })
        let seen = seen |> set.union(region.inside)
        #(to_check, [region, ..regions], seen)
      }
      get_regions(to_check, garden, regions, seen)
    }
  }
}

fn get_region(
  to_check: List(Point),
  garden: Grid(String),
  region: Region,
  seen: Set(Point),
) -> Region {
  let directions = [N, W, E, S]
  case to_check {
    [] -> region
    [p, ..rest] -> {
      let #(region, next) = {
        use <- bool.guard(set.contains(seen, p), #(region, rest))
        let #(inside, outside) =
          directions
          |> list.map(grid.move(p, _, 1))
          |> list.partition(fn(np) { grid.get(garden, np) == Ok(region.plant) })
        let region =
          Region(
            ..region,
            inside: region.inside |> set.insert(p),
            perimeter: region.perimeter + list.length(outside),
          )
        #(
          region,
          inside
            |> list.append(rest)
            |> list.unique
            |> list.filter(fn(x) { !set.contains(seen, x) }),
        )
      }
      let seen = seen |> set.insert(p)
      get_region(next, garden, region, seen)
    }
  }
}

pub fn solve(data: String) -> #(Int, Int) {
  let garden = grid.from_string(data, string.to_graphemes, Ok)
  let regions =
    get_regions(garden.points |> dict.to_list, garden, [], set.new())
  let #(part1, part2) =
    regions
    |> list.fold(#(0, 0), fn(totals, r) {
      let area = r.inside |> set.size
      #(area * r.perimeter + totals.0, area * r.sides + totals.1)
    })

  #(part1, part2)
}
