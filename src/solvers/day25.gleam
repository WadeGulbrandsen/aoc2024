import gleam/int
import gleam/list
import gleam/string
import gleam/yielder
import utils/helper

type Lock =
  List(Int)

type Key =
  List(Int)

type Locks =
  List(Lock)

type Keys =
  List(Lock)

type LockKeyPair {
  LockKeyPair(lock: Lock, key: Key)
}

type LockKeyPairs =
  List(LockKeyPair)

fn parse(data: String) -> #(Locks, Keys) {
  data
  |> string.split("\n\n")
  |> list.fold(#([], []), fn(locks_keys, str) {
    let #(locks, keys) = locks_keys
    let pin_heigths =
      str
      |> string.split("\n")
      |> list.map(string.to_graphemes)
      |> list.transpose
      |> list.map(fn(l) { list.count(l, fn(g) { g == "#" }) - 1 })
    case string.starts_with(str, "#####\n") {
      True -> #([pin_heigths, ..locks], keys)
      False -> #(locks, [pin_heigths, ..keys])
    }
  })
  |> helper.map_both(list.reverse)
}

fn non_overlapping(pair: LockKeyPair) -> Bool {
  list.map2(pair.lock, pair.key, int.add) |> list.all(fn(x) { x < 6 })
}

fn non_overlapping_pairs(locks: Locks, keys: Keys) -> LockKeyPairs {
  locks
  |> yielder.from_list
  |> yielder.flat_map(fn(lock) {
    keys |> yielder.from_list |> yielder.map(LockKeyPair(lock, _))
  })
  |> yielder.filter(non_overlapping)
  |> yielder.to_list
}

pub fn solve(data: String, _visualization: helper.Visualize) -> #(Int, Int) {
  let #(locks, keys) = parse(data)
  let pairs = non_overlapping_pairs(locks, keys)
  #(list.length(pairs), 50)
}
