import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/regexp
import gleam/string

pub type Vector {
  Vector(x: Int, y: Int)
}

fn vector_add(a: Vector, b: Vector) -> Vector {
  Vector(x: a.x + b.x, y: a.y + b.y)
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

fn solve_inner(
  location: Vector,
  machine: Machine,
  count: Int,
) -> Result(Int, Nil) {
  location |> io.debug
  count |> io.debug
  let oof = count >= 100
  case oof {
    True -> Error(Nil)
    False -> {
      let found_prize =
        location.x == machine.prize.x && location.y == machine.prize.y
      let oob = location.x > machine.prize.x || location.y > machine.prize.y
      case found_prize, oob {
        True, _ -> Ok(0)
        _, True -> Error(Nil)
        False, False -> {
          let a_result =
            solve_inner(
              location |> vector_add(machine.button_a),
              machine,
              count + 1,
            )
          let b_result =
            solve_inner(
              location |> vector_add(machine.button_b),
              machine,
              count + 1,
            )

          case a_result, b_result {
            Error(_), Error(_) -> Error(Nil)
            Ok(cost_a), Error(_) -> Ok(1 + cost_a)
            Error(_), Ok(cost_b) -> Ok(3 + cost_b)
            Ok(cost_a), Ok(cost_b) if cost_a > cost_b -> Ok(3 + cost_b)
            Ok(cost_a), Ok(_) -> Ok(1 + cost_a)
          }
        }
      }
    }
  }
}

fn solve(machine: Machine) -> Result(Int, Nil) {
  solve_inner(Vector(x: 0, y: 0), machine, 0)
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
  todo as "part 2 not implemented"
}
