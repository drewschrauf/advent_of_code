import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/set.{type Set}
import gleam/string

pub type Entity {
  Empty
  Wall
}

pub type Direction {
  North
  South
  East
  West
}

pub type Position {
  Position(x: Int, y: Int)
}

pub type Vector {
  Vector(position: Position, direction: Direction)
}

pub type Map =
  Dict(Int, Dict(Int, Entity))

pub type Scenario {
  Scenario(reindeer: Vector, map: Map, end: Position)
}

pub fn parse(input: String) -> Scenario {
  let assert #(map, Some(start), Some(end)) =
    input
    |> string.split("\n")
    |> list.index_fold(#(dict.new(), None, None), fn(acc, row, row_index) {
      let #(row, start, end) =
        row
        |> string.split("")
        |> list.index_fold(
          #(dict.new(), None, None),
          fn(acc, column, column_index) {
            let entity = case column {
              "#" -> Wall
              _ -> Empty
            }
            let start = column == "S"
            let end = column == "E"

            #(
              acc.0 |> dict.insert(column_index, entity),
              case start {
                True -> Some(column_index)
                False -> acc.1
              },
              case end {
                True -> Some(column_index)
                False -> acc.2
              },
            )
          },
        )

      #(
        acc.0 |> dict.insert(row_index, row),
        case start {
          Some(column_index) -> Some(Position(x: column_index, y: row_index))
          None -> acc.1
        },
        case end {
          Some(column_index) -> Some(Position(x: column_index, y: row_index))
          None -> acc.2
        },
      )
    })

  Scenario(reindeer: Vector(position: start, direction: East), map:, end:)
}

type Node {
  Node(parent: Option(Node), g: Int, f: Int)
}

fn get_entity(scenario: Scenario, position: Position) -> Entity {
  let assert Ok(row) = scenario.map |> dict.get(position.y)
  let assert Ok(column) = row |> dict.get(position.x)
  column
}

fn calculate_heuristic(scenario: Scenario, vector: Vector) -> Int {
  int.absolute_value(vector.position.x - scenario.end.x)
  + int.absolute_value(vector.position.y - scenario.end.y)
}

fn get_neighbours(scenario: Scenario, vector: Vector) -> Set(#(Vector, Int)) {
  set.new()
  |> set.insert(#(
    Vector(
      ..vector,
      direction: case vector.direction {
        North -> East
        East -> South
        South -> West
        West -> North
      },
    ),
    1000,
  ))
  |> set.insert(#(
    Vector(
      ..vector,
      direction: case vector.direction {
        North -> West
        West -> South
        South -> East
        East -> North
      },
    ),
    1000,
  ))
  |> set.insert(#(
    Vector(
      ..vector,
      position: case vector.direction {
        North -> Position(..vector.position, y: vector.position.y - 1)
        South -> Position(..vector.position, y: vector.position.y + 1)
        East -> Position(..vector.position, x: vector.position.x + 1)
        West -> Position(..vector.position, x: vector.position.x - 1)
      },
    ),
    1,
  ))
}

fn solve_inner(
  scenario: Scenario,
  open: Dict(Vector, Node),
  closed: Set(Vector),
) {
  let assert Some(#(vector, node)) =
    open
    |> dict.fold(None, fn(acc: Option(#(Vector, Node)), vector, node) {
      case acc {
        None -> Some(#(vector, node))
        Some(#(_, n)) -> {
          case node.f < n.f {
            True -> Some(#(vector, node))
            False -> acc
          }
        }
      }
    })

  let found_end = vector.position == scenario.end

  case found_end {
    True -> {
      node |> io.debug()
      node.g
    }
    False -> {
      let new_open = open |> dict.delete(vector)
      let new_closed = closed |> set.insert(vector)

      let neighbours = get_neighbours(scenario, vector)

      let new_open =
        neighbours
        |> set.fold(new_open, fn(acc, neighbour_entry) {
          let #(neighbour, cost) = neighbour_entry
          let is_closed = new_closed |> set.contains(neighbour)
          let is_empty = scenario |> get_entity(neighbour.position) == Empty

          case !is_closed && is_empty {
            False -> acc
            True -> {
              let is_new_node = !{ acc |> dict.has_key(neighbour) }
              case is_new_node {
                True -> {
                  acc
                  |> dict.insert(
                    neighbour,
                    Node(
                      parent: Some(node),
                      g: node.g + cost,
                      f: node.g + calculate_heuristic(scenario, neighbour),
                    ),
                  )
                }
                False -> {
                  let assert Ok(existing_node) = acc |> dict.get(neighbour)
                  let is_shorter_path = existing_node.g > node.g + cost
                  case is_shorter_path {
                    False -> acc
                    True -> {
                      acc
                      |> dict.insert(
                        neighbour,
                        Node(
                          parent: Some(node),
                          g: node.g + cost,
                          f: node.g + calculate_heuristic(scenario, neighbour),
                        ),
                      )
                    }
                  }
                }
              }
            }
          }
        })

      solve_inner(scenario, new_open, new_closed)
    }
  }
}

fn solve(scenario: Scenario) -> Int {
  let initial_heuristic = calculate_heuristic(scenario, scenario.reindeer)
  solve_inner(
    scenario,
    dict.new()
      |> dict.insert(
        scenario.reindeer,
        Node(parent: None, g: 0, f: initial_heuristic),
      ),
    set.new(),
  )
}

pub fn pt_1(input: Scenario) {
  input |> solve() |> io.debug()
}

pub fn pt_2(input: Scenario) {
  todo as "part 2 not implemented"
}
