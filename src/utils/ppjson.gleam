import glam/doc.{type Document}
import gleam/bool
import gleam/float
import gleam/int
import gleam/list
import gleam/string

pub type JSON {
  String(String)
  Int(Int)
  Float(Float)
  Bool(Bool)
  Null
  Array(List(JSON))
  Object(List(#(String, JSON)))
}

fn comma() -> Document {
  doc.from_string(",")
}

fn json_to_doc(json: JSON) -> Document {
  case json {
    String(s) -> string_to_doc(s)
    Int(i) -> i |> int.to_string |> doc.from_string
    Float(f) -> f |> float.to_string |> doc.from_string
    Bool(b) -> b |> bool.to_string |> string.uppercase |> doc.from_string
    Null -> doc.from_string("null")
    Array(objects) -> array_to_doc(objects)
    Object(fields) -> object_to_doc(fields)
  }
}

fn string_to_doc(string: String) -> Document {
  doc.from_string("\"" <> string <> "\"")
}

fn field_to_doc(field: #(String, JSON)) -> Document {
  let #(key, value) = field
  let key_doc = string_to_doc(key)
  let value_doc = json_to_doc(value)
  [key_doc, doc.from_string(": "), value_doc] |> doc.concat
}

fn parenthesise(document: Document, open: String, close: String) -> Document {
  document
  |> doc.prepend_docs([doc.from_string(open), doc.soft_break])
  |> doc.nest(2)
  |> doc.append_docs([doc.soft_break, doc.from_string(close)])
  |> doc.group
}

fn array_to_doc(objects: List(JSON)) -> Document {
  objects
  |> list.map(json_to_doc)
  |> doc.concat_join([comma(), doc.space])
  |> parenthesise("[", "]")
}

fn object_to_doc(fields: List(#(String, JSON))) -> Document {
  fields
  |> list.map(field_to_doc)
  |> doc.concat_join([comma(), doc.space])
  |> parenthesise("{", "}")
}

pub fn to_string(json: JSON, width: Int) -> String {
  json |> json_to_doc |> doc.to_string(width)
}
