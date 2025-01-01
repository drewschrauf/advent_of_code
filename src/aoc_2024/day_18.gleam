import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order.{Eq, Gt, Lt}
import gleam/regexp

pub type Position {
  Position(x: Int, y: Int)
}

pub fn parse(input: String) -> List(Position) {
  let assert Ok(position_regexp) = "(\\d+),(\\d+)" |> regexp.from_string()
  let matches = position_regexp |> regexp.scan(input)

  matches
  |> list.map(fn(match) {
    let assert [x, y] =
      match.submatches
      |> list.map(fn(submatch) {
        let assert Some(raw_num) = submatch
        let assert Ok(num) = raw_num |> int.parse()
        num
      })
    Position(x:, y:)
  })
}

type Scenario {
  Scenario(positions: List(Position), width: Int, height: Int, time: Int)
}

type Node {
  Node(searched: Bool, g: Int, f: Int)
}

fn calculate_heuristic(scenario: Scenario, position: Position) {
  scenario.width - 1 - position.x + scenario.height - 1 - position.y
}

fn get_neighbours(scenario: Scenario, position: Position) -> List(Position) {
  [
    Position(x: position.x - 1, y: position.y),
    Position(x: position.x + 1, y: position.y),
    Position(x: position.x, y: position.y - 1),
    Position(x: position.x, y: position.y + 1),
  ]
  |> list.filter(fn(p) {
    p.x >= 0
    && p.x < scenario.width
    && p.y >= 0
    && p.y < scenario.height
    && !{
      scenario.positions
      |> list.take(scenario.time)
      |> list.contains(p)
    }
  })
}

fn solve_inner(scenario: Scenario, nodes: Dict(Position, Node)) {
  let cheapest_entry =
    nodes
    |> dict.fold(None, fn(acc: Option(#(Position, Node)), position, node) {
      case acc, node.searched {
        None, False -> Some(#(position, node))
        Some(#(_, n)), False if node.f < n.f -> Some(#(position, node))
        _, _ -> acc
      }
    })

  case cheapest_entry {
    None -> Error(Nil)
    Some(#(position, node)) -> {
      let at_end =
        position.x == scenario.width - 1 && position.y == scenario.height - 1

      case at_end {
        True -> Ok(node.g)
        False -> {
          let nodes =
            nodes |> dict.insert(position, Node(..node, searched: True))

          get_neighbours(scenario, position)
          |> list.fold(nodes, fn(acc, neighbour) {
            let neighbour_node = acc |> dict.get(neighbour)
            case neighbour_node {
              Error(_) ->
                acc
                |> dict.insert(
                  neighbour,
                  Node(
                    searched: False,
                    g: node.g + 1,
                    f: node.g + 1 + calculate_heuristic(scenario, neighbour),
                  ),
                )
              Ok(existing_neighbour_node) -> {
                case int.compare(node.g + 1, existing_neighbour_node.g) {
                  Lt ->
                    acc
                    |> dict.insert(
                      neighbour,
                      Node(
                        ..existing_neighbour_node,
                        g: node.g + 1,
                        f: node.g + 1 + calculate_heuristic(scenario, neighbour),
                      ),
                    )
                  Eq | Gt -> acc
                }
              }
            }
          })
          |> solve_inner(scenario, _)
        }
      }
    }
  }
}

fn solve(scenario: Scenario) {
  let start = Position(x: 0, y: 0)
  solve_inner(
    scenario,
    dict.new()
      |> dict.insert(
        start,
        Node(searched: False, g: 0, f: calculate_heuristic(scenario, start)),
      ),
  )
}

pub fn pt_1(input: List(Position)) {
  let assert Ok(result) =
    Scenario(positions: input, width: 71, height: 71, time: 1024)
    |> solve()
  result
}

fn find_last_success(
  positions: List(Position),
  width: Int,
  height: Int,
  success: Int,
  failure: Int,
) {
  let guess = success + { failure - success } / 2
  case guess == success {
    True -> success
    False ->
      case solve(Scenario(positions:, width:, height:, time: guess)) {
        Ok(_) -> find_last_success(positions, width, height, guess, failure)
        Error(_) -> find_last_success(positions, width, height, success, guess)
      }
  }
}

pub fn pt_2(input: List(Position)) {
  let last_success = find_last_success(input, 71, 71, 0, list.length(input) - 1)
  let assert [position, ..] = input |> list.drop(last_success)
  position.x |> int.to_string() <> "," <> position.y |> int.to_string()
}
