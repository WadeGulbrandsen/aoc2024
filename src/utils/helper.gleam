import gleam/list
import gleam/yielder

pub fn at_index(list list: List(a), index index: Int) -> Result(a, Nil) {
  let i = case index < 0 {
    True -> list.length(list) + index
    False -> index
  }
  list |> yielder.from_list |> yielder.at(i)
}
