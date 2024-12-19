import gleam/dict.{type Dict}
import gleam/list
import gleam/result
import gleam/set.{type Set}
import gleam/string

pub type Garden {
  Garden(grid: Dict(Int, Dict(Int, String)))
}

pub fn parse(input: String) -> Garden {
  let grid =
    input
    |> string.split("\n")
    |> list.index_map(fn(row, row_index) {
      #(
        row_index,
        row
          |> string.split("")
          |> list.index_map(fn(column, column_index) { #(column_index, column) })
          |> dict.from_list,
      )
    })
    |> dict.from_list

  Garden(grid: grid)
}

type Position {
  Position(row: Int, column: Int)
}

type Direction {
  Up
  Down
  Left
  Right
}

type Perimeter {
  Perimeter(position: Position, direction: Direction)
}

type Region {
  Region(positions: Set(Position), perimeters: Set(Perimeter))
}

fn map_region_from_inner(
  positions_to_check: List(Position),
  checked_positions: Set(Position),
  name: String,
  garden: Garden,
) -> Region {
  case positions_to_check {
    [] -> Region(positions: set.new(), perimeters: set.new())
    _ -> {
      let assert Ok(position) = positions_to_check |> list.first
      let positions_to_check = positions_to_check |> list.drop(1)

      let #(new_positions_to_check, perimeters) =
        [Up, Down, Left, Right]
        |> list.fold(#([], set.new()), fn(acc, direction) {
          let step = case direction {
            Up -> #(-1, 0)
            Down -> #(1, 0)
            Left -> #(0, -1)
            Right -> #(0, 1)
          }

          let next_position =
            Position(
              row: position.row + step.0,
              column: position.column + step.1,
            )

          let next_position_in_region =
            {
              use row <- result.try(garden.grid |> dict.get(next_position.row))
              use column <- result.try(row |> dict.get(next_position.column))
              case column == name {
                False -> Error(Nil)
                True -> Ok(Nil)
              }
            }
            |> result.is_ok

          case next_position_in_region {
            False -> #(
              acc.0,
              acc.1
                |> set.insert(Perimeter(
                  position: position,
                  direction: direction,
                )),
            )
            True -> {
              let position_already_found =
                checked_positions |> set.contains(next_position)
                || positions_to_check |> list.contains(next_position)

              case position_already_found {
                True -> acc
                False -> #([next_position, ..acc.0], acc.1)
              }
            }
          }
        })

      let inner =
        map_region_from_inner(
          list.flatten([new_positions_to_check, positions_to_check]),
          checked_positions |> set.insert(position),
          name,
          garden,
        )

      Region(
        positions: inner.positions |> set.insert(position),
        perimeters: inner.perimeters |> set.union(perimeters),
      )
    }
  }
}

fn map_region_from(position: Position, name: String, garden: Garden) -> Region {
  map_region_from_inner([position], set.new(), name, garden)
}

fn map_regions(garden: Garden) -> Set(Region) {
  let map_result =
    garden.grid
    |> dict.keys
    |> list.fold(#(set.new(), set.new()), fn(acc, row_index) {
      let assert Ok(row) = garden.grid |> dict.get(row_index)

      row
      |> dict.keys
      |> list.fold(acc, fn(acc, column_index) {
        let position = Position(row: row_index, column: column_index)
        let position_already_mapped = acc.1 |> set.contains(position)

        case position_already_mapped {
          True -> acc
          False -> {
            let assert Ok(name) = row |> dict.get(column_index)
            let region = position |> map_region_from(name, garden)

            #(acc.0 |> set.insert(region), acc.1 |> set.union(region.positions))
          }
        }
      })
    })

  map_result.0
}

fn get_non_contiguous_perimeter_count_inner(
  perimeters_to_check: List(Perimeter),
  perimeters: Set(Perimeter),
) -> Int {
  case perimeters_to_check {
    [] -> 0
    _ -> {
      let assert Ok(perimeter) = perimeters_to_check |> list.first
      let perimeters_to_check = perimeters_to_check |> list.drop(1)

      let has_sibling =
        perimeters
        |> set.contains({
          case perimeter.direction {
            Up | Down ->
              Perimeter(
                ..perimeter,
                position: Position(
                  ..perimeter.position,
                  column: perimeter.position.column - 1,
                ),
              )
            Left | Right ->
              Perimeter(
                ..perimeter,
                position: Position(
                  ..perimeter.position,
                  row: perimeter.position.row - 1,
                ),
              )
          }
        })

      {
        perimeters_to_check
        |> get_non_contiguous_perimeter_count_inner(perimeters)
      }
      + case has_sibling {
        True -> 0
        False -> 1
      }
    }
  }
}

fn get_non_contiguous_perimeter_count(perimeters: Set(Perimeter)) -> Int {
  perimeters
  |> set.to_list
  |> get_non_contiguous_perimeter_count_inner(perimeters)
}

pub fn pt_1(input: Garden) -> Int {
  input
  |> map_regions
  |> set.fold(0, fn(acc, region) {
    acc
    + { { region.positions |> set.size } * { region.perimeters |> set.size } }
  })
}

pub fn pt_2(input: Garden) {
  input
  |> map_regions
  |> set.fold(0, fn(acc, region) {
    acc
    + {
      { region.positions |> set.size }
      * { region.perimeters |> get_non_contiguous_perimeter_count }
    }
  })
}
