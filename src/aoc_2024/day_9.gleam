import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/string

pub type Byte {
  File(Int)
  Empty
}

pub type Disk {
  Disk(data: Dict(Int, Byte), size: Int)
}

fn alloc(
  disk: Dict(Int, Byte),
  pointer: Int,
  size: Int,
  byte: Byte,
) -> #(Dict(Int, Byte), Int) {
  case size {
    0 -> #(disk, pointer)
    _ -> {
      let new_disk = disk |> dict.insert(pointer, byte)
      alloc(new_disk, pointer + 1, size - 1, byte)
    }
  }
}

pub fn parse(input: String) -> Disk {
  let result =
    input
    |> string.split("")
    |> list.index_fold(#(dict.new(), 0, 0), fn(acc, char, index) {
      let #(disk, pointer, file) = acc

      let assert Ok(size) = char |> int.parse
      let is_file = index |> int.is_even

      case is_file {
        True -> {
          let #(new_disk, new_pointer) = alloc(disk, pointer, size, File(file))
          #(new_disk, new_pointer, file + 1)
        }
        False -> {
          let #(new_disk, new_pointer) = alloc(disk, pointer, size, Empty)
          #(new_disk, new_pointer, file)
        }
      }
    })

  let data = result.0
  let size = data |> dict.keys |> list.length

  Disk(data: data, size: size)
}

fn compact_inner(disk: Disk, start_pointer: Int, end_pointer: Int) -> Disk {
  let complete = start_pointer >= end_pointer

  case complete {
    True -> disk
    False -> {
      let assert Ok(start_byte) = disk.data |> dict.get(start_pointer)
      let assert Ok(end_byte) = disk.data |> dict.get(end_pointer)

      case start_byte, end_byte {
        Empty, Empty -> compact_inner(disk, start_pointer, end_pointer - 1)
        File(_), Empty ->
          compact_inner(disk, start_pointer + 1, end_pointer - 1)
        File(_), File(_) -> compact_inner(disk, start_pointer + 1, end_pointer)
        Empty, File(_) as f -> {
          let new_disk =
            Disk(
              ..disk,
              data: disk.data
                |> dict.insert(start_pointer, f)
                |> dict.insert(end_pointer, Empty),
            )
          compact_inner(new_disk, start_pointer + 1, end_pointer - 1)
        }
      }
    }
  }
}

fn compact(disk: Disk) {
  compact_inner(disk, 0, disk.size - 1)
}

fn get_size(disk: Disk, pointer: Int, byte: Byte) -> Int {
  let byte_at_pointer = disk.data |> dict.get(pointer)

  case byte_at_pointer {
    Ok(found_byte) if found_byte == byte -> {
      1 + get_size(disk, pointer + 1, byte)
    }
    _ -> 0
  }
}

fn is_at_start_of_file(disk: Disk, pointer: Int) {
  let byte_at_pointer = disk.data |> dict.get(pointer)
  let byte_before_pointer = disk.data |> dict.get(pointer - 1)

  byte_at_pointer != byte_before_pointer && byte_at_pointer != Ok(Empty)
}

fn is_at_start_of_empty(disk: Disk, pointer: Int) {
  let byte_at_pointer = disk.data |> dict.get(pointer)
  let byte_before_pointer = disk.data |> dict.get(pointer - 1)

  byte_at_pointer != byte_before_pointer && byte_at_pointer == Ok(Empty)
}

fn move_file(
  disk: Disk,
  source_pointer: Int,
  destination_pointer: Int,
  remaining_bytes: Int,
) -> Disk {
  case remaining_bytes {
    0 -> disk
    _ -> {
      let assert Ok(byte_at_source_pointer) =
        disk.data |> dict.get(source_pointer)

      Disk(
        ..disk,
        data: disk.data
          |> dict.insert(destination_pointer, byte_at_source_pointer)
          |> dict.insert(source_pointer, Empty),
      )
      |> move_file(
        source_pointer + 1,
        destination_pointer + 1,
        remaining_bytes - 1,
      )
    }
  }
}

fn find_space(
  disk: Disk,
  pointer: Int,
  original_location: Int,
  required_size: Int,
) {
  let invalid = pointer >= disk.size || original_location <= pointer

  case invalid {
    True -> Error(Nil)
    False -> {
      let assert Ok(byte_at_pointer) = disk.data |> dict.get(pointer)
      case byte_at_pointer {
        File(_) ->
          disk
          |> find_space(pointer + 1, original_location, required_size)
        Empty -> {
          let start_of_empty = disk |> is_at_start_of_empty(pointer)
          case start_of_empty {
            True -> {
              let available_space = disk |> get_size(pointer, Empty)
              case required_size <= available_space {
                True -> Ok(pointer)
                False ->
                  disk
                  |> find_space(pointer + 1, original_location, required_size)
              }
            }
            False ->
              disk
              |> find_space(pointer + 1, original_location, required_size)
          }
        }
      }
    }
  }
}

fn full_compact_inner(disk: Disk, end_pointer: Int) -> Disk {
  let complete = end_pointer == 0

  case complete {
    True -> disk
    False -> {
      let is_at_start_of_file = disk |> is_at_start_of_file(end_pointer)
      case is_at_start_of_file {
        False -> disk |> full_compact_inner(end_pointer - 1)
        True -> {
          let assert Ok(file_at_pointer) = disk.data |> dict.get(end_pointer)
          let file_size = disk |> get_size(end_pointer, file_at_pointer)

          let destination = disk |> find_space(0, end_pointer, file_size)

          case destination {
            Ok(destination_pointer) -> {
              disk
              |> move_file(end_pointer, destination_pointer, file_size)
              |> full_compact_inner(end_pointer - 1)
            }
            _ -> disk |> full_compact_inner(end_pointer - 1)
          }
        }
      }
    }
  }
}

fn full_compact(disk: Disk) {
  full_compact_inner(disk, disk.size - 1)
}

fn checksum(disk: Disk) {
  disk.data
  |> dict.keys
  |> list.fold(0, fn(acc, location) {
    let assert Ok(byte) = disk.data |> dict.get(location)
    case byte {
      Empty -> acc
      File(f) -> acc + location * f
    }
  })
}

pub fn pt_1(input: Disk) {
  input |> compact |> checksum
}

pub fn pt_2(input: Disk) {
  input |> full_compact |> checksum
}
