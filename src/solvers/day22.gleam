import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import gleam/yielder
import utils/helper

type Sequence {
  Sequence(a: Int, b: Int, c: Int, d: Int)
}

fn evolve(secret: Int) -> Int {
  let next = { secret * 64 |> int.bitwise_exclusive_or(secret) } % 16_777_216
  let next = { next / 32 |> int.bitwise_exclusive_or(next) } % 16_777_216
  { next * 2048 |> int.bitwise_exclusive_or(next) } % 16_777_216
}

fn iterate(secret: Int, times: Int) -> Int {
  use <- bool.guard(times <= 0, secret)
  let secret = evolve(secret)
  iterate(secret, times - 1)
}

fn get_sequences(secret: Int) -> Dict(Sequence, Int) {
  yielder.iterate(secret, evolve)
  |> yielder.take(2000)
  |> yielder.map(fn(x) { x % 10 })
  |> yielder.to_list
  |> list.window_by_2
  |> list.map(fn(p) { #(p.1 - p.0, p.1) })
  |> list.window(4)
  |> list.fold(dict.new(), fn(sequences, changes) {
    let assert [#(a, _), #(b, _), #(c, _), #(d, v)] = changes
    let sequence = Sequence(a, b, c, d)
    case dict.has_key(sequences, sequence) {
      True -> sequences
      False -> sequences |> dict.insert(sequence, v)
    }
  })
}

pub fn solve(data: String, _visualization: helper.Visualize) -> #(Int, Int) {
  let secrets =
    data
    |> string.split("\n")
    |> list.map(int.parse)
    |> result.values

  let part1 =
    secrets
    |> helper.parallel_map(iterate(_, 2000))
    |> int.sum

  let part2 =
    secrets
    |> helper.parallel_map(get_sequences)
    |> list.fold(dict.new(), fn(a, b) { dict.combine(a, b, int.add) })
    |> dict.fold(0, fn(acc, _sequence, value) {
      case value > acc {
        True -> value
        False -> acc
      }
    })

  #(part1, part2)
}
