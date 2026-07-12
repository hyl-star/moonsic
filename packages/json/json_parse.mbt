// Recursive-descent parser for the subset needed by moonsic FFI.

///|
pub fn json_parse(input : String) -> Result[JsonValue, JsonError] {
  let len = input.length()
  let pos = skip_ws(input, 0, len)
  if pos >= len {
    return Err(ParseError("empty input"))
  }
  match parse_value(input, pos, len) {
    Ok((value, next)) => {
      let after = skip_ws(input, next, len)
      if after < len {
        Err(ParseError("trailing characters after JSON value"))
      } else {
        Ok(value)
      }
    }
    Err(msg) => Err(ParseError(msg))
  }
}

///|
fn skip_ws(input : String, pos : Int, len : Int) -> Int {
  let mut p = pos
  while p < len {
    let c = input[p]
    if c == ' ' || c == '\t' || c == '\n' || c == '\r' {
      p = p + 1
    } else {
      break
    }
  }
  p
}

///|
fn parse_value(
  input : String,
  pos : Int,
  len : Int,
) -> Result[(JsonValue, Int), String] {
  let p = skip_ws(input, pos, len)
  if p >= len {
    return Err("unexpected end of JSON value")
  }
  let c = input[p]
  if c == '{' {
    parse_object(input, p, len)
  } else if c == '[' {
    parse_array(input, p, len)
  } else if c == '\"' {
    match parse_string(input, p, len) {
      Ok((s, next)) => Ok((JString(s), next))
      Err(e) => Err(e)
    }
  } else if c == 't' {
    parse_literal(input, p, len, "true", JBool(true))
  } else if c == 'f' {
    parse_literal(input, p, len, "false", JBool(false))
  } else if c == 'n' {
    parse_literal(input, p, len, "null", JNull)
  } else if c == '-' || (c >= '0' && c <= '9') {
    parse_number(input, p, len)
  } else {
    Err("invalid JSON character")
  }
}

///|
fn parse_literal(
  input : String,
  pos : Int,
  len : Int,
  target : String,
  value : JsonValue,
) -> Result[(JsonValue, Int), String] {
  if pos + target.length() > len {
    return Err("truncated JSON literal")
  }
  for i = 0; i < target.length(); i = i + 1 {
    if input[pos + i] != target[i] {
      return Err("invalid JSON literal")
    }
  }
  Ok((value, pos + target.length()))
}

///|
fn parse_string(
  input : String,
  pos : Int,
  len : Int,
) -> Result[(String, Int), String] {
  let mut p = pos + 1
  let mut out = ""
  while p < len {
    let c = input[p]
    if c == '\"' {
      return Ok((out, p + 1))
    } else if c == '\\' {
      p = p + 1
      if p >= len {
        return Err("truncated string escape")
      }
      let escaped = input[p]
      if escaped == '\"' {
        out = out + "\""
      } else if escaped == '\\' {
        out = out + "\\"
      } else if escaped == '/' {
        out = out + "/"
      } else if escaped == 'n' {
        out = out + "\n"
      } else if escaped == 'r' {
        out = out + "\r"
      } else if escaped == 't' {
        out = out + "\t"
      } else {
        return Err("unsupported string escape")
      }
      p = p + 1
    } else {
      out = out + input[p:p + 1].to_owned()
      p = p + 1
    }
  }
  Err("unterminated string")
}

///|
fn parse_number(
  input : String,
  pos : Int,
  len : Int,
) -> Result[(JsonValue, Int), String] {
  let mut p = pos
  if p < len && input[p] == '-' {
    p = p + 1
  }
  let mut has_digit = false
  while p < len && input[p] >= '0' && input[p] <= '9' {
    has_digit = true
    p = p + 1
  }
  if !has_digit {
    return Err("number has no digits")
  }
  if p < len && input[p] == '.' {
    p = p + 1
    let mut has_frac = false
    while p < len && input[p] >= '0' && input[p] <= '9' {
      has_frac = true
      p = p + 1
    }
    if !has_frac {
      return Err("fraction has no digits")
    }
  }
  if p < len && (input[p] == 'e' || input[p] == 'E') {
    p = p + 1
    if p < len && (input[p] == '+' || input[p] == '-') {
      p = p + 1
    }
    let mut has_exp = false
    while p < len && input[p] >= '0' && input[p] <= '9' {
      has_exp = true
      p = p + 1
    }
    if !has_exp {
      return Err("exponent has no digits")
    }
  }
  match parse_ascii_double(input[pos:p].to_owned()) {
    Ok(value) => Ok((JNumber(value), p))
    Err(e) => Err(e)
  }
}

