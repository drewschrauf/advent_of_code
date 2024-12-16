import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/result
import gleam/string

pub fn parse(input: String) -> List(Int) {
  input
  |> string.split(" ")
  |> list.map(fn(raw_num) {
    let assert Ok(num) = raw_num |> int.parse
    num
  })
}

fn split_number(num: Int) -> #(Int, Int) {
  let half_number_length = { num |> int.to_string |> string.length } / 2
  let chars =
    num
    |> int.to_string
    |> string.split("")

  let p1_chars =
    chars
    |> list.take(half_number_length)
    |> string.join("")
  let assert Ok(p1) = p1_chars |> int.parse
  let p2_chars =
    chars
    |> list.drop(half_number_length)
    |> string.join("")
  let assert Ok(p2) = p2_chars |> int.parse

  #(p1, p2)
}

fn blink_inner(stones: Dict(Int, Int), blinks: Int) -> Dict(Int, Int) {
  case blinks {
    0 -> stones
    _ -> {
      stones
      |> dict.keys
      |> list.fold([], fn(acc, stone) {
        let assert Ok(count) = stones |> dict.get(stone)
        let stone_length_even =
          stone |> int.to_string |> string.length |> int.is_even

        let new_values = case stone, stone_length_even {
          0, _ -> [1]
          n, True -> {
            let #(p1, p2) = n |> split_number
            [p1, p2]
          }
          n, _ -> [n * 2024]
        }

        list.flatten([
          acc,
          new_values
            |> list.map(fn(new_stone) { #(new_stone, count) }),
        ])
      })
      |> list.fold(dict.new(), fn(acc, stone_count) {
        let #(stone, count) = stone_count
        let current = acc |> dict.get(stone) |> result.unwrap(0)
        acc |> dict.insert(stone, count + current)
      })
      |> blink_inner(blinks - 1)
    }
  }
}

fn blink(stones: List(Int), blinks: Int) -> Int {
  let stones =
    stones
    |> list.fold(dict.new(), fn(acc, stone) {
      let existing = acc |> dict.get(stone) |> result.unwrap(0)
      dict.insert(acc, stone, existing + 1)
    })
    |> blink_inner(blinks)

  stones
  |> dict.keys
  |> list.map(fn(key) { stones |> dict.get(key) |> result.unwrap(0) })
  |> list.fold(0, int.add)
}

pub fn pt_1(input: List(Int)) {
  blink(input, 25)
}

pub fn pt_2(input: List(Int)) {
  blink(input, 75)
}
