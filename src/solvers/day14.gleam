import gleam/dict
import gleam/function
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/regexp.{type Match, Match}
import gleam/result
import gleam/set
import gleam/string
import gleam_community/ansi
import utils/grid.{type Point, Point}
import utils/helper

const debug = False

type Robot {
  Robot(px: Int, py: Int, vx: Int, vy: Int)
}

fn move(robot: Robot, width: Int, height: Int, seconds: Int) -> Robot {
  let assert Ok(x) = robot.px + robot.vx * seconds |> int.modulo(width)
  let assert Ok(y) = robot.py + robot.vy * seconds |> int.modulo(height)
  Robot(..robot, px: x, py: y)
}

fn quadrant(robot: Robot, width: Int, height: Int) -> Result(Int, Nil) {
  let mid_x = width / 2
  let mid_y = height / 2
  case robot.px < mid_x, robot.px > mid_x, robot.py < mid_y, robot.py > mid_y {
    True, False, True, False -> Ok(1)
    False, True, True, False -> Ok(2)
    True, False, False, True -> Ok(3)
    False, True, False, True -> Ok(4)
    _, _, _, _ -> Error(Nil)
  }
}

fn safety_score(robots: List(Robot), width: Int, height: Int) -> Int {
  robots
  |> list.map(quadrant(_, width, height))
  |> result.values
  |> list.group(function.identity)
  |> dict.values
  |> list.map(list.length)
  |> int.product
}

fn match_to_robot(match: Match) -> Result(Robot, Nil) {
  let Match(_, captured) = match
  case captured |> option.values |> list.map(int.parse) |> result.values {
    [px, py, vx, vy] -> Ok(Robot(px, py, vx, vy))
    _ -> Error(Nil)
  }
}

fn robot_to_point(robot: Robot) -> Point {
  Point(robot.px, robot.py)
}

fn robots_to_string(robots: List(Robot), width: Int, height: Int) -> String {
  let points = robots |> list.map(robot_to_point) |> set.from_list
  list.range(0, height - 1)
  |> list.map(fn(y) {
    list.range(0, width - 1)
    |> list.map(fn(x) {
      case set.contains(points, Point(x, y)) {
        True -> "X" |> ansi.bright_green
        False -> "."
      }
    })
    |> string.concat
    |> helper.bg_black
  })
  |> string.join("\n")
}

fn robots_debug(robots: List(Robot), width: Int, height: Int) -> List(Robot) {
  io.println_error("\n" <> robots_to_string(robots, width, height) <> "\n")
  robots
}

pub fn solver(
  data: String,
  width: Int,
  height: Int,
  _visualize: helper.Visualize,
) -> #(Int, Int) {
  let assert Ok(re) =
    regexp.from_string("p=(-?\\d+),(-?\\d+) v=(-?\\d+),(-?\\d+)")
  let robots =
    regexp.scan(re, data)
    |> list.map(match_to_robot)
    |> result.values

  let part1 =
    robots
    |> list.map(move(_, width, height, 100))
    |> safety_score(width, height)

  let robot_count = list.length(robots)

  let part2 =
    list.range(1, width * height)
    |> list.find_map(fn(i) {
      let r = robots |> list.map(move(_, width, height, i))
      let unique_points =
        r |> list.map(robot_to_point) |> set.from_list |> set.size
      case robot_count == unique_points {
        True -> {
          let _ = case debug {
            True -> robots_debug(r, width, height)
            False -> r
          }
          Ok(i)
        }
        False -> Error(Nil)
      }
    })
    |> result.unwrap(0)

  #(part1, part2)
}

pub fn solve(data: String, visualize: helper.Visualize) -> #(Int, Int) {
  solver(data, 101, 103, visualize)
}
