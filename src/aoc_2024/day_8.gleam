import gleam/dict.{type Dict}
import gleam/list
import gleam/result
import gleam/string

pub type Position {
  Position(row: Int, column: Int)
}

pub type World {
  World(rows: Int, columns: Int, antennas: Dict(String, List(Position)))
}

pub fn parse(input: String) -> World {
  let rows = input |> string.split("\n")
  let assert Ok(first_row) = rows |> list.first

  let antennas =
    rows
    |> list.index_map(fn(row, row_index) {
      row
      |> string.split("")
      |> list.index_fold([], fn(acc, column, column_index) {
        case column {
          "." -> acc
          _ -> [
            #(column, Position(row: row_index, column: column_index)),
            ..acc
          ]
        }
      })
    })
    |> list.flatten
    |> list.fold(dict.new(), fn(acc, antenna) {
      let #(name, position) = antenna
      let existing_antennas = acc |> dict.get(name) |> result.unwrap([])
      acc |> dict.insert(name, [position, ..existing_antennas])
    })

  World(
    rows: rows |> list.length,
    columns: first_row |> string.length,
    antennas: antennas,
  )
}

fn get_antinodes(positions: #(Position, Position)) -> List(Position) {
  let #(a, b) = positions

  [
    Position(
      row: a.row - { b.row - a.row },
      column: a.column - { b.column - a.column },
    ),
    Position(
      row: b.row - { a.row - b.row },
      column: b.column - { a.column - b.column },
    ),
  ]
}

fn get_harmonic_antinodes_inner(
  position: Position,
  step: #(Int, Int),
  world: World,
) {
  let next_position =
    Position(row: position.row + step.0, column: position.column + step.1)
  let next_position_in_bounds =
    next_position.row >= 0
    && next_position.row < world.rows
    && next_position.column >= 0
    && next_position.column < world.columns

  case next_position_in_bounds {
    False -> []
    True -> {
      let rest = get_harmonic_antinodes_inner(next_position, step, world)
      [next_position, ..rest]
    }
  }
}

fn get_harmonic_antinodes(
  positions: #(Position, Position),
  world: World,
) -> List(Position) {
  let #(a, b) = positions

  let step = #(b.row - a.row, b.column - a.column)

  [
    [a],
    get_harmonic_antinodes_inner(a, step, world),
    get_harmonic_antinodes_inner(a, #(step.0 * -1, step.1 * -1), world),
  ]
  |> list.flatten
}

pub fn pt_1(input: World) {
  let World(rows: rows, columns: columns, antennas: antennas) = input

  antennas
  |> dict.fold([], fn(acc, _name, positions) {
    list.flatten([
      acc,
      positions
        |> list.combination_pairs
        |> list.map(get_antinodes)
        |> list.flatten,
    ])
  })
  |> list.filter(fn(position) {
    position.row >= 0
    && position.row < rows
    && position.column >= 0
    && position.column < columns
  })
  |> list.unique
  |> list.length
}

pub fn pt_2(input: World) {
  input.antennas
  |> dict.fold([], fn(acc, _name, positions) {
    list.flatten([
      acc,
      positions
        |> list.combination_pairs
        |> list.map(get_harmonic_antinodes(_, input))
        |> list.flatten,
    ])
  })
  |> list.unique
  |> list.length
}
