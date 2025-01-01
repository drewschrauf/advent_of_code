import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/string

pub type Position {
  Position(x: Int, y: Int)
}

pub type Entity {
  Wall
  Empty
}

pub type Map =
  Dict(Position, Entity)

pub type Scenario {
  Scenario(map: Map, start: Position, end: Position)
}

pub fn parse(input: String) -> Scenario {
  let assert #(map, Some(start), Some(end)) =
    input
    |> string.split("\n")
    |> list.index_fold(#(dict.new(), None, None), fn(acc, row, row_index) {
      let #(columns, start, end) =
        row
        |> string.split("")
        |> list.index_fold(
          #(dict.new(), None, None),
          fn(acc, column, column_index) {
            let entity = case column {
              "#" -> Wall
              _ -> Empty
            }
            let is_start = column == "S"
            let is_end = column == "E"

            #(
              acc.0
                |> dict.insert(Position(x: column_index, y: row_index), entity),
              case is_start {
                True -> Some(Position(x: column_index, y: row_index))
                False -> acc.1
              },
              case is_end {
                True -> Some(Position(x: column_index, y: row_index))
                False -> acc.2
              },
            )
          },
        )

      #(
        columns
          |> dict.fold(acc.0, fn(acc, position, entity) {
            acc |> dict.insert(position, entity)
          }),
        case start {
          Some(_) -> start
          None -> acc.1
        },
        case end {
          Some(_) -> end
          None -> acc.2
        },
      )
    })

  Scenario(map:, start:, end:)
}

fn get_next_step(scenario: Scenario, path: List(Position)) -> Position {
  let assert Ok(next_step) = case path {
    [] -> Ok(scenario.start)
    [last_step, ..rest] -> {
      let positions = [
        Position(x: last_step.x - 1, y: last_step.y),
        Position(x: last_step.x + 1, y: last_step.y),
        Position(x: last_step.x, y: last_step.y - 1),
        Position(x: last_step.x, y: last_step.y + 1),
      ]

      case rest {
        [] ->
          positions
          |> list.find(fn(position) {
            let assert Ok(entity) = scenario.map |> dict.get(position)
            entity == Empty
          })
        [second_last_step, ..] ->
          positions
          |> list.find(fn(position) {
            let assert Ok(entity) = scenario.map |> dict.get(position)
            case entity {
              Wall -> False
              Empty -> position != second_last_step
            }
          })
      }
    }
  }
  next_step
}

fn get_standard_path_inner(scenario: Scenario, path: List(Position)) {
  let last_step = path |> list.first()
  case last_step {
    Ok(step) if step == scenario.end -> path
    _ -> {
      let next_step = get_next_step(scenario, path)
      get_standard_path_inner(scenario, [next_step, ..path])
    }
  }
}

fn get_standard_path(scenario: Scenario) {
  get_standard_path_inner(scenario, [])
}

fn get_cheats(positions: Dict(Position, Int), max: Int) -> List(Int) {
  positions
  |> dict.fold([], fn(acc, p1, d1) {
    positions
    |> dict.fold(acc, fn(acc, p2, d2) {
      let cheat_time =
        int.absolute_value(p1.x - p2.x) + int.absolute_value(p1.y - p2.y)
      case cheat_time {
        n if n > 0 && n <= max -> {
          let time_saved = d1 - d2 - n
          case time_saved > 0 {
            True -> [time_saved, ..acc]
            False -> acc
          }
        }
        _ -> acc
      }
    })
  })
}

fn cheat(scenario: Scenario, cheat_time: Int) {
  scenario
  |> get_standard_path()
  |> list.index_map(fn(position, idx) { #(position, idx) })
  |> dict.from_list()
  |> get_cheats(cheat_time)
  |> list.count(fn(time_saved) { time_saved >= 100 })
}

pub fn pt_1(input: Scenario) {
  input |> cheat(2)
}

pub fn pt_2(input: Scenario) {
  input |> cheat(20)
}
