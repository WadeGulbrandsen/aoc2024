import gleam/dict
import gleam/function
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import utils/helper

type Stones =
  dict.Dict(Int, Int)

fn blink(stones: Stones) -> Stones {
  stones
  |> dict.fold(dict.new(), fn(stones, stone, count) {
    apply_rule(stone)
    |> list.fold(stones, fn(acc, new_stone) {
      dict.upsert(acc, new_stone, fn(x) {
        case x {
          Some(current) -> current + count
          None -> count
        }
      })
    })
  })
}

fn apply_rule(stone: Int) -> List(Int) {
  let assert Ok(digits) = stone |> int.digits(10)
  case digits |> list.length |> int.is_even {
    _ if stone == 0 -> 1 |> list.wrap
    True ->
      digits
      |> list.split(list.length(digits) / 2)
      |> helper.map_both(int.undigits(_, 10))
      |> fn(p) { [p.0, p.1] }
      |> result.values
    False -> stone * 2024 |> list.wrap
  }
}

pub fn solve(data: String) -> #(Int, Int) {
  io.println_error("")
  let p1 =
    data
    |> string.split(" ")
    |> list.map(int.parse)
    |> result.values
    |> list.group(function.identity)
    |> dict.map_values(fn(_, v) { list.length(v) })
    |> helper.repeat_function(blink, 25)

  let p2 = p1 |> helper.repeat_function(blink, 50) |> dict.values |> int.sum
  #(p1 |> dict.values |> int.sum, p2)
}
