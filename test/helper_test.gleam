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
