import efetch
import gleam/http/request
import gleam/int
import gleam/io
import gleam/string
import simplifile

pub fn get_input(day: Int) -> Result(String, String) {
  let padded_day = int.to_string(day) |> string.pad_start(2, "0")
  let file_path = "./input/day" <> padded_day <> ".txt"
  io.println("Reading " <> file_path)
  case simplifile.read(file_path) {
    Ok(input) -> Ok(input)
    _ -> {
      io.println("Could not read " <> file_path)
      io.println("Trying to load from the web")
      case load_input_from_web(day) {
        Ok(input) -> {
          io.println("Input sucessfully downloaded")
          let _ = simplifile.write(file_path, input)
          Ok(input)
        }
        Error(e) -> Error(e)
      }
    }
  }
}

fn load_input_from_web(day: Int) -> Result(String, String) {
  let session_path = "./input/session.txt"
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
