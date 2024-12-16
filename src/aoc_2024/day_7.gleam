import gleam/int
import gleam/list
import gleam/string

pub type Equation {
  Equation(total: Int, operands: List(Int))
}

type Operation =
  fn(Int, Int) -> Int

pub fn parse(input: String) -> List(Equation) {
  input
  |> string.split("\n")
  |> list.map(fn(line) {
    let assert [raw_total, raw_operands] = line |> string.split(": ")

    let assert Ok(total) = raw_total |> int.parse
    let operands =
      raw_operands
      |> string.split(" ")
      |> list.map(fn(raw_operand) {
        let assert Ok(operand) = raw_operand |> int.parse
        operand
      })

    Equation(total: total, operands: operands)
  })
}

fn generate_equation_totals(
  running_total: Int,
  remaining_operands: List(Int),
  operations: List(Operation),
) -> List(Int) {
  case remaining_operands {
    [] -> [running_total]
    [next_operand, ..remaining_operands] -> {
      operations
      |> list.map(fn(operation) {
        generate_equation_totals(
          operation(running_total, next_operand),
          remaining_operands,
          operations,
        )
      })
      |> list.flatten
    }
  }
}

fn check_equation(equation: Equation, operations: List(Operation)) -> Bool {
  generate_equation_totals(0, equation.operands, operations)
  |> list.any(fn(total) { total == equation.total })
}

fn concat(a: Int, b: Int) -> Int {
  let assert Ok(num) =
    [a, b] |> list.map(int.to_string) |> string.concat |> int.parse
  num
}

fn sum_of_valid_totals(equations: List(Equation), operations: List(Operation)) {
  equations
  |> list.fold(0, fn(acc, eq) {
    let valid = eq |> check_equation(operations)
    case valid {
      True -> acc + eq.total
      False -> acc
    }
  })
}

pub fn pt_1(input: List(Equation)) {
  input |> sum_of_valid_totals([int.add, int.multiply])
}

pub fn pt_2(input: List(Equation)) {
  input |> sum_of_valid_totals([int.add, int.multiply, concat])
}
