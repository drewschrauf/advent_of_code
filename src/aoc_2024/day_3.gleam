import gleam/int
import gleam/list
import gleam/regexp

type Instruction {
  Value(Int)
  Do
  Dont
}

fn extract_instructions(input: String) -> List(Instruction) {
  let assert Ok(instruction_re) =
    regexp.from_string("mul\\(\\d{1,3},\\d{1,3}\\)|do\\(\\)|don't\\(\\)")
  let assert Ok(num_re) = regexp.from_string("\\d+")

  input
  |> regexp.scan(instruction_re, _)
  |> list.map(fn(match) {
    let regexp.Match(op, _) = match

    case op {
      "mul" <> _ ->
        op
        |> regexp.scan(num_re, _)
        |> list.map(fn(match) {
          let regexp.Match(raw_num, _) = match
          let assert Ok(num) = int.parse(raw_num)
          num
        })
        |> list.fold(1, int.multiply)
        |> Value
      "don't" <> _ -> Dont
      "do" <> _ -> Do
      _ -> panic
    }
  })
}

pub fn pt_1(input: String) {
  input
  |> extract_instructions
  |> list.fold(0, fn(acc, instruction) {
    acc
    + {
      case instruction {
        Value(v) -> v
        _ -> 0
      }
    }
  })
}

type Accumulator {
  Accumulator(enabled: Bool, value: Int)
}

pub fn pt_2(input: String) {
  let result =
    input
    |> extract_instructions
    |> list.fold(Accumulator(enabled: True, value: 0), fn(acc, instruction) {
      case acc, instruction {
        Accumulator(True, value), Value(next) ->
          Accumulator(..acc, value: value + next)
        _, Do -> Accumulator(..acc, enabled: True)
        _, Dont -> Accumulator(..acc, enabled: False)
        _, _ -> acc
      }
    })

  result.value
}
