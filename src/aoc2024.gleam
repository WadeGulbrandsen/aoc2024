import argv
import birl
import clip
import clip/arg
import clip/help
import gleam/dict
import gleam/function
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import gleam/yielder
import gleam_community/ansi
import glitzer/progress
import glitzer/spinner
import humanise
import simplifile
import solvers/day01
import solvers/day02
import solvers/day03
import solvers/day04
import solvers/day05
import solvers/day06
import solvers/day07
import solvers/day08
import solvers/day09
import solvers/day10
import utils/helper
import utils/puzzle.{type Answer, Answer}
import utils/table

const days = [
  #(1, day01.solve), #(2, day02.solve), #(3, day03.solve), #(4, day04.solve),
  #(5, day05.solve), #(6, day06.solve), #(7, day07.solve), #(8, day08.solve),
  #(9, day09.solve), #(10, day10.solve),
]

type Args {
  Day(day: Int)
  All
  SaveMD
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

fn day_command() {
  clip.command({
    use day <- clip.parameter
    Day(day)
  })
  |> clip.arg(day())
  |> clip.help(help.simple("aoc2024 day", "Runs the specified day"))
}

fn all_command() {
  clip.return(All) |> clip.help(help.simple("aoc2024 all", "Runs all days"))
}

fn save_md_command() {
  clip.return(SaveMD)
  |> clip.help(help.simple("aoc2024 save", "Saves times to a markdown"))
}

fn command() {
  clip.subcommands_with_default(
    [
      #("day", day_command()),
      #("all", all_command()),
      #("save", save_md_command()),
    ],
    all_command(),
  )
}

fn timed(body: fn() -> a) -> #(Int, a) {
  let start = birl.monotonic_now()
  let value = body()
  let elapsed = birl.monotonic_now() - start
  #(elapsed, value)
}

fn evaluate_day(
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
    0 -> helper.aged_plastic_yellow
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
      io.println(helper.unnamed_blue("Results for Day " <> int.to_string(day)))
      io.println(
        "Part 1: " |> helper.aged_plastic_yellow
        <> int.to_string(part1)
        |> string.pad_start(10, " ")
        |> result_colour(saved.part1, part1)
        <> " "
        <> result_emoji(saved.part1, part1),
      )
      io.println(
        "Part 2: " |> helper.aged_plastic_yellow
        <> int.to_string(part2)
        |> string.pad_start(10, " ")
        |> result_colour(saved.part2, part2)
        <> " "
        <> result_emoji(saved.part2, part2),
      )
      io.println(
        "Time  : " |> helper.faff_pink
        <> humanise.microseconds_int(time)
        |> string.pad_start(13, " ")
        |> helper.faff_pink,
      )
      puzzle.update_answer(Answer(day, part1, part2), answers)
    }
  }
}

fn run_days(first: Int, last: Int) {
  let filtered =
    dict.from_list(days)
    |> dict.filter(fn(d, _) { d >= first && d <= last })
  let bar =
    progress.fancy_thick_bar()
    |> progress.with_length(dict.size(filtered))
    |> progress.with_left_text(helper.faff_pink("["))
  let results =
    filtered
    |> dict.to_list
    |> yielder.from_list
    |> progress.map_yielder(bar, fn(bar, p) {
      bar
      |> progress.with_right_text(helper.faff_pink(
        "] Evaluating day " <> string.pad_start(int.to_string(p.0), 2, "0"),
      ))
      |> progress.print_bar
      #(p.0, evaluate_day(p.0, p.1))
    })
    |> yielder.to_list
    |> dict.from_list

  bar
  |> progress.with_right_text("] Done!\n" |> helper.faff_pink)
  |> progress.finish
  |> progress.print_bar
  results
}

