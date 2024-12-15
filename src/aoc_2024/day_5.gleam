import gleam/bool
import gleam/int
import gleam/list
import gleam/result
import gleam/string

pub fn parse(input: String) -> #(List(#(Int, Int)), List(List(Int))) {
  let assert [raw_rules, raw_orders] = input |> string.split("\n\n")

  let rules =
    raw_rules
    |> string.split("\n")
    |> list.map(fn(raw_rule) {
      let assert [raw_before, raw_after] = raw_rule |> string.split("|")
      let assert Ok(before) = int.parse(raw_before)
      let assert Ok(after) = int.parse(raw_after)
      #(before, after)
    })

  let orders =
    raw_orders
    |> string.split("\n")
    |> list.map(fn(raw_order) {
      raw_order
      |> string.split(",")
      |> list.map(fn(page) {
        let assert Ok(num) = int.parse(page)
        num
      })
    })

  #(rules, orders)
}

fn check_order_valid(order: List(Int), rules: List(#(Int, Int))) -> Bool {
  case order {
    [first, ..rest] -> {
      let valid =
        rest
        |> list.all(fn(page) {
          rules |> list.contains(#(page, first)) |> bool.negate
        })

      case valid {
        True -> check_order_valid(order |> list.drop(1), rules)
        False -> False
      }
    }
    _ -> True
  }
}

fn build_valid_orders(
  order: List(Int),
  rules: List(#(Int, Int)),
) -> Result(List(List(Int)), Nil) {
  let options =
    order
    |> list.index_map(fn(page, idx) {
      let #(heads, tails) = order |> list.split(idx)
      let other_pages = list.flatten([heads, tails |> list.drop(1)])

      let valid =
        other_pages
        |> list.all(fn(other_page) {
          rules |> list.contains(#(other_page, page)) |> bool.negate
        })

      case valid, other_pages {
        True, [] -> {
          Ok([[page]])
        }
        True, _ -> {
          use tails <- result.try(other_pages |> build_valid_orders(rules))
          Ok(tails |> list.map(list.prepend(_, page)))
        }
        False, _ -> Error(Nil)
      }
    })

  let valid_options =
    options
    |> list.fold([], fn(acc, f) {
      case f {
        Error(Nil) -> acc
        Ok(r) -> list.flatten([acc, r])
      }
    })

  case valid_options {
    [] -> Error(Nil)
    vo -> Ok(vo)
  }
}

fn get_center_number(order: List(Int)) -> Int {
  order
  |> list.drop({ order |> list.length } / 2)
  |> list.first
  |> result.unwrap(0)
}

pub fn pt_1(input: #(List(#(Int, Int)), List(List(Int)))) {
  let rules = input.0
  let orders = input.1

  orders
  |> list.filter(check_order_valid(_, rules))
  |> list.map(get_center_number)
  |> list.fold(0, int.add)
}

pub fn pt_2(input: #(List(#(Int, Int)), List(List(Int)))) {
  let rules = input.0
  let orders = input.1

  orders
  |> list.filter(fn(order) { order |> check_order_valid(rules) |> bool.negate })
  |> list.map(build_valid_orders(_, rules))
  |> list.map(result.unwrap(_, []))
  |> list.map(list.flatten)
  |> list.map(get_center_number)
  |> list.fold(0, int.add)
}
