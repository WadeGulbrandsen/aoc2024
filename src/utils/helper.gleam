import gleam/bool
import gleam/dynamic.{type Dynamic}
import gleam/erlang/atom
import gleam/float
import gleam/int
import gleam/list
import gleam/otp/task
import gleam/pair
import gleam/result
import gleam/string
import gleam/yielder
import gleam_community/ansi
import glitzer/spinner
import tempo.{type Duration}
import tempo/duration

pub type Visualize {
  None
  Both
  Part1
  Part2
}

pub fn at_index(list list: List(a), index index: Int) -> Result(a, Nil) {
  list |> yielder.from_list |> yielder.at(index)
}

pub fn map_both(of pair: #(a, a), with fun: fn(a) -> b) -> #(b, b) {
  #(pair |> pair.first |> fun, pair |> pair.second |> fun)
}

pub fn parallel_map(over list: List(a), with fun: fn(a) -> b) -> List(b) {
  list
  |> list.map(fn(item) { task.async(fn() { fun(item) }) })
  |> list.map(task.await_forever)
}

pub fn parallel_filter(
  over list: List(a),
  keeping predicate: fn(a) -> Bool,
) -> List(a) {
  list
  |> parallel_map(fn(item) { #(item, predicate(item)) })
  |> list.filter(pair.second)
  |> list.map(pair.first)
}

@external(erlang, "io", "get_line")
@external(javascript, "./js_ffi.mjs", "read_line")
fn ext_read_line(prompt: String) -> Dynamic

pub fn read_line(prompt: String) -> String {
  ext_read_line(prompt)
  |> dynamic.from
  |> dynamic.string
  |> result.unwrap("")
  |> string.trim_end
}

pub fn ask_yn(prompt: String, default: Bool) -> Bool {
  case read_line(prompt <> "\n") |> string.uppercase {
    "Y" -> True
    "N" -> False
    "" -> default
    _ -> ask_yn(prompt, default)
  }
}

@external(erlang, "erlang", "system_info")
fn ext_system_info(item: atom.Atom) -> Dynamic

pub fn get_thread_count() -> Int {
  let atom = atom.create_from_string("logical_processors")
  let info = ext_system_info(atom)
  info |> dynamic.int |> result.unwrap(0)
}

pub fn int_to_string_with_commas(x: Int) -> String {
  int_to_string_helper(x, [])
}

fn int_to_string_helper(remaining: Int, parts: List(String)) -> String {
  case remaining / 1000, remaining % 1000 {
    0, x -> [int.to_string(x), ..parts] |> string.join(",")
    r, x ->
      int_to_string_helper(r, [
        int.to_string(x) |> string.pad_start(3, "0"),
        ..parts
      ])
  }
}

pub fn faff_pink(s: String) -> String {
  ansi.hex(s, 0xffaff3)
}

pub fn white(s: String) -> String {
  ansi.hex(s, 0xfefefc)
}

pub fn unnamed_blue(s: String) -> String {
  ansi.hex(s, 0xa6f0fc)
}

pub fn aged_plastic_yellow(s: String) -> String {
  ansi.hex(s, 0xfffbe8)
}

pub fn unexpected_aubergine(s: String) -> String {
  ansi.hex(s, 0x584355)
}

pub fn underwater_blue(s: String) -> String {
  ansi.hex(s, 0x292d3e)
}

pub fn charcoal(s: String) -> String {
  ansi.hex(s, 0x2f2f2f)
}

pub fn black(s: String) -> String {
  ansi.hex(s, 0x1e1e1e)
}

pub fn blacker(s: String) -> String {
  ansi.hex(s, 0x151515)
}

pub fn bg_faff_pink(s: String) -> String {
  ansi.bg_hex(s, 0xffaff3)
}

pub fn bg_white(s: String) -> String {
  ansi.bg_hex(s, 0xfefefc)
}

pub fn bg_unnamed_blue(s: String) -> String {
  ansi.bg_hex(s, 0xa6f0fc)
}

pub fn bg_aged_plastic_yellow(s: String) -> String {
  ansi.bg_hex(s, 0xfffbe8)
}

pub fn bg_unexpected_aubergine(s: String) -> String {
  ansi.bg_hex(s, 0x584355)
}

pub fn bg_underwater_blue(s: String) -> String {
  ansi.bg_hex(s, 0x292d3e)
}

pub fn bg_charcoal(s: String) -> String {
  ansi.bg_hex(s, 0x2f2f2f)
}

pub fn bg_black(s: String) -> String {
  ansi.bg_hex(s, 0x1e1e1e)
}

pub fn bg_blacker(s: String) -> String {
  ansi.bg_hex(s, 0x151515)
}

pub fn float_to_string(f: Float, percision: Int) -> String {
  let str = f |> float.to_precision(percision) |> float.to_string
  case str |> string.split_once(".") {
    Error(_) -> str
    Ok(#(w, d)) ->
      w
      <> "."
      <> d
      |> string.drop_end(int.max(0, string.length(d) - percision))
      |> string.pad_end(percision, "0")
  }
}

pub fn timed(body: fn() -> a) -> #(Duration, a) {
  let start = duration.start_monotonic()
  let value = body()
  let elapsed = duration.stop_monotonic(start)
  #(elapsed, value)
}

pub fn repeat_function(a: a, function: fn(a) -> a, times: Int) -> a {
  use <- bool.guard(times <= 0, a)
  repeat_function(function(a), function, times - 1)
}

pub fn spin_it(
  start_message s: String,
  finish_message f: String,
  show_spinner visualize: Bool,
  body fun: fn() -> a,
) -> a {
  use <- bool.guard(!visualize, fun())
  let spinner =
    spinner.spinning_spinner()
    |> spinner.with_left_text(s)
    |> spinner.with_finish_text(f)
    |> spinner.spin
  let result = fun()
  spinner.finish(spinner)
  result
}
