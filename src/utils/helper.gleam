import gleam/pair
import gleam/yielder

pub fn at_index(list list: List(a), index index: Int) -> Result(a, Nil) {
  list |> yielder.from_list |> yielder.at(index)
}

pub fn map_both(of pair: #(a, a), with fun: fn(a) -> b) -> #(b, b) {
  #(pair |> pair.first |> fun, pair |> pair.second |> fun)
}
