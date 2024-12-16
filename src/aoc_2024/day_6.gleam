import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/set.{type Set}
import gleam/string

pub type Location {
  Empty
  Obstacle
}

pub type Map =
  Dict(Int, Dict(Int, Location))

pub type Position {
  Position(row: Int, column: Int)
}

pub type Direction {
  Up
  Down
  Left
  Right
}

pub type Guard {
  Guard(position: Position, direction: Direction)
}

pub type Scenario {
  Scenario(map: Map, guard: Guard)
}

pub fn parse(input: String) -> Scenario {
  let rows =
    input
    |> string.split("\n")
    |> list.index_map(fn(row, row_index) {
      let columns =
        row
        |> string.split("")
        |> list.index_map(fn(char, column_index) {
          let location = case char {
            "#" -> Obstacle
            _ -> Empty
          }
          let guard =
            case char {
              "^" -> Some(Up)
              "v" -> Some(Down)
              "<" -> Some(Left)
              ">" -> Some(Right)
              _ -> None
            }
            |> option.map(Guard(
              position: Position(row: row_index, column: column_index),
              direction: _,
            ))
          #(#(column_index, location), guard)
        })

      #(
        columns |> list.map(fn(c) { c.0 }) |> dict.from_list,
        columns
          |> list.fold(None, fn(acc, c) {
            case c.1 {
              Some(_) -> c.1
              None -> acc
            }
          }),
      )
    })

  let map =
    rows
    |> list.index_map(fn(r, row_index) { #(row_index, r.0) })
    |> dict.from_list

  let assert Some(guard) =
    rows
    |> list.fold(None, fn(acc, c) {
      case c.1 {
        Some(_) -> c.1
        None -> acc
      }
    })

  Scenario(map: map, guard: guard)
}

fn generate_path_inner(
  scenario: Scenario,
  path: List(Position),
  previous_guards: Set(Guard),
) -> Result(List(Position), Nil) {
  let next_step_position = case scenario.guard {
    Guard(position: p, direction: Up) -> Position(..p, row: p.row - 1)
    Guard(position: p, direction: Down) -> Position(..p, row: p.row + 1)
    Guard(position: p, direction: Left) -> Position(..p, column: p.column - 1)
    Guard(position: p, direction: Right) -> Position(..p, column: p.column + 1)
  }

  let next_step_location = {
    use column <- result.try(scenario.map |> dict.get(next_step_position.row))
    use location <- result.try(column |> dict.get(next_step_position.column))
    Ok(location)
  }

  case next_step_location {
    Error(_) -> Ok(path)
    Ok(location) -> {
      let #(next_guard, next_path) = case location {
        Empty -> #(Guard(..scenario.guard, position: next_step_position), [
          next_step_position,
          ..path
        ])
        Obstacle -> #(
          Guard(
            ..scenario.guard,
            direction: case scenario.guard.direction {
              Up -> Right
              Down -> Left
              Left -> Up
              Right -> Down
            },
          ),
          path,
        )
      }

      let has_loop = previous_guards |> set.contains(next_guard)
      case has_loop {
        True -> Error(Nil)
        False ->
          generate_path_inner(
            Scenario(..scenario, guard: next_guard),
            next_path,
            previous_guards
              |> set.insert(next_guard),
          )
      }
    }
  }
}

fn generate_path(scenario: Scenario) -> Result(List(Position), Nil) {
  generate_path_inner(
    scenario,
    [scenario.guard.position],
    set.from_list([scenario.guard]),
  )
}

fn generate_blocked_maps(path: List(Position), scenario: Scenario) -> List(Map) {
  path
  |> list.map(fn(pos) {
    let assert Ok(row) = scenario.map |> dict.get(pos.row)
    scenario.map
    |> dict.insert(pos.row, row |> dict.insert(pos.column, Obstacle))
  })
}

pub fn pt_1(input: Scenario) -> Int {
  let assert Ok(path) =
    input
    |> generate_path()

  path
  |> list.unique
  |> list.length
}

pub fn pt_2(input: Scenario) -> Int {
  let assert Ok(original_path) =
    input
    |> generate_path()

  original_path
  |> list.filter(fn(pos) { pos != input.guard.position })
  |> list.unique
  |> generate_blocked_maps(input)
  |> list.map(fn(map) { Scenario(..input, map: map) })
  |> list.map(generate_path)
  |> list.filter(result.is_error)
  |> list.length
}
