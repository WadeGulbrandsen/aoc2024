import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/string

pub type Point {
  Point(x: Int, y: Int)
}

pub type Grid(a) {
  Grid(width: Int, height: Int, points: Dict(Point, a))
}

pub type Direction {
  N
  S
  E
  W
  NE
  NW
  SE
  SW
}

pub fn from_string(
  data data: String,
  row_split_function row_splitter: fn(String) -> List(a),
  parsing_function parser: fn(a) -> Result(b, Nil),
) -> Grid(b) {
  let split = data |> string.split("\n") |> list.map(row_splitter)
  let height = list.length(split)
  let width = split |> list.map(list.length) |> list.fold(0, int.max)
  let points =
    split
    |> list.index_fold(dict.new(), fn(grid, items, y) {
      items
      |> list.index_fold(grid, fn(grid, item, x) {
        case parser(item) {
          Ok(i) -> dict.insert(grid, Point(x, y), i)
          _ -> grid
        }
      })
    })
  Grid(width, height, points)
}

fn direction_to_point(dir: Direction) -> Point {
  case dir {
    N -> Point(0, -1)
    S -> Point(0, 1)
    E -> Point(1, 0)
    W -> Point(-1, 0)
    NE -> Point(1, -1)
    NW -> Point(-1, -1)
    SE -> Point(1, 1)
    SW -> Point(-1, 1)
  }
}

fn scale_direction(dir: Direction, factor: Int) -> Point {
  let direction = direction_to_point(dir)
  Point(direction.x * factor, direction.y * factor)
}

pub fn move(
  starting_point start: Point,
  direction dir: Direction,
  distance factor: Int,
) -> Point {
  add_points(start, scale_direction(dir, factor))
}

pub fn add_points(first_point a: Point, second_point b: Point) -> Point {
  Point(a.x + b.x, a.y + b.y)
}

pub fn get(grid grid: Grid(a), point point: Point) -> Result(a, Nil) {
  dict.get(grid.points, point)
}

pub fn remove(grid grid: Grid(a), point point: Point) -> Grid(a) {
  Grid(..grid, points: grid.points |> dict.delete(point))
}

pub fn insert(
  grid grid: Grid(a),
  point point: Point,
  value value: a,
) -> Result(Grid(a), Nil) {
  use <- bool.guard(!in_bounds(grid, point), Error(Nil))
  Ok(Grid(..grid, points: grid.points |> dict.insert(point, value)))
}

pub fn in_bounds(grid grid: Grid(a), point point: Point) -> Bool {
  point.x >= 0 && point.x < grid.width && point.y >= 0 && point.y < grid.height
}

pub fn filter(
  in grid: Grid(a),
  keeping predicate: fn(Point, a) -> Bool,
) -> Grid(a) {
  Grid(..grid, points: dict.filter(grid.points, predicate))
}

pub fn size(grid grid: Grid(a)) -> Int {
  grid.points |> dict.size
}

pub fn rotate_right(direction dir: Direction) -> Direction {
  case dir {
    N -> E
    E -> S
    S -> W
    W -> N
    NE -> SE
    SE -> SW
    SW -> NW
    NW -> NE
  }
}

pub fn rotate_left(direction dir: Direction) -> Direction {
  case dir {
    N -> W
    W -> S
    S -> E
    E -> N
    NE -> NW
    NW -> SW
    SW -> SE
    SE -> NE
  }
}
