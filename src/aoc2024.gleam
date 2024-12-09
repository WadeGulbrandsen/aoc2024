import argv
import birl
import clip
import clip/help
import clip/opt
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import gleam_community/ansi
import humanise
import pprint
import solvers/day01
import solvers/day02
import solvers/day03
import solvers/day04
import solvers/day05
import solvers/day06
import solvers/day07
import solvers/day08
import solvers/day09
import utils/helper
import utils/markdown
import utils/puzzle.{type Answer, Answer}

const days = [
  #(1, day01.solve), #(2, day02.solve), #(3, day03.solve), #(4, day04.solve),
  #(5, day05.solve), #(6, day06.solve), #(7, day07.solve), #(8, day08.solve),
  #(9, day09.solve),
]

type Args {
  Day(day: Result(Int, Nil))
}

fn day() {
  opt.new("day")
  |> opt.help("Which day should be run: 1-25")
  |> opt.try_map(fn(v) {
    case int.parse(v) {
      Ok(x) if x >= 1 && x <= 25 -> Ok(x)
      _ -> Error("day must be a number between 1 and 25")
    }
  })
  |> opt.optional
}

fn command() {
  clip.command({
    use day <- clip.parameter
    Day(day)
  })
  |> clip.opt(day())
}

fn timed(body: fn() -> a) -> #(Int, a) {
  let start = birl.monotonic_now()
  let value = body()
  let elapsed = birl.monotonic_now() - start
  #(elapsed, value)
}

fn do_day(
  day: Int,
  function: fn(String) -> #(Int, Int),
) -> Result(#(Int, #(Int, Int)), String) {
  case day |> puzzle.get_input {
    Ok(input) -> Ok(timed(fn() { function(input) }))
    Error(message) -> Error(message)
  }
}

fn result_emoji(goal: Int, answer: Int) -> String {
  case goal {
    0 -> "⚠️"
    g if answer < g -> "⬇️"
    g if answer > g -> "⬆️"
    _ -> "✔️"
  }
}

fn result_colour(goal: Int, answer: Int) -> fn(String) -> String {
  case goal {
    0 -> ansi.yellow
    g if g == answer -> ansi.green
    _ -> ansi.red
  }
}

fn print_day_result(
  result: Result(#(Int, #(Int, Int)), String),
  day: Int,
) -> Nil {
  case result {
    Error(e) -> e |> ansi.red |> io.println_error
    Ok(#(time, #(part1, part2))) -> {
      let answers = puzzle.get_answers()
      let saved = answers |> dict.get(day) |> result.unwrap(Answer(day, 0, 0))
      io.println("Results for Day " <> int.to_string(day))
      io.println(
        "Part 1: "
        <> int.to_string(part1) |> string.pad_start(10, " ")
        <> " "
        <> result_emoji(saved.part1, part1),
      )
      io.println(
        "Part 2: "
        <> int.to_string(part2) |> string.pad_start(10, " ")
        <> " "
        <> result_emoji(saved.part2, part2),
      )
      io.println(
        "Time  : "
        <> humanise.microseconds_int(time) |> string.pad_start(13, " "),
      )
      puzzle.update_answer(Answer(day, part1, part2), answers)
    }
  }
}

fn do_all_days(day_functions: Dict(Int, fn(String) -> #(Int, Int))) -> Nil {
  let answers = puzzle.get_answers()
  let headers =
    ["Day", "Part 1", "Part 2", "Time"]
    |> list.map(markdown.Cell(_, 1, ansi.reset))
  let widths = [3, 20, 20, 10]
  let coldefs = widths |> list.map(markdown.ColDef(_, markdown.Right))
  let results = day_functions |> dict.map_values(do_day)
  let rows =
    results
    |> dict.fold([], fn(rows, day, result) {
      let row = case result {
        Ok(#(time, #(part1, part2))) -> {
          let saved =
            answers |> dict.get(day) |> result.unwrap(Answer(day, 0, 0))
          let p1 = #(
            int.to_string(part1)
              <> " "
              <> result_emoji(saved.part1, part1)
              <> " ",
            result_colour(saved.part1, part1),
          )
          let p2 = #(
            int.to_string(part2)
              <> " "
              <> result_emoji(saved.part2, part2)
              <> " ",
            result_colour(saved.part2, part2),
          )
          [#(int.to_string(day), ansi.reset), p1, p2]
          |> list.map(fn(p) { markdown.Cell(p.0, 1, p.1) })
          |> list.append([
            markdown.Cell(humanise.microseconds_int(time), 1, ansi.reset),
          ])
        }
        Error(e) -> [
          markdown.Cell(int.to_string(day), 1, ansi.red),
          markdown.Cell(e, 3, ansi.red),
        ]
      }
      list.append(rows, [row])
    })

  let total_time =
    results
    |> dict.values
    |> result.values
    |> list.map(pair.first)
    |> int.sum

  let total_row = [
    markdown.Cell("TOTAL", 3, ansi.bright_blue),
    markdown.Cell(humanise.microseconds_int(total_time), 1, ansi.bright_blue),
  ]

  let delim_row =
    widths
    |> list.map(string.repeat("-", _))
    |> list.map(markdown.Cell(_, 1, ansi.blue))

  markdown.Table(headers, coldefs, list.append(rows, [delim_row, total_row]))
  |> markdown.table_to_string
  |> io.println
  Nil
}

pub fn main() {
  let result =
    command()
    |> clip.help(help.simple("aoc2024", "Solve Advent of Code 2024 puzzles"))
    |> clip.run(argv.load().arguments)
  case result {
    Error(e) -> io.println_error(e)
    Ok(args) -> {
      let day_functions = dict.from_list(days)
      case args.day {
        Error(Nil) -> do_all_days(day_functions)
        Ok(day) -> {
          day_functions
          |> dict.get(day)
          |> result.replace_error(
            "Day " <> int.to_string(day) <> " is not implemented yet.",
          )
          |> result.try(do_day(day, _))
          |> print_day_result(day)
        }
      }
    }
  }
}
