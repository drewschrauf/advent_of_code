import gleam/dict.{type Dict}
import gleam/list
import gleam/result
import gleam/string

type Board =
  Dict(Int, Dict(Int, String))

pub fn parse(input: String) -> Board {
  input
  |> string.split("\n")
  |> list.map(fn(row) {
    row
    |> string.split("")
    |> list.index_map(fn(v, i) { #(i, v) })
    |> dict.from_list
  })
  |> list.index_map(fn(v, i) { #(i, v) })
  |> dict.from_list
}

type SearchPath =
  List(#(Int, Int, String))

fn check_search_path(board: Board, path: SearchPath) -> Bool {
  path
  |> list.map(fn(p) {
    use row <- result.try(board |> dict.get(p.0))
    use char <- result.try(row |> dict.get(p.1))
    case char {
      c if c == p.2 -> Ok(True)
      _ -> Error(Nil)
    }
  })
  |> list.all(result.is_ok)
}

fn search_board(
  board: Board,
  search_path_generator: fn(Int, Int) -> List(SearchPath),
) -> Int {
  board
  |> dict.fold(0, fn(acc, row_index, row) {
    acc
    + {
      row
      |> dict.fold(0, fn(acc, column_index, _char) {
        let this_location_count =
          search_path_generator(row_index, column_index)
          |> list.map(fn(path) { check_search_path(board, path) })
          |> list.count(fn(r) { r == True })
        acc + this_location_count
      })
    }
  })
}

fn generate_word_search_paths(
  row_index: Int,
  column_index: Int,
) -> List(SearchPath) {
  [#(0, 1), #(1, 1), #(1, 0), #(1, -1), #(0, -1), #(-1, -1), #(-1, 0), #(-1, 1)]
  |> list.map(fn(stepper) {
    "XMAS"
    |> string.split("")
    |> list.index_map(fn(char, idx) {
      #(row_index + idx * stepper.0, column_index + idx * stepper.1, char)
    })
  })
}

pub fn pt_1(input: Board) {
  input
  |> search_board(generate_word_search_paths)
}

fn generate_x_mas_search_paths(
  row_index: Int,
  column_index: Int,
) -> List(SearchPath) {
  [#(-1, -1), #(1, -1), #(-1, 1), #(1, 1)]
  |> list.map(fn(offset) {
    [
      #(row_index, column_index, "A"),
      #(row_index + offset.0, column_index + offset.0, "M"),
      #(row_index + offset.0 * -1, column_index + offset.0 * -1, "S"),
      #(row_index + offset.1, column_index + offset.1 * -1, "M"),
      #(row_index + offset.1 * -1, column_index + offset.1, "S"),
    ]
  })
}

pub fn pt_2(input: Board) {
  input
  |> search_board(generate_x_mas_search_paths)
}
