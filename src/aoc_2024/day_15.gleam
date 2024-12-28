import gleam/dict.{type Dict}
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string

pub type Position {
  Position(x: Int, y: Int)
}

pub type Entity {
  Wall
  Box
  Empty
}

pub type Direction {
  Up
  Down
  Left
  Right
}

pub type Map =
  Dict(Int, Dict(Int, Entity))

pub type Scenario {
  Scenario(map: Map, robot: Position, instructions: List(Direction))
}

pub fn parse(input: String) -> Scenario {
  let assert [raw_map, raw_instructions] = input |> string.split("\n\n")

  let assert #(map, Some(robot)) =
    raw_map
    |> string.split("\n")
    |> list.index_fold(#(dict.new(), None), fn(acc, row, row_index) {
      let row_result =
        row
        |> string.split("")
        |> list.index_fold(#(dict.new(), None), fn(acc, column, column_index) {
          let entity = case column {
            "#" -> Wall
            "O" -> Box
            _ -> Empty
          }
          let robot = case column {
            "@" -> Some(column_index)
            _ -> None
          }

          #(acc.0 |> dict.insert(column_index, entity), case acc.1 {
            Some(_) -> acc.1
            None -> robot
          })
        })

      #(acc.0 |> dict.insert(row_index, row_result.0), case row_result.1 {
        Some(col) -> Some(Position(x: col, y: row_index))
        None -> acc.1
      })
    })

  let instructions =
    raw_instructions
    |> string.split("\n")
    |> string.join("")
    |> string.split("")
    |> list.map(fn(raw_instruction) {
      case raw_instruction {
        "^" -> Up
        "v" -> Down
        "<" -> Left
        ">" -> Right
        _ -> panic
      }
    })

  Scenario(map:, robot:, instructions:)
}

fn relative_position(position: Position, direction: Direction) -> Position {
  case position, direction {
    Position(x: _, y: y), Up -> Position(..position, y: y - 1)
    Position(x: _, y: y), Down -> Position(..position, y: y + 1)
    Position(x: x, y: _), Left -> Position(..position, x: x - 1)
    Position(x: x, y: _), Right -> Position(..position, x: x + 1)
  }
}

fn get_entity(map: Map, position: Position) -> Entity {
  let assert Ok(row) = map |> dict.get(position.y)
  let assert Ok(column) = row |> dict.get(position.x)
  column
}

fn set_entity(map: Map, position: Position, entity: Entity) -> Map {
  let assert Ok(row) = map |> dict.get(position.y)
  map |> dict.insert(position.y, row |> dict.insert(position.x, entity))
}

fn update_map(
  map: Map,
  position: Position,
  direction: Direction,
) -> Result(Map, Nil) {
  let entity = map |> get_entity(position)

  case entity {
    Wall -> Error(Nil)
    Empty -> Ok(map)
    Box -> {
      let next_position = position |> relative_position(direction)
      use update_result <- result.try(
        map |> update_map(next_position, direction),
      )
      Ok(
        update_result
        |> set_entity(next_position, Box)
        |> set_entity(position, Empty),
      )
    }
  }
}

fn move_robot(scenario: Scenario) -> Map {
  let Scenario(map:, robot:, instructions:) = scenario

  case instructions {
    [] -> map
    [instruction, ..instructions] -> {
      let next_position = robot |> relative_position(instruction)
      let move_result = map |> update_map(next_position, instruction)

      case move_result {
        Ok(next_map) ->
          Scenario(map: next_map, robot: next_position, instructions:)
        Error(_) -> Scenario(map:, robot:, instructions:)
      }
      |> move_robot
    }
  }
}

fn calculate_coords(map: Map) -> Int {
  map
  |> dict.fold(0, fn(acc, row_index, row) {
    acc
    + dict.fold(row, 0, fn(acc, column_index, column) {
      case column {
        Box -> acc + 100 * row_index + column_index
        _ -> acc
      }
    })
  })
}

pub fn pt_1(input: Scenario) {
  input |> move_robot |> calculate_coords
}

pub fn pt_2(input: Scenario) {
  todo as "part 2 not implemented"
}
