import gleam/int
import gleam/string

import gleam/list

pub type Alignment {
  Left
  Right
  Center
}

pub type Cell {
  Cell(text: String, colspan: Int, style: fn(String) -> String)
}

pub type ColDef {
  ColDef(width: Int, alignment: Alignment)
}

pub type Table {
  Table(headings: List(Cell), coldefs: List(ColDef), rows: List(List(Cell)))
}

pub fn table_to_string(table: Table) -> String {
  let heading = row_to_string(table.headings, table.coldefs)
  let separator = make_separator(table.coldefs)
  let rows = table.rows |> list.map(row_to_string(_, table.coldefs))
  string.join([heading, separator, ..rows], "\n")
}

fn make_separator(coldefs: List(ColDef)) -> String {
  coldefs
  |> list.map(header)
  |> list.intersperse("|")
  |> list.append(["|"])
  |> list.prepend("|")
  |> string.join(" ")
}

fn header(coldef: ColDef) -> String {
  case coldef.alignment {
    Left -> ":" <> string.repeat("-", coldef.width - 1)
    Right -> string.repeat("-", coldef.width - 1) <> ":"
    Center -> ":" <> string.repeat("-", coldef.width - 2) <> ":"
  }
}

fn row_to_string(row: List(Cell), coldefs: List(ColDef)) -> String {
  row
  |> cells_to_strings([], coldefs)
  |> list.prepend("|")
  |> string.concat()
}

fn cells_to_strings(
  cells: List(Cell),
  acc: List(String),
  coldefs: List(ColDef),
) -> List(String) {
  case cells {
    [] -> acc |> list.reverse
    [cell, ..rest] -> {
      let #(before, after) = list.split(coldefs, cell.colspan)
      case before {
        [] -> acc |> list.reverse
        [ColDef(_, alignment), ..] -> {
          let size = before |> list.map(fn(c) { c.width }) |> int.sum
          let text = pad_cell(cell, size, alignment)
          cells_to_strings(rest, [text, ..acc], after)
        }
      }
    }
  }
}

fn pad_cell(cell: Cell, size: Int, alignment: Alignment) -> String {
  let size = size + { cell.colspan - 1 } * 2
  let pad = size - string.length(cell.text)
  let padded = case pad {
    0 -> cell.text
    p if p < 0 -> string.drop_end(cell.text, int.absolute_value(p) + 3) <> "..."
    p ->
      case alignment {
        Left -> string.pad_end(cell.text, size, " ")
        Right -> string.pad_start(cell.text, size, " ")
        Center ->
          string.repeat(" ", p / 2) <> cell.text |> string.pad_end(size, " ")
      }
  }
  " " <> cell.style(padded) <> " " <> string.repeat("|", cell.colspan)
}