fn save_md() {
  let results = run_days(1, 25)
  let headers = ["Day", "Time"] |> list.map(table.Cell(_, 1, function.identity))
  let coldefs = [
    5 |> table.ColDef(table.Right),
    60 |> table.ColDef(table.Right),
  ]
  let rows =
    results
    |> dict.fold([], fn(rows, day, result) {
      let value = case result {
        Ok(#(time, _)) -> humanise.microseconds_int(time)
        Error(e) -> e
      }
      [int.to_string(day), value]
      |> list.map(table.Cell(_, 1, function.identity))
      |> list.wrap
      |> list.append(rows, _)
    })

  let total_time =
    results
    |> dict.values
    |> result.values
    |> list.map(pair.first)
    |> int.sum

  let total_row = [
    table.Cell("TOTAL", 1, function.identity),
    table.Cell(humanise.microseconds_int(total_time), 1, function.identity),
  ]

  let table =
    table.Table(headers, coldefs, list.append(rows, [total_row]))
    |> table.table_to_markdown

  io.println("Saving times...")
  let md =
    [
      "# Run times",
      "Run at "
        <> birl.utc_now() |> birl.to_iso8601
        <> " using "
        <> int.to_string(helper.get_thread_count())
        <> " threads.",
      table,
    ]
    |> string.join("\n\n")
  let md_path = "./Times.md"
  case simplifile.write(md_path, md) {
    Ok(Nil) -> io.println("Done!")
    Error(_) -> io.println_error("Could not write " <> md_path)
  }
}

fn do_all_days() {
  let results = run_days(1, 25)
  let answers = puzzle.get_answers()
  let headers =
    ["Day", "Part 1", "Part 2", "Time"]
    |> list.map(table.Cell(_, 1, helper.white))
  let widths = [3, 25, 25, 10]
  let coldefs = widths |> list.map(table.ColDef(_, table.Right))
  let rows =
    results
    |> dict.fold([], fn(rows, day, result) {
      let row = case result {
        Ok(#(time, #(part1, part2))) -> {
          let saved =
            answers |> dict.get(day) |> result.unwrap(Answer(day, 0, 0))
          let p1 = #(
            helper.int_to_string_with_commas(part1)
              <> " "
              <> result_emoji(saved.part1, part1)
              <> " ",
            result_colour(saved.part1, part1),
          )
          let p2 = #(
            helper.int_to_string_with_commas(part2)
              <> " "
              <> result_emoji(saved.part2, part2)
              <> " ",
            result_colour(saved.part2, part2),
          )
          [#(int.to_string(day), helper.aged_plastic_yellow), p1, p2]
          |> list.map(fn(p) { table.Cell(p.0, 1, p.1) })
          |> list.append([
            table.Cell(
              humanise.microseconds_int(time),
              1,
              helper.aged_plastic_yellow,
            ),
          ])
        }
        Error(e) -> [
          table.Cell(int.to_string(day), 1, ansi.red),
          table.Cell(e, 3, ansi.red),
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
    table.Cell("TOTAL", 3, helper.unnamed_blue),
    table.Cell(humanise.microseconds_int(total_time), 1, helper.unnamed_blue),
  ]

  table.Table(headers, coldefs, list.append(rows, [total_row]))
  |> table.table_to_string(
    table.rounded_boarder(),
    helper.faff_pink,
    helper.bg_underwater_blue,
  )
  |> io.println
}

fn do_day(day: Int) {
  let s =
    spinner.spinning_spinner()
    |> spinner.with_left_text(helper.faff_pink(
      "Evaluating day " <> int.to_string(day) <> " ",
    ))
    |> spinner.with_finish_text(helper.faff_pink(
      "Done evaluating day " <> int.to_string(day) <> "\n",
    ))
    |> spinner.spin

  let result =
    dict.from_list(days)
    |> dict.get(day)
    |> result.replace_error(
      "Day " <> int.to_string(day) <> " is not implemented yet.",
    )
    |> result.try(evaluate_day(day, _))

  spinner.finish(s)

  result |> print_day_result(day)
}

pub fn main() {
  let result =
    command()
    |> clip.help(help.simple("aoc2024", "Solve Advent of Code 2024 puzzles"))
    |> clip.run(argv.load().arguments)
  case result {
    Error(e) -> io.println_error(e)
    Ok(All) -> do_all_days()
    Ok(Day(day)) -> do_day(day)
    Ok(SaveMD) -> save_md()
  }
}
