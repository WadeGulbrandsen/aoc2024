import gleam/int
import gleam/string
import gleam_community/ansi
import utils/helper

import gleam/list

pub type Alignment {
  Left
  Right
  Center
}

pub type Boarder {
  Boarder(
    udlr: String,
    ud: String,
    lr: String,
    ul: String,
    ur: String,
    dl: String,
    dr: String,
    udl: String,
    udr: String,
    ulr: String,
    dlr: String,
  )
}

pub fn double_boarder() {
  Boarder(
    udlr: "╬",
    ud: "║",
    lr: "═",
    ul: "╝",
    ur: "╚",
    dl: "╗",
    dr: "╔",
    udl: "╣",
    udr: "╠",
    ulr: "╩",
    dlr: "╦",
  )
}

pub fn default_boarder() {
  Boarder(
    udlr: "┼",
    ud: "│",
    lr: "─",
    ul: "┘",
    ur: "└",
    dl: "┐",
    dr: "┌",
    udl: "┤",
    udr: "├",
    ulr: "┴",
    dlr: "┬",
  )
}

pub fn rounded_boarder() {
  Boarder(
    udlr: "┼",
    ud: "│",
    lr: "─",
    ul: "╯",
    ur: "╰",
    dl: "╮",
    dr: "╭",
    udl: "┤",
    udr: "├",
    ulr: "┴",
    dlr: "┬",
  )
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

pub fn table_to_string(table: Table, boarder: Boarder) -> String {
  let heading = row_to_string(table.headings, table.coldefs, boarder)

  let top_boarder =
    make_boarder(
      heading,
      boarder.dr,
      boarder.dl,
      boarder.dlr,
      boarder.ud,
      boarder.lr,
    )

  let rows =
    table.rows
    |> list.map(row_to_string(_, table.coldefs, boarder))
    |> list.prepend(heading)

  let horizontals =
    rows
    |> list.window_by_2
    |> list.map(make_horizontal(_, boarder))
    |> list.prepend(top_boarder)

  case list.last(rows) {
    Error(Nil) -> ""
    Ok(footer) -> {
      let bottom_boarder =
        make_boarder(
          footer,
          boarder.ur,
          boarder.ul,
          boarder.ulr,
          boarder.ud,
          boarder.lr,
        )
      list.interleave([horizontals, rows])
      |> list.append([bottom_boarder])
      |> string.join("\n")
    }
  }
}

fn make_boarder(
  row: String,
  left: String,
  right: String,
  intersection: String,
  verticle: String,
  horizontal: String,
) -> String {
  let chars = row |> ansi.strip |> string.to_graphemes
  let end = list.length(chars) - 1
  list.index_map(chars, fn(char, i) {
    case char {
      _ if i == 0 -> left
      _ if i == end -> right
      c if c == verticle -> intersection
      _ -> horizontal
    }
  })
  |> string.concat
}

fn make_horizontal(rows: #(String, String), boarder: Boarder) -> String {
  let #(above, below) =
    rows |> helper.map_both(ansi.strip) |> helper.map_both(string.to_graphemes)
  let zipped = list.zip(above, below)
  let end = list.length(zipped) - 1
  list.index_map(zipped, fn(z, i) {
    case z |> helper.map_both(fn(x) { x == boarder.ud }) {
      _ if i == 0 -> boarder.udr
      _ if i == end -> boarder.udl
      #(True, True) -> boarder.udlr
      #(True, False) -> boarder.ulr
      #(False, True) -> boarder.dlr
      _ -> boarder.lr
    }
  })
  |> string.concat
}

fn row_to_string(
  row: List(Cell),
  coldefs: List(ColDef),
  boarder: Boarder,
) -> String {
  row
  |> cells_to_string([], coldefs, pad_cell_text)
  |> list.intersperse(boarder.ud)
  |> list.prepend(boarder.ud)
  |> list.append([boarder.ud])
  |> string.join(" ")
}

pub fn table_to_markdown(table: Table) -> String {
  let heading = row_to_markdown(table.headings, table.coldefs)
  let deliminator = make_markdown_deliminator(table.coldefs)
  let rows = table.rows |> list.map(row_to_markdown(_, table.coldefs))
  string.join([heading, deliminator, ..rows], "\n")
}

fn make_markdown_deliminator(coldefs: List(ColDef)) -> String {
  coldefs
  |> list.map(markdown_header)
  |> list.intersperse("|")
  |> list.append(["|"])
  |> list.prepend("|")
  |> string.join(" ")
}

fn markdown_header(coldef: ColDef) -> String {
  case coldef.alignment {
    Left -> ":" <> string.repeat("-", coldef.width - 1)
    Right -> string.repeat("-", coldef.width - 1) <> ":"
    Center -> ":" <> string.repeat("-", coldef.width - 2) <> ":"
  }
}

fn row_to_markdown(row: List(Cell), coldefs: List(ColDef)) -> String {
  row
  |> cells_to_string([], coldefs, pad_cell_markdown)
  |> list.prepend("|")
  |> string.concat()
}

fn cells_to_string(
  cells: List(Cell),
  acc: List(String),
  coldefs: List(ColDef),
  padding_fun: fn(Cell, Int, Alignment) -> String,
) -> List(String) {
  case cells {
    [] -> acc |> list.reverse
    [cell, ..rest] -> {
      let #(before, after) = list.split(coldefs, cell.colspan)
      case before {
        [] -> acc |> list.reverse
        [ColDef(_, alignment), ..] -> {
          let size = before |> list.map(fn(c) { c.width }) |> int.sum
          let text = padding_fun(cell, size, alignment)
          cells_to_string(rest, [text, ..acc], after, padding_fun)
        }
      }
    }
  }
}

fn pad_cell_text(cell: Cell, size: Int, alignment: Alignment) -> String {
  let size = size + { cell.colspan - 1 } * 3
  let pad = size - string.length(cell.text)
  let padded = case pad {
    p if p < 0 -> string.drop_end(cell.text, int.absolute_value(p) + 3) <> "..."
    p if p > 0 ->
      case alignment {
        Left -> string.pad_end(cell.text, size, " ")
        Right -> string.pad_start(cell.text, size, " ")
        Center ->
          string.repeat(" ", p / 2 + p % 2)
          <> cell.text
          <> string.repeat(" ", p / 2)
      }
    _ -> cell.text
  }
  cell.style(padded)
}

fn pad_cell_markdown(cell: Cell, size: Int, alignment: Alignment) -> String {
  let size = size + { cell.colspan - 1 } * 2
  let pad = size - string.length(cell.text)
  let padded = case pad {
    p if p > 0 ->
      case alignment {
        Left -> string.pad_end(cell.text, size, " ")
        Right -> string.pad_start(cell.text, size, " ")
        Center ->
          string.repeat(" ", p / 2 + p % 2)
          <> cell.text
          <> string.repeat(" ", p / 2)
      }
    _ -> cell.text
  }
  " " <> padded <> " " <> string.repeat("|", cell.colspan)
}
