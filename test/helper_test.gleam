import gleam/erlang/process
import gleam/int
import gleam/list
import gleeunit/should
import utils/helper

pub fn map_both_test() {
  helper.map_both(#(2, 3), fn(x) { x * x })
  |> should.equal(#(4, 9))
}

pub fn at_index_test() {
  let list = ["a", "b", "c"]

  helper.at_index(list, 0)
  |> should.equal(Ok("a"))

  helper.at_index(list, 1)
  |> should.equal(Ok("b"))

  helper.at_index(list, 2)
  |> should.equal(Ok("c"))

  helper.at_index(list, 3)
  |> should.be_error
}

pub fn parallel_map_test() {
  let list = list.range(0, 1000)
  list
  |> helper.parallel_map(fn(x) {
    process.sleep(100)
    x
  })
  |> should.equal(list)
}

pub fn parallel_filter_test() {
  let list = list.range(0, 1000)
  list
  |> helper.parallel_filter(fn(x) {
    process.sleep(100)
    int.is_even(x)
  })
  |> should.equal(list |> list.filter(int.is_even))
}
