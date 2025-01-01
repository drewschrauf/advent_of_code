import gleam/dict.{type Dict}
import gleam/list
import gleam/regexp
import gleam/string

pub type Scenario {
  Scenario(towels: List(String), patterns: List(String))
}

pub fn parse(input: String) -> Scenario {
  let assert [raw_towels, raw_patterns] = input |> string.split("\n\n")

  let towels = raw_towels |> string.split(", ")
  let patterns = raw_patterns |> string.split("\n")

  Scenario(towels:, patterns:)
}

fn get_valid_count(scenario: Scenario) -> Int {
  let assert Ok(towel_regexp) =
    { "^(?:" <> scenario.towels |> string.join("|") <> ")+$" }
    |> regexp.from_string()

  scenario.patterns
  |> list.count(regexp.check(towel_regexp, _))
}

fn build_valid_patterns(
  cache: Dict(String, Int),
  towels: List(String),
  pattern: String,
) -> Dict(String, Int) {
  case pattern {
    "" -> cache |> dict.insert("", 1)
    _ -> {
      case cache |> dict.get(pattern) {
        Ok(_) -> cache
        Error(_) -> {
          let #(cache, count) =
            towels
            |> list.fold(#(cache, 0), fn(acc, towel) {
              let #(cache, count) = acc

              case string.starts_with(pattern, towel) {
                False -> acc
                True -> {
                  let tail =
                    pattern |> string.drop_start(towel |> string.length())
                  let cache = build_valid_patterns(cache, towels, tail)
                  let assert Ok(tail_count) = cache |> dict.get(tail)
                  #(cache, count + tail_count)
                }
              }
            })

          cache |> dict.insert(pattern, count)
        }
      }
    }
  }
}

pub fn pt_1(input: Scenario) {
  input |> get_valid_count()
}

pub fn pt_2(input: Scenario) {
  let cache =
    input.patterns
    |> list.fold(dict.new(), fn(acc, pattern) {
      acc |> build_valid_patterns(input.towels, pattern)
    })
  input.patterns
  |> list.fold(0, fn(acc, pattern) {
    let assert Ok(count) = cache |> dict.get(pattern)
    acc + count
  })
}
