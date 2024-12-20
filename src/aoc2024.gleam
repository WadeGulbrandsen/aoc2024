import argv
import clip
import clip/arg
import clip/flag
import clip/help
import clip/opt
import gleam/bool
import gleam/dict.{type Dict}
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
import simplifile
import tempo.{type Duration}
import tempo/datetime
import tempo/duration
import utils/helper.{type Visualize, Both, None, Part1, Part2}
import utils/puzzle.{type Answer, Answer}
import utils/table

type Args {
  Day(day: Int, skip: Bool, visualize: Visualize)
  All
  SaveMD
}

fn day() {
  let max_day = puzzle.max_day()
  use <- bool.guard(
    max_day <= 0,
    arg.new("day")
      |> arg.help("You're too early come back on Dec 1st, 2024")
      |> arg.try_map(fn(_) {
        Error("You're too early come back on Dec 1st, 2024")
      }),
  )
  arg.new("day")
  |> arg.help("Which day should be run: 1-" <> int.to_string(max_day))
  |> arg.try_map(fn(v) {
    case int.parse(v) {
      Ok(x) if x >= 1 && x <= max_day -> Ok(x)
      _ ->
        Error("day must be a number between 1 and " <> int.to_string(max_day))
    }
  })
}

fn visualize() {
  opt.new("visualization")
  |> opt.short("v")
  |> opt.help(
    "Show visualization: valid options are NONE, BOTH, PART1, or PART2",
  )
  |> opt.try_map(fn(v) {
    case string.uppercase(v) {
      "NONE" -> Ok(None)
      "BOTH" -> Ok(Both)
      "PART1" -> Ok(Part1)
      "PART2" -> Ok(Part2)
      _ -> Error("visualization must be one of: NONE, BOTH, PART1, or PART2")
    }
  })
  |> opt.default(Both)
}

fn day_command() {
  clip.command({
    use day <- clip.parameter
    use skip <- clip.parameter
    use visualize <- clip.parameter
    Day(day, skip, visualize)
  })
  |> clip.arg(day())
  |> clip.flag(
    flag.new("skip")
    |> flag.short("s")
    |> flag.help("Skip the results at the end"),
  )
  |> clip.opt(visualize())
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
  clip.subcommands([
    #("day", day_command()),
    #("all", all_command()),
    #("save", save_md_command()),
  ])
}

