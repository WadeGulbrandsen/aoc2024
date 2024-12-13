import gleam/bool
import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pair
import gleam/set.{type Set}
import gleam/string
import utils/grid.{type Direction, type Grid, type Point, E, N, S, W}
import utils/helper

const directions = [N, E, S, W]

type Region {
  Region(plant: String, inside: Set(Point), outside: List(Point))
}

fn new_region(plant: String) {
  Region(plant, set.new(), [])
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
            outside: outside |> list.append(region.outside),
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

fn get_sides(region: Region) -> Int {
  region.outside
  |> list.unique
  |> list.flat_map(fn(p) {
    directions
    |> list.filter_map(fn(d) {
      let point = grid.move(p, d, 1)
      case region.inside |> set.contains(point) {
        True -> Ok(#(d, point))
        False -> Error(Nil)
      }
    })
  })
  |> list.group(pair.first)
  |> dict.map_values(get_fences)
  |> dict.values
  |> list.flatten
  |> list.length
}

fn split_fences(
  values: List(Int),
  last: Option(Int),
  current: List(Int),
  acc: List(List(Int)),
) -> List(List(Int)) {
  case values {
    [] -> [current, ..acc]
    [x, ..rest] -> {
      let #(current, acc) = case last {
        Some(l) if x != l + 1 -> #([x], [current, ..acc])
        _ -> #([x, ..current], acc)
      }
      split_fences(rest, Some(x), current, acc)
    }
  }
}

fn get_fences(
  direction: Direction,
  points: List(#(Direction, Point)),
) -> List(List(Int)) {
  let #(group_fn, extractor) = case grid.is_verticle(direction) {
    True -> #(grid.point_y, grid.point_x)
    False -> #(grid.point_x, grid.point_y)
  }

  let extract_fn = fn(_, list: List(Point)) -> List(List(Int)) {
    list
    |> list.map(extractor)
    |> list.sort(int.compare)
    |> split_fences(None, [], [])
  }

  points
  |> list.map(pair.second)
  |> list.group(group_fn)
  |> dict.map_values(extract_fn)
  |> dict.values
  |> list.flatten
}

pub fn solve(data: String) -> #(Int, Int) {
  let garden = grid.from_string(data, string.to_graphemes, Ok)
  garden.points
  |> dict.to_list
  |> get_regions(garden, [], set.new())
  |> list.reverse
  |> list.map(fn(r) {
    let area = r.inside |> set.size
    let perimeter = r.outside |> list.length
    let sides = get_sides(r)
    #(area * perimeter, area * sides)
  })
  |> list.unzip
  |> helper.map_both(int.sum)
}
