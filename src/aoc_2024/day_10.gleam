import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/result
import gleam/string

pub type Position {
  Position(row: Int, column: Int)
}

pub type Map {
  Map(grid: Dict(Int, Dict(Int, Int)), trailheads: List(Position))
}

pub fn parse(input: String) -> Map {
  let #(rows, trailheads) =
    input
    |> string.split("\n")
    |> list.index_fold(#([], []), fn(acc, row, row_index) {
      let #(columns, trailheads) =
        row
        |> string.split("")
        |> list.index_fold(#([], []), fn(acc, column, column_index) {
          let #(columns, trailheads) = acc

          let num = case column |> int.parse {
            Ok(n) -> n
            Error(_) -> -1
          }

          let new_trailheads = case num {
            0 -> [Position(row: row_index, column: column_index), ..trailheads]
            _ -> trailheads
          }

          #([#(column_index, num), ..columns], new_trailheads)
        })

      #(
        [#(row_index, columns |> dict.from_list), ..acc.0],
        list.flatten([acc.1, trailheads]),
      )
    })

  let grid = rows |> dict.from_list

  Map(grid: grid, trailheads: trailheads)
}

fn get_all_trails(
  position: Position,
  level: Int,
  map: Map,
) -> List(List(Position)) {
  [#(-1, 0), #(0, 1), #(1, 0), #(0, -1)]
  |> list.map(fn(step) {
    let next_row_index = position.row + step.0
    let next_column_index = position.column + step.1
    let next_position = Position(row: next_row_index, column: next_column_index)

    use next_row <- result.try(map.grid |> dict.get(next_row_index))
    use next_column <- result.try(next_row |> dict.get(next_column_index))

    case next_column {
      9 if level == 8 -> Ok([[next_position]])
      n if n == level + 1 ->
        Ok(
          get_all_trails(next_position, level + 1, map)
          |> list.map(fn(trail) { [next_position, ..trail] }),
        )
      _ -> Error(Nil)
    }
  })
  |> list.fold([], fn(acc, result) {
    case result {
      Error(Nil) -> acc
      Ok(list) -> list.flatten([list, acc])
    }
  })
  |> list.unique
}

pub fn pt_1(input: Map) {
  input.trailheads
  |> list.map(fn(trailhead) {
    trailhead
    |> get_all_trails(0, input)
    |> list.map(fn(trail) {
      let assert Ok(end) = trail |> list.reverse |> list.first
      end
    })
    |> list.unique
  })
  |> list.map(list.length)
  |> list.fold(0, int.add)
}

pub fn pt_2(input: Map) {
  input.trailheads
  |> list.map(get_all_trails(_, 0, input))
  |> list.map(list.length)
  |> list.fold(0, int.add)
}
