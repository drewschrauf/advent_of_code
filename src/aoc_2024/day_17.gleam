import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/regexp
import gleam/string

pub type Computer {
  Computer(
    instructions: Dict(Int, Int),
    pointer: Int,
    register_a: Int,
    register_b: Int,
    register_c: Int,
  )
}

pub fn parse(input: String) -> Computer {
  let assert Ok(input_regexp) =
    regexp.from_string(
      "Register A: (\\d+)\nRegister B: (\\d+)\nRegister C: (\\d+)\n\nProgram: (.+)",
    )

  let assert [
    regexp.Match(
      _,
      [
        Some(raw_register_a),
        Some(raw_register_b),
        Some(raw_register_c),
        Some(raw_program),
      ],
    ),
  ] = input_regexp |> regexp.scan(input)

  let assert Ok(register_a) = raw_register_a |> int.parse()
  let assert Ok(register_b) = raw_register_b |> int.parse()
  let assert Ok(register_c) = raw_register_c |> int.parse()

  let instructions =
    raw_program
    |> string.split(",")
    |> list.index_map(fn(raw_instruction, idx) {
      let assert Ok(instruction) = raw_instruction |> int.parse()
      #(idx, instruction)
    })
    |> dict.from_list()

  Computer(instructions:, pointer: 0, register_a:, register_b:, register_c:)
}

fn get_literal_operand(computer: Computer) -> Int {
  let assert Ok(operand) =
    computer.instructions |> dict.get(computer.pointer + 1)
  operand
}

fn get_combo_operand(computer: Computer) {
  let operand = computer |> get_literal_operand()

  case operand {
    0 | 1 | 2 | 3 -> operand
    4 -> computer.register_a
    5 -> computer.register_b
    6 -> computer.register_c
    _ -> panic
  }
}

fn run(computer: Computer) {
  let instruction = computer.instructions |> dict.get(computer.pointer)

  case instruction {
    Error(_) -> []
    Ok(instruction) -> {
      case instruction {
        0 -> {
          let numerator = computer.register_a |> int.to_float()
          let assert Ok(denominator) =
            int.power(2, computer |> get_combo_operand() |> int.to_float())
          let register_a =
            { numerator /. denominator } |> float.floor() |> float.round()

          run(Computer(..computer, pointer: computer.pointer + 2, register_a:))
        }
        1 -> {
          let register_b =
            computer
            |> get_literal_operand()
            |> int.bitwise_exclusive_or(computer.register_b)
          run(Computer(..computer, pointer: computer.pointer + 2, register_b:))
        }
        2 -> {
          let register_b = { computer |> get_combo_operand() } % 8
          run(Computer(..computer, pointer: computer.pointer + 2, register_b:))
        }
        3 -> {
          let should_jump = computer.register_a != 0
          case should_jump {
            True ->
              run(
                Computer(..computer, pointer: computer |> get_literal_operand),
              )
            False -> run(Computer(..computer, pointer: computer.pointer + 2))
          }
        }
        4 -> {
          let register_b =
            int.bitwise_exclusive_or(computer.register_b, computer.register_c)
          run(Computer(..computer, pointer: computer.pointer + 2, register_b:))
        }
        5 -> {
          let output = { computer |> get_combo_operand() } % 8
          [output, ..run(Computer(..computer, pointer: computer.pointer + 2))]
        }
        6 -> {
          let numerator = computer.register_a |> int.to_float()
          let assert Ok(denominator) =
            int.power(2, computer |> get_combo_operand() |> int.to_float())
          let register_b =
            { numerator /. denominator } |> float.floor() |> float.round()

          run(Computer(..computer, pointer: computer.pointer + 2, register_b:))
        }
        7 -> {
          let numerator = computer.register_a |> int.to_float()
          let assert Ok(denominator) =
            int.power(2, computer |> get_combo_operand() |> int.to_float())
          let register_c =
            { numerator /. denominator } |> float.floor() |> float.round()

          run(Computer(..computer, pointer: computer.pointer + 2, register_c:))
        }
        _ -> panic
      }
    }
  }
}

fn print_output(output: List(Int)) -> String {
  output
  |> list.map(fn(out) { out |> int.to_string() })
  |> string.join(",")
}

pub fn pt_1(input: Computer) {
  input |> run() |> print_output()
}

fn find_register_a_inner(
  computer: Computer,
  instructions: List(Int),
  digits: List(Int),
  next_digit: Int,
) {
  let overflow = next_digit == 8
  case overflow {
    True -> Error(Nil)
    False -> {
      let assert Ok(register_a) =
        {
          list.flatten([digits, [next_digit]])
          |> list.map(fn(digit) { digit |> int.to_string })
          |> string.join("")
        }
        |> string.pad_end(instructions |> list.length(), "0")
        |> int.base_parse(8)

      let result = run(Computer(..computer, register_a:))

      let is_quine = result == instructions
      case is_quine {
        True -> Ok(register_a)
        False -> {
          let drop_amount = list.length(instructions) - list.length(digits) - 1
          let tail_matches =
            instructions |> list.drop(drop_amount)
            == result |> list.drop(drop_amount)

          case tail_matches {
            True -> {
              let next_digit_result =
                find_register_a_inner(
                  computer,
                  instructions,
                  [digits, [next_digit]] |> list.flatten(),
                  0,
                )
              case next_digit_result {
                Ok(_) -> next_digit_result
                Error(_) ->
                  find_register_a_inner(
                    computer,
                    instructions,
                    digits,
                    next_digit + 1,
                  )
              }
            }
            False -> {
              find_register_a_inner(
                computer,
                instructions,
                digits,
                next_digit + 1,
              )
            }
          }
        }
      }
    }
  }
}

fn find_register_a(computer: Computer) {
  let instructions =
    computer.instructions
    |> dict.to_list()
    |> list.sort(fn(a, b) { int.compare(a.0, b.0) })
    |> list.map(fn(instruction) { instruction.1 })

  let assert Ok(register_a) =
    find_register_a_inner(computer, instructions, [], 0)
  register_a
}

pub fn pt_2(input: Computer) {
  input |> find_register_a()
}
