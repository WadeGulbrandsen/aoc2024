import argv
import clip
import clip/arg
import clip/help
import gleam/dict
import gleam/int
import gleam/io
import gleam/pair
import solvers/day01
import solvers/day02
import solvers/day03
import solvers/day04
import solvers/day05
import solvers/day06
import utils/puzzle

const days = [
  #(1, day01.solve), #(2, day02.solve), #(3, day03.solve), #(4, day04.solve),
  #(5, day05.solve), #(6, day06.solve),
]

type Args {
  Args(day: Int)
}

fn day() {
  arg.new("day")
  |> arg.help("Which day should be run: 1-25")
  |> arg.try_map(fn(v) {
    case int.parse(v) {
      Ok(x) if x >= 1 && x <= 25 -> Ok(x)
      _ -> Error("day must be a number between 1 and 25")
    }
  })
}

fn do_aoc(day: Int) -> Result(#(Int, Int), String) {
  let day_functions = dict.from_list(days)
  case dict.get(day_functions, day) {
    Ok(function) ->
      case day |> puzzle.get_input {
        Ok(input) -> Ok(function(input))
        Error(message) -> Error(message)
      }
    _ -> Error("Day " <> int.to_string(day) <> " has not been implented.")
  }
}

fn command() {
  clip.command({
    use day <- clip.parameter
    Args(day)
  })
  |> clip.arg(day())
}

pub fn main() {
  let result =
    command()
    |> clip.help(help.simple("aoc2024", "Solve an Advent of Code 2024 puzzles"))
    |> clip.run(argv.load().arguments)
  case result {
    Error(e) -> io.println_error(e)
    Ok(args) ->
      case do_aoc(args.day) {
        Error(e) -> io.println_error(e)
        Ok(results) -> {
          io.println("Results for Day " <> int.to_string(args.day))
          io.println("Part 1: " <> int.to_string(pair.first(results)))
          io.println("Part 2: " <> int.to_string(pair.second(results)))
        }
      }
  }
}
