import gleam/int
import gleam/list
import gleam/regexp
import gleam/string

pub fn parse(input: String) -> #(List(Int), List(Int)) {
  let assert Ok(whitespace_re) = regexp.from_string("\\s+")

  input
  |> string.split("\n")
  |> list.map(fn(line) {
    let assert [raw_a, raw_b] = line |> regexp.split(whitespace_re, _)
    let assert Ok(a) = raw_a |> int.parse
    let assert Ok(b) = raw_b |> int.parse
    #(a, b)
  })
  |> list.unzip
}

pub fn pt_1(input: #(List(Int), List(Int))) -> Int {
  let sorted_a = input.0 |> list.sort(int.compare)
  let sorted_b = input.1 |> list.sort(int.compare)
  list.zip(sorted_a, sorted_b)
  |> list.fold(0, fn(acc, v) { acc + int.absolute_value(v.0 - v.1) })
}

pub fn pt_2(input: #(List(Int), List(Int))) -> Int {
  input.0
  |> list.fold(0, fn(acc, value_a) {
    let list_b_count =
      input.1 |> list.filter(fn(value_b) { value_a == value_b }) |> list.length

    acc + value_a * list_b_count
  })
}
