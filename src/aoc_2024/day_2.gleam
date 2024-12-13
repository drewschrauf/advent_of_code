import gleam/int
import gleam/list
import gleam/order
import gleam/string

pub fn parse(input: String) -> List(List(Int)) {
  input
  |> string.split("\n")
  |> list.map(fn(line) {
    line
    |> string.split(" ")
    |> list.map(fn(v) {
      let assert Ok(num) = v |> int.parse
      num
    })
  })
}

fn check_report(report) -> Bool {
  let pairs =
    report
    |> list.window_by_2
    |> list.map(fn(window) {
      let direction = int.compare(window.0, window.1)
      let diff = int.absolute_value(window.1 - window.0)
      #(direction, diff)
    })

  let consistent_direction =
    pairs |> list.all(fn(pair) { pair.0 == order.Gt })
    || pairs |> list.all(fn(pair) { pair.0 == order.Lt })
  let safe_diff = pairs |> list.all(fn(pair) { pair.1 >= 1 && pair.1 <= 3 })

  consistent_direction && safe_diff
}

pub fn pt_1(input: List(List(Int))) -> Int {
  input
  |> list.map(check_report)
  |> list.count(fn(result) { result == True })
}

pub fn pt_2(input: List(List(Int))) -> Int {
  input
  |> list.map(fn(report) {
    let valid = report |> check_report

    case valid {
      True -> True
      False ->
        report
        |> list.combinations(list.length(report) - 1)
        |> list.map(check_report)
        |> list.any(fn(result) { result == True })
    }
  })
  |> list.count(fn(result) { result == True })
}
