// JsonValue -> compact JSON string.

///|
pub fn json_stringify(value : JsonValue) -> String {
  match value {
    JNull => "null"
    JBool(b) => if b { "true" } else { "false" }
    JNumber(n) => format_json_number(n)
    JString(s) => json_escape(s)
    JArray(items) => stringify_array(items)
    JObject(fields) => stringify_object(fields)
  }
}

///|
fn format_json_number(n : Double) -> String {
  let i = n.to_int()
  if n == i.to_double() {
    i.to_string()
  } else {
    n.to_string()
  }
}

///|
pub fn json_escape(s : String) -> String {
  let mut out = "\""
  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i]
    if c == '\"' {
      out = out + "\\\""
    } else if c == '\\' {
      out = out + "\\\\"
    } else if c == '\n' {
      out = out + "\\n"
    } else if c == '\r' {
      out = out + "\\r"
    } else if c == '\t' {
      out = out + "\\t"
    } else if c.to_int() < 32 {
      out = out +
        "\\u00" +
        hex_digit(c.to_int() / 16) +
        hex_digit(c.to_int() % 16)
    } else {
      out = out + s[i:i + 1].to_owned()
    }
  }
  out + "\""
}

///|
fn hex_digit(n : Int) -> String {
  match n {
    0 => "0"
    1 => "1"
    2 => "2"
    3 => "3"
    4 => "4"
    5 => "5"
    6 => "6"
    7 => "7"
    8 => "8"
    9 => "9"
    10 => "a"
    11 => "b"
    12 => "c"
    13 => "d"
    14 => "e"
    15 => "f"
    _ => "0"
  }
}

///|
fn stringify_array(items : Array[JsonValue]) -> String {
  let mut out = "["
  for i = 0; i < items.length(); i = i + 1 {
    out = out + json_stringify(items[i])
    if i < items.length() - 1 {
      out = out + ","
    }
  }
  out + "]"
}

///|
fn stringify_object(fields : Array[JsonField]) -> String {
  let mut out = "{"
  for i = 0; i < fields.length(); i = i + 1 {
    let field = fields[i]
    out = out + json_escape(field.key) + ":" + json_stringify(field.value)
    if i < fields.length() - 1 {
      out = out + ","
    }
  }
  out + "}"
}
