import efetch
import gleam/bool
import gleam/dict.{type Dict}
import gleam/dynamic
import gleam/http/request
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/result
import gleam/string
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
import solvers/day11
import solvers/day12
import solvers/day13
import solvers/day14
import solvers/day15
import solvers/day16
import solvers/day17
import solvers/day18
import solvers/day19
import solvers/day20
import solvers/day21
import solvers/day22
import solvers/day23
import solvers/day24
import solvers/day25
import tempo/date
import tempo/datetime
import tempo/offset
import utils/helper
import utils/ppjson

const days = [
  #(1, #(day01.solve, "Historian Hysteria")),
  #(2, #(day02.solve, "Red-Nosed Reports")),
  #(3, #(day03.solve, "Mull It Over")), #(4, #(day04.solve, "Ceres Search")),
  #(5, #(day05.solve, "Print Queue")), #(6, #(day06.solve, "Guard Gallivant")),
  #(7, #(day07.solve, "Bridge Repair")),
  #(8, #(day08.solve, "Resonant Collinearity")),
  #(9, #(day09.solve, "Disk Fragmenter")), #(10, #(day10.solve, "Hoof It")),
  #(11, #(day11.solve, "Plutonian Pebbles")),
  #(12, #(day12.solve, "Garden Groups")),
  #(13, #(day13.solve, "Claw Contraption")),
  #(14, #(day14.solve, "Restroom Redoubt")),
  #(15, #(day15.solve, "Warehouse Woes")),
  #(16, #(day16.solve, "Reindeer Maze")),
  #(17, #(day17.solve, "Chronospatial Computer")),
  #(18, #(day18.solve, "RAM Run")), #(19, #(day19.solve, "Linen Layout")),
  #(20, #(day20.solve, "Race Condition")), #(21, #(day21.solve, "NOT DEFINED")),
  #(22, #(day22.solve, "NOT DEFINED")), #(23, #(day23.solve, "NOT DEFINED")),
  #(24, #(day24.solve, "NOT DEFINED")), #(25, #(day25.solve, "NOT DEFINED")),
]

const answers_path = "./input/answers.json"

const session_path = "./input/session.txt"

pub type Answer {
  Answer(day: Int, part1: Int, part2: Int)
}

pub fn get_days() {
  let max_day = max_day()
  dict.from_list(days) |> dict.filter(fn(d, _) { max_day >= d })
}

pub fn max_day() -> Int {
  let dec01 = datetime.literal("2024-12-01T00:00:00.000-05:00")
  let dec25 = datetime.literal("2024-12-25T00:00:00.000-05:00")
  let now = datetime.now_utc() |> datetime.to_offset(offset.literal("-05:00"))
  use <- bool.guard(datetime.is_later(now, dec25), 25)
  use <- bool.guard(datetime.is_earlier(now, dec01), 0)
  now |> datetime.get_date |> date.get_day
}

fn decode_answers(json: String) -> Result(List(Answer), Nil) {
  let answers_decoder =
    dynamic.list(dynamic.decode3(
      Answer,
      dynamic.field("day", dynamic.int),
      dynamic.field("part1", dynamic.int),
      dynamic.field("part2", dynamic.int),
    ))
  json.decode(json, answers_decoder) |> result.replace_error(Nil)
}

pub fn get_answers() -> Dict(Int, Answer) {
  answers_path
  |> simplifile.read
  |> result.replace_error(Nil)
  |> result.try(decode_answers)
  |> result.map(list.map(_, fn(a: Answer) { #(a.day, a) }))
  |> result.map(dict.from_list)
  |> result.unwrap(dict.new())
}

pub fn update_answer(answer: Answer, answers: Dict(Int, Answer)) -> Nil {
  let current =
    dict.get(answers, answer.day) |> result.unwrap(Answer(answer.day, 0, 0))
  use <- bool.guard(current == answer, Nil)
  use <- bool.guard(
    !helper.ask_yn(
      "The saved values don't match the results. Do you want to update them? [y/N]",
      False,
    ),
    Nil,
  )
  io.println("Updating saved answers...")
  let json =
    answers
    |> dict.insert(answer.day, answer)
    |> dict.values
    |> list.map(fn(a) {
      ppjson.Object([
        #("day", ppjson.Int(a.day)),
        #("part1", ppjson.Int(a.part1)),
        #("part2", ppjson.Int(a.part2)),
      ])
    })
    |> ppjson.Array
    |> ppjson.to_string(80)

  case simplifile.write(answers_path, json) {
    Ok(Nil) -> io.println("Done!")
    Error(_) -> io.println_error("Could not write " <> answers_path)
  }
}

pub fn get_input(day: Int) -> Result(String, String) {
  let padded_day = int.to_string(day) |> string.pad_start(2, "0")
  let file_path = "./input/day" <> padded_day <> ".txt"
  case simplifile.read(file_path) {
    Ok(input) -> Ok(input)
    _ -> {
      case load_input_from_web(day) {
        Ok(input) -> {
          let _ = simplifile.write(file_path, input)
          Ok(input)
        }
        Error(e) -> Error(e)
      }
    }
  }
}

fn load_input_from_web(day: Int) -> Result(String, String) {
  case simplifile.read(session_path) {
    Ok(session) -> download_input(day, session)
    _ -> Error("Could not read session cookie from " <> session_path)
  }
}

fn download_input(day: Int, session: String) -> Result(String, String) {
  let url =
    "https://adventofcode.com/2024/day/" <> int.to_string(day) <> "/input"
  let assert Ok(base_req) = request.to(url)
  let req = request.set_cookie(base_req, "session", session)
  case efetch.send(req) {
    Ok(res) ->
      case res.status {
        // remove the trailing newline in the body
        200 -> Ok(res.body |> string.drop_end(1))
        500 ->
          Error("Error 500: Try replacing the session in ./input/session.txt")
        404 ->
          Error(
            "Error 404: "
            <> url
            <> " was not found. Is day "
            <> int.to_string(day)
            <> " available yet?",
          )
        x -> Error("Error " <> int.to_string(x))
      }
    Error(e) -> Error(string.inspect(e))
  }
}
