import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/regexp
import gleam/result

pub type Vector {
  Vector(x: Int, y: Int)
}

pub type Robot {
  Robot(position: Vector, velocity: Vector)
}

pub fn parse(input: String) -> List(Robot) {
  let assert Ok(robot_re) =
    regexp.from_string("p=(-?\\d+),(-?\\d+) v=(-?\\d+),(-?\\d+)")
  robot_re
  |> regexp.scan(input)
  |> list.map(fn(robot_match) {
    let assert [px, py, vx, vy] =
      robot_match.submatches
      |> list.map(fn(raw_value) {
        let assert Some(string_value) = raw_value
        let assert Ok(value) = string_value |> int.parse
        value
      })
    Robot(position: Vector(x: px, y: py), velocity: Vector(x: vx, y: vy))
  })
}

fn move_robots(
  robots: List(Robot),
  grid_width: Int,
  grid_height: Int,
  seconds: Int,
) {
  robots
  |> list.map(fn(robot) {
    let assert Ok(x) =
      { robot.position.x + robot.velocity.x * seconds }
      |> int.modulo(grid_width)
    let assert Ok(y) =
      { robot.position.y + robot.velocity.y * seconds }
      |> int.modulo(grid_height)

    Robot(..robot, position: Vector(x:, y:))
  })
}

type Quadrant {
  NE
  SE
  SW
  NW
}

fn find_quadrants(
  robots: List(Robot),
  grid_width: Int,
  grid_height: Int,
) -> Dict(Quadrant, Int) {
  let center_x =
    { { grid_width |> int.to_float } /. 2.0 }
    |> float.floor()
    |> float.round()
  let center_y =
    { { grid_height |> int.to_float } /. 2.0 }
    |> float.floor()
    |> float.round()

  robots
  |> list.fold(dict.new(), fn(acc, robot) {
    let west = robot.position.x < center_x
    let east = robot.position.x > center_x
    let north = robot.position.y < center_y
    let south = robot.position.y > center_y

    let quadrant = case west, east, north, south {
      True, False, True, False -> Some(NW)
      False, True, True, False -> Some(NE)
      True, False, False, True -> Some(SW)
      False, True, False, True -> Some(SE)
      _, _, _, _ -> None
    }

    case quadrant {
      Some(q) -> {
        acc
        |> dict.insert(q, { acc |> dict.get(q) |> result.unwrap(0) } + 1)
      }
      None -> acc
    }
  })
}

pub fn pt_1(input: List(Robot)) {
  input
  |> move_robots(101, 103, 100)
  |> find_quadrants(101, 103)
  |> dict.to_list()
  |> list.fold(1, fn(acc, quadrant) { acc * quadrant.1 })
}

pub fn find_xmas_tree(
  robots: List(Robot),
  grid_width: Int,
  grid_height: Int,
  iteration: Int,
  max: Int,
) -> Result(Int, Nil) {
  case iteration > max {
    True -> Error(Nil)
    False -> {
      let moved_robots =
        robots
        |> move_robots(grid_width, grid_height, iteration)
      let neighbour_count = {
        moved_robots
        |> list.fold(0, fn(acc, r) {
          let neighbours =
            moved_robots
            |> list.count(fn(rr) {
              rr.position.x >= r.position.x - 1
              && rr.position.x <= r.position.x + 1
              && rr.position.y >= r.position.y - 1
              && rr.position.y <= r.position.y + 1
            })
          acc + neighbours - 1
        })
      }
      case neighbour_count > 1000 {
        True -> {
          Ok(iteration)
        }
        False -> {
          find_xmas_tree(robots, grid_width, grid_height, iteration + 1, max)
        }
      }
    }
  }
}

pub fn pt_2(input: List(Robot)) {
  input |> find_xmas_tree(101, 103, 1, 100_000) |> result.unwrap(0)
}
