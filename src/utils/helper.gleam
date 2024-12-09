import gleam/dynamic.{type Dynamic}
import gleam/list
import gleam/otp/task
import gleam/pair
import gleam/result
import gleam/string
import gleam/yielder

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
