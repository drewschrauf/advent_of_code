import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
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
  Scenario(map: Map, start: Vector, end: Position)
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

  Scenario(map:, start: Vector(position: start, direction: East), end:)
}

type Node {
  Node(
    searched: Bool,
    neighbours: List(Vector),
    running_path_cost: Int,
    total_path_cost_estimate: Int,
  )
}

type Solution {
  Solution(cost: Int, paths: List(List(Vector)))
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

fn get_neighbours(vector: Vector) -> Set(#(Vector, Int)) {
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

fn get_all_paths(
  nodes: Dict(Vector, Node),
  vector: Vector,
) -> List(List(Vector)) {
  let assert Ok(node) = nodes |> dict.get(vector)

  case node.neighbours {
    [] -> [[vector]]
    _ ->
      node.neighbours
      |> list.map(fn(neighbour) {
        get_all_paths(nodes, neighbour)
        |> list.map(fn(path) { [vector, ..path] })
      })
      |> list.flatten()
  }
}

fn get_cheapest_estimate(nodes: Dict(Vector, Node)) -> #(Vector, Node) {
  let assert Some(entry) =
    nodes
    |> dict.fold(None, fn(acc: Option(#(Vector, Node)), vector, node) {
      case acc, node.searched {
        None, False -> Some(#(vector, node))
        Some(#(_, n)), False -> {
          case node.total_path_cost_estimate < n.total_path_cost_estimate {
            True -> Some(#(vector, node))
            False -> acc
          }
        }
        _, True -> acc
      }
    })

  entry
}

fn solve_inner(scenario: Scenario, nodes: Dict(Vector, Node)) -> Solution {
  let #(vector, node) = nodes |> get_cheapest_estimate()

  let found_end = vector.position == scenario.end

  case found_end {
    True ->
      Solution(
        cost: node.running_path_cost,
        paths: nodes |> get_all_paths(vector),
      )
    False -> {
      let nodes = nodes |> dict.insert(vector, Node(..node, searched: True))

      let neighbours = get_neighbours(vector)

      let nodes =
        neighbours
        |> set.fold(nodes, fn(acc, neighbour_entry) {
          let #(neighbour, cost) = neighbour_entry
          let entity = get_entity(scenario, neighbour.position)

          case entity {
            Wall -> acc
            Empty -> {
              let neighour_node = acc |> dict.get(neighbour)
              let new_neighour_node = case neighour_node {
                Error(_) ->
                  Node(
                    searched: False,
                    neighbours: [vector],
                    running_path_cost: node.running_path_cost + cost,
                    total_path_cost_estimate: node.running_path_cost
                      + cost
                      + calculate_heuristic(scenario, neighbour),
                  )
                Ok(existing_neighbour_node) -> {
                  case
                    int.compare(
                      node.running_path_cost + cost,
                      existing_neighbour_node.running_path_cost,
                    )
                  {
                    order.Lt -> {
                      Node(
                        ..existing_neighbour_node,
                        neighbours: [vector],
                        running_path_cost: node.running_path_cost + cost,
                        total_path_cost_estimate: node.running_path_cost
                          + cost
                          + calculate_heuristic(scenario, neighbour),
                      )
                    }
                    order.Eq -> {
                      Node(
                        ..existing_neighbour_node,
                        neighbours: [
                          vector,
                          ..existing_neighbour_node.neighbours
                        ],
                      )
                    }
                    order.Gt -> {
                      existing_neighbour_node
                    }
                  }
                }
              }

              acc |> dict.insert(neighbour, new_neighour_node)
            }
          }
        })

      solve_inner(scenario, nodes)
    }
  }
}

fn solve(scenario: Scenario) {
  solve_inner(
    scenario,
    dict.new()
      |> dict.insert(
        scenario.start,
        Node(
          searched: False,
          neighbours: [],
          running_path_cost: 0,
          total_path_cost_estimate: calculate_heuristic(
            scenario,
            scenario.start,
          ),
        ),
      ),
  )
}

pub fn pt_1(input: Scenario) {
  let solution = input |> solve()
  solution.cost
}

pub fn pt_2(input: Scenario) {
  let solution = input |> solve()
  solution.paths
  |> list.flatten()
  |> list.map(fn(vector) { vector.position })
  |> list.unique()
  |> list.length()
}
