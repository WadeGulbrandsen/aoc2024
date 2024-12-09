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
import utils/helper
import utils/ppjson

const answers_path = "./input/answers.json"

const session_path = "./input/session.txt"

pub type Answer {
  Answer(day: Int, part1: Int, part2: Int)
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
