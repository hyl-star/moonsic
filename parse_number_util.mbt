// Shared ASCII number parsing for text and JSON decoders.

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
    return Err("empty number: \{s}")
  }
  let mut int_part = 0
  let mut has_digit = false
  while i < s.length() && s[i] >= '0' && s[i] <= '9' {
    int_part = int_part * 10 + (s[i].to_int() - '0'.to_int())
    has_digit = true
    i = i + 1
  }
  if !has_digit {
    return Err("number has no digits: \{s}")
  }
  let mut result = int_part.to_double()
  if i < s.length() && s[i] == '.' {
    i = i + 1
    let mut frac : Double = 0.0
    let mut div : Double = 10.0
    while i < s.length() && s[i] >= '0' && s[i] <= '9' {
      frac = frac + (s[i].to_int() - '0'.to_int()).to_double() / div
      div = div * 10.0
      i = i + 1
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
      return Err("exponent has no digits: \{s}")
    }
    let mut exponent = 0
    while i < s.length() && s[i] >= '0' && s[i] <= '9' {
      exponent = exponent * 10 + (s[i].to_int() - '0'.to_int())
      i = i + 1
    }
    let mut scale : Double = 1.0
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
    return Err("trailing number suffix: \{s[i:s.length()].to_owned()}")
  }
  if negative {
    result = -result
  }
  Ok(result)
}