fn evaluate_day(
  day: Int,
  function: fn(String, Visualize) -> #(Int, Int),
  visualize: Visualize,
) -> Result(#(Duration, #(Int, Int)), String) {
  case day |> puzzle.get_input {
    Ok(input) -> Ok(helper.timed(fn() { function(input, visualize) }))
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
  result: Result(#(Duration, #(Int, Int)), String),
  day: Int,
  title: String,
) -> Nil {
  case result {
    Error(e) -> e |> ansi.red |> io.println_error
    Ok(#(time, #(part1, part2))) -> {
      let answers = puzzle.get_answers()
      let saved = answers |> dict.get(day) |> result.unwrap(Answer(day, 0, 0))
      io.println(
        helper.unnamed_blue("Results for Day " <> int.to_string(day) <> ": ")
        <> helper.faff_pink(title),
      )
      io.println(
        "Part 1: " |> helper.aged_plastic_yellow
        <> int.to_string(part1)
        |> string.pad_start(20, " ")
        |> result_colour(saved.part1, part1)
        <> " "
        <> result_emoji(saved.part1, part1),
      )
      io.println(
        "Part 2: " |> helper.aged_plastic_yellow
        <> int.to_string(part2)
        |> string.pad_start(20, " ")
        |> result_colour(saved.part2, part2)
        <> " "
        <> result_emoji(saved.part2, part2),
      )
      io.println(
        "Time  : " |> helper.unnamed_blue
        <> {
          duration.as_milliseconds_fractional(time)
          |> helper.float_to_string(3)
          <> " ms"
        }
        |> string.pad_start(23, " ")
        |> helper.faff_pink,
      )
      puzzle.update_answer(Answer(day, part1, part2), answers)
    }
  }
}

fn run_days(
  first: Int,
  last: Int,
) -> Dict(Int, #(Result(#(Duration, #(Int, Int)), String), String)) {
  let filtered =
    puzzle.get_days()
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
        [
          "]",
          "Evaluating day",
          string.pad_start(int.to_string(p.0), 2, "0") <> ":",
          p.1.1,
        ]
        |> string.join(" "),
      ))
      |> progress.print_bar
      #(p.0, #(evaluate_day(p.0, p.1.0, None), p.1.1))
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
  let headers =
    ["Day", "Title", "Time (ms)", "% Time"]
    |> list.map(table.Cell(_, 1, function.identity))
  let coldefs = [
    5 |> table.ColDef(table.Right),
    30 |> table.ColDef(table.Left),
    15 |> table.ColDef(table.Right),
    15 |> table.ColDef(table.Right),
  ]

  let total_time =
    results
    |> dict.values
    |> list.map(pair.first)
    |> result.values
    |> list.map(pair.first)
    |> list.fold(duration.nanoseconds(0), duration.increase)

  let rows =
    results
    |> dict.fold([], fn(rows, day, result_pair) {
      let #(result, title) = result_pair
      let times = case result {
        Ok(#(time, _)) -> [
          table.Cell(
            duration.as_milliseconds_fractional(time)
              |> helper.float_to_string(3),
            1,
            function.identity,
          ),
          table.Cell(
            duration.as_milliseconds_fractional(time)
            /. duration.as_milliseconds_fractional(total_time)
            *. 100.0
              |> helper.float_to_string(3),
            1,
            function.identity,
          ),
        ]
        Error(e) -> [table.Cell(e, 2, function.identity)]
      }
      [
        table.Cell(int.to_string(day), 1, function.identity),
        table.Cell(title, 1, function.identity),
        ..times
      ]
      |> list.wrap
      |> list.append(rows, _)
    })

  let total_row = [
    table.Cell("TOTAL", 2, function.identity),
    table.Cell(
      duration.as_milliseconds_fractional(total_time)
        |> helper.float_to_string(3),
      1,
      function.identity,
    ),
    table.Cell("100.000", 1, function.identity),
  ]

  let table =
    table.Table(headers, coldefs, list.append(rows, [total_row]))
    |> table.table_to_markdown

  io.println("Saving times...")
  let md =
    [
      "# Run times",
      "Run at "
        <> datetime.now_local() |> datetime.to_string
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

  let total_time =
    results
    |> dict.values
    |> list.map(pair.first)
    |> result.values
    |> list.map(pair.first)
    |> list.fold(duration.nanoseconds(0), duration.increase)

  let headers =
    ["Day", "Title", "Part 1", "Part 2", "Time (ms)", "% Time"]
    |> list.map(table.Cell(_, 1, helper.white))

  let coldefs = [
    table.ColDef(3, table.Right),
    table.ColDef(25, table.Left),
    table.ColDef(25, table.Right),
    table.ColDef(25, table.Right),
    table.ColDef(10, table.Right),
    table.ColDef(10, table.Right),
  ]

  let rows =
    results
    |> dict.fold([], fn(rows, day, result_pair) {
      let #(result, title) = result_pair
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
          [
            table.Cell(int.to_string(day), 1, helper.aged_plastic_yellow),
            table.Cell(title, 1, helper.unnamed_blue),
            table.Cell(p1.0, 1, p1.1),
            table.Cell(p2.0, 1, p2.1),
            table.Cell(
              duration.as_milliseconds_fractional(time)
                |> helper.float_to_string(3),
              1,
              helper.aged_plastic_yellow,
            ),
            table.Cell(
              duration.as_milliseconds_fractional(time)
              /. duration.as_milliseconds_fractional(total_time)
              *. 100.0
                |> helper.float_to_string(3),
              1,
              helper.faff_pink,
            ),
          ]
        }
        Error(e) -> [
          table.Cell(int.to_string(day), 1, ansi.red),
          table.Cell(title, 1, ansi.red),
          table.Cell(e, 4, ansi.red),
        ]
      }
      list.append(rows, [row])
    })

  let total_row = [
    table.Cell("TOTAL", 4, helper.unnamed_blue),
    table.Cell(
      duration.as_milliseconds_fractional(total_time)
        |> helper.float_to_string(3),
      1,
      helper.unnamed_blue,
    ),
    table.Cell("100.000", 1, helper.unnamed_blue),
  ]

  table.Table(headers, coldefs, list.append(rows, [total_row]))
  |> table.table_to_string(
    table.rounded_boarder(),
    helper.faff_pink,
    helper.bg_underwater_blue,
  )
  |> io.println
}

fn do_day(day: Int, skip: Bool, visualize: Visualize) {
  case puzzle.get_days() |> dict.get(day) {
    Error(_) ->
      ansi.red("Day " <> int.to_string(day) <> " is not implemented yet.")
      |> io.println_error
    Ok(#(fun, title)) -> {
      let results = evaluate_day(day, fun, visualize)
      case skip {
        True -> Nil
        False -> print_day_result(results, day, title)
      }
    }
  }
}

pub fn main() {
  let result =
    command()
    |> clip.help(help.simple("aoc2024", "Solve Advent of Code 2024 puzzles"))
    |> clip.run(argv.load().arguments)
  case result {
    Error(e) -> io.println_error(e)
    Ok(All) -> do_all_days()
    Ok(Day(day, skip, visualize)) -> do_day(day, skip, visualize)
    Ok(SaveMD) -> save_md()
  }
}