///|
fn parse_object(
  input : String,
  pos : Int,
  len : Int,
) -> Result[(JsonValue, Int), String] {
  let fields : Array[JsonField] = []
  let mut p = skip_ws(input, pos + 1, len)
  if p < len && input[p] == '}' {
    return Ok((JObject(fields), p + 1))
  }
  while true {
    p = skip_ws(input, p, len)
    if p >= len || input[p] != '\"' {
      return Err("object key must be a string")
    }
    match parse_string(input, p, len) {
      Ok((key, next_key)) => {
        p = skip_ws(input, next_key, len)
        if p >= len || input[p] != ':' {
          return Err("object key must be followed by colon")
        }
        match parse_value(input, p + 1, len) {
          Ok((value, next_value)) => {
            fields.push({ key, value })
            p = skip_ws(input, next_value, len)
            if p >= len {
              return Err("unterminated object")
            }
            if input[p] == '}' {
              return Ok((JObject(fields), p + 1))
            } else if input[p] == ',' {
              p = p + 1
            } else {
              return Err("object expects comma or closing brace")
            }
          }
          Err(e) => return Err(e)
        }
      }
      Err(e) => return Err(e)
    }
  } nobreak {
    Err("unreachable object parser state")
  }
}

///|
fn parse_array(
  input : String,
  pos : Int,
  len : Int,
) -> Result[(JsonValue, Int), String] {
  let items : Array[JsonValue] = []
  let mut p = skip_ws(input, pos + 1, len)
  if p < len && input[p] == ']' {
    return Ok((JArray(items), p + 1))
  }
  while true {
    match parse_value(input, p, len) {
      Ok((value, next_value)) => {
        items.push(value)
        p = skip_ws(input, next_value, len)
        if p >= len {
          return Err("unterminated array")
        }
        if input[p] == ']' {
          return Ok((JArray(items), p + 1))
        } else if input[p] == ',' {
          p = p + 1
        } else {
          return Err("array expects comma or closing bracket")
        }
      }
      Err(e) => return Err(e)
    }
  } nobreak {
    Err("unreachable array parser state")
  }
}

///|
fn parse_ascii_double(input : String) -> Result[Double, String] {
  let s = input.trim().to_owned()
  if s.length() == 0 {
    return Err("empty number")
  }
  let mut i = 0
  let mut negative = false
  if s[0] == '+' {
    i = 1
  } else if s[0] == '-' {
    negative = true
    i = 1
  }
  if i >= s.length() {
    return Err("empty number")
  }
  let mut int_part = 0
  let mut has_digit = false
  while i < s.length() && s[i] >= '0' && s[i] <= '9' {
    int_part = int_part * 10 + (s[i].to_int() - '0'.to_int())
    has_digit = true
    i = i + 1
  }
  if !has_digit {
    return Err("number has no digits")
  }
  let mut result = int_part.to_double()
  if i < s.length() && s[i] == '.' {
    i = i + 1
    let mut frac = 0.0
    let mut div = 10.0
    let mut has_frac = false
    while i < s.length() && s[i] >= '0' && s[i] <= '9' {
      frac = frac + (s[i].to_int() - '0'.to_int()).to_double() / div
      div = div * 10.0
      has_frac = true
      i = i + 1
    }
    if !has_frac {
      return Err("fraction has no digits")
    }
    result = result + frac
  }
  if i < s.length() && (s[i] == 'e' || s[i] == 'E') {
    i = i + 1
    let mut exp_negative = false
    if i < s.length() && s[i] == '+' {
      i = i + 1
    } else if i < s.length() && s[i] == '-' {
      exp_negative = true
      i = i + 1
    }
    if i >= s.length() || s[i] < '0' || s[i] > '9' {
      return Err("exponent has no digits")
    }
    let mut exponent = 0
    while i < s.length() && s[i] >= '0' && s[i] <= '9' {
      exponent = exponent * 10 + (s[i].to_int() - '0'.to_int())
      i = i + 1
    }
    let mut scale = 1.0
    for step = 0; step < exponent; step = step + 1 {
      scale = scale * 10.0
    }
    if exp_negative {
      result = result / scale
    } else {
      result = result * scale
    }
  }
  if i != s.length() {
    return Err("trailing number suffix")
  }
  if negative {
    result = -result
  }
  Ok(result)
}
