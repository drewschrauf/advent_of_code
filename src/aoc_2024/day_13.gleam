import gleam/float
import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/regexp

pub type Vector {
  Vector(x: Int, y: Int)
}

pub type Machine {
  Machine(button_a: Vector, button_b: Vector, prize: Vector)
}

pub fn parse(input: String) -> List(Machine) {
  let assert Ok(machine_re) =
    regexp.from_string(
      "Button A: X\\+(\\d+), Y\\+(\\d+)\nButton B: X\\+(\\d+), Y\\+(\\d+)\nPrize: X=(\\d+), Y=(\\d+)",
    )

  machine_re
  |> regexp.scan(input)
  |> list.map(fn(match) {
    let regexp.Match(content: _, submatches: submatches) = match

    let assert [
      button_a_x,
      button_a_y,
      button_b_x,
      button_b_y,
      prize_x,
      prize_y,
    ] =
      submatches
      |> list.map(fn(submatch) {
        let assert Some(submatch) = submatch
        let assert Ok(num) = submatch |> int.parse
        num
      })

    Machine(
      button_a: Vector(x: button_a_x, y: button_a_y),
      button_b: Vector(x: button_b_x, y: button_b_y),
      prize: Vector(x: prize_x, y: prize_y),
    )
  })
}

fn is_int(num: Float) -> Result(Int, Nil) {
  let as_int = num |> float.round

  let is_equal = num == { as_int |> int.to_float }

  case is_equal {
    True -> Ok(as_int)
    False -> Error(Nil)
  }
}

fn solve(machine: Machine) -> Result(Int, Nil) {
  let button_a_x = machine.button_a.x |> int.to_float
  let button_a_y = machine.button_a.y |> int.to_float
  let button_b_x = machine.button_b.x |> int.to_float
  let button_b_y = machine.button_b.y |> int.to_float
  let prize_x = machine.prize.x |> int.to_float
  let prize_y = machine.prize.y |> int.to_float

  let times_b =
    { button_a_y *. prize_x -. button_a_x *. prize_y }
    /. { button_a_y *. button_b_x -. button_a_x *. button_b_y }
  let times_a = { prize_x -. button_b_x *. times_b } /. button_a_x

  case times_a |> is_int, times_b |> is_int {
    Ok(a), Ok(b) -> Ok(a * 3 + b)
    _, _ -> Error(Nil)
  }
}

pub fn pt_1(input: List(Machine)) {
  input
  |> list.fold(0, fn(acc, machine) {
    let result = machine |> solve
    case result {
      Error(_) -> acc
      Ok(cost) -> acc + cost
    }
  })
}

pub fn pt_2(input: List(Machine)) {
  input
  |> list.fold(0, fn(acc, machine) {
    let result =
      Machine(
        ..machine,
        prize: Vector(
          x: machine.prize.x + 10_000_000_000_000,
          y: machine.prize.y + 10_000_000_000_000,
        ),
      )
      |> solve
    case result {
      Error(_) -> acc
      Ok(cost) -> acc + cost
    }
  })
}
