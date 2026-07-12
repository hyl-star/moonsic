//
// FFI — 面向 JS/WASM 的字符串包装（time 模块）

///|

///|
fn _ffi_ok_field(name : String, value_json : String) -> String {
  "{\"ok\":true,\"" + name + "\":" + value_json + "}"
}

///|
fn _ffi_error(error : String, message : String) -> String {
  "{\"ok\":false,\"error\":" +
  @json.json_escape(error) +
  ",\"message\":" +
  @json.json_escape(message) +
  "}"
}

///|
fn _extract_json_string(json : String, key : String) -> Result[String, String] {
  let pattern = "\"" + key + "\":\""
  let pos = _str_find(json, pattern)
  if pos < 0 {
    return Err("missing key: \{key}")
  }
  let start = pos + pattern.length()
  let mut end = start
  while end < json.length() {
    if json[end] == '\"' && (end == 0 || json[end - 1] != '\\') {
      break
    }
    end = end + 1
  }
  Ok(json[start:end].to_owned())
}

///|
fn _extract_json_int(json : String, key : String) -> Result[Int, String] {
  let pattern = "\"" + key + "\":"
  let pos = _str_find(json, pattern)
  if pos < 0 {
    return Err("missing key: \{key}")
  }
  let start = pos + pattern.length()
  let mut end = start
  while end < json.length() {
    let c = json[end]
    if c == ',' || c == '}' || c == ' ' || c == '\n' {
      break
    }
    end = end + 1
  }
  let num_str = json[start:end].to_owned().trim().to_owned()
  let mut val = 0
  for i = 0; i < num_str.length(); i = i + 1 {
    let ch = num_str[i]
    if ch >= '0' && ch <= '9' {
      val = val * 10 + (ch.to_int() - '0'.to_int())
    } else if ch == '-' && i == 0 {
      continue
    } else if ch == '.' {
      break
    } else {
      return Err("invalid int: \{num_str}")
    }
  }
  if num_str[0] == '-' {
    val = -val
  }
  Ok(val)
}

///|
fn _extract_json_double(json : String, key : String) -> Result[Double, String] {
  let pattern = "\"" + key + "\":"
  let pos = _str_find(json, pattern)
  if pos < 0 {
    return Err("missing key: \{key}")
  }
  let start = pos + pattern.length()
  let mut end = start
  while end < json.length() {
    let c = json[end]
    if c == ',' || c == '}' {
      break
    }
    end = end + 1
  }
  let num_str = json[start:end].to_owned().trim().to_owned()
  match _parse_double_literal(num_str) {
    Ok(d) => Ok(d)
    Err(e) => Err(e)
  }
}

///|
fn _str_find(s : String, pattern : String) -> Int {
  let plen = pattern.length()
  let slen = s.length()
  if plen > slen {
    return -1
  }
  let mut i = 0
  while i + plen <= slen {
    let mut matched = true
    let mut j = 0
    while j < plen {
      if s[i + j] != pattern[j] {
        matched = false
        break
      }
      j = j + 1
    }
    if matched {
      return i
    }
    i = i + 1
  }
  -1
}

///|
fn _parse_double_literal(s : String) -> Result[Double, String] {
  let trimmed = s.trim().to_owned()
  if trimmed.length() == 0 {
    return Err("empty")
  }
  let mut i = 0
  let mut neg = false
  if trimmed[0] == '-' {
    neg = true
    i = 1
  } else if trimmed[0] == '+' {
    i = 1
  }
  let mut int_part : Int = 0
  let mut has_digit = false
  while i < trimmed.length() &&
        trimmed[i] != '.' &&
        trimmed[i] != 'e' &&
        trimmed[i] != 'E' {
    let c = trimmed[i]
    if c >= '0' && c <= '9' {
      int_part = int_part * 10 + (c.to_int() - '0'.to_int())
      has_digit = true
      i = i + 1
    } else {
      return Err("invalid char: \{c}")
    }
  }
  if !has_digit {
    return Err("no digits")
  }
  let mut result = int_part.to_double()
  if i < trimmed.length() && trimmed[i] == '.' {
    i = i + 1
    let mut frac : Double = 0.0
    let mut div : Double = 10.0
    while i < trimmed.length() && trimmed[i] != 'e' && trimmed[i] != 'E' {
      let c = trimmed[i]
      if c >= '0' && c <= '9' {
        frac = frac + (c.to_int() - '0'.to_int()).to_double() / div
        div = div * 10.0
        i = i + 1
      } else {
        return Err("invalid char: \{c}")
      }
    }
    result = result + frac
  }
  if neg {
    result = -result
  }
  Ok(result)
}

// FFI 入口

///|
/// FFI 时值转 tick：入 {"duration":"q","ppq":480} → {"ok":true,"ticks":480}
pub fn ffi_duration_ticks_json(input : String) -> String {
  let dur_text = match _extract_json_string(input, "duration") {
    Ok(s) => s
    Err(e) => return _ffi_error("TimeError", e)
  }
  let ppq = match _extract_json_int(input, "ppq") {
    Ok(n) => n
    Err(e) => return _ffi_error("TimeError", e)
  }
  match parse_dur_unit(dur_text) {
    Ok(dur) =>
      match rhythm_duration_to_ticks(dur, ppq) {
        Ok(ticks) => _ffi_ok_field("ticks", ticks.to_string())
        Err(e) => _ffi_error("TimeError", e.to_string())
      }
    Err(e) => _ffi_error("TimeError", e.to_string())
  }
}

///|
/// FFI tick→秒：入 {"ticks":480,"bpm":120.0,"ppq":480} → {"ok":true,"seconds":0.5}
pub fn ffi_ticks_to_seconds_json(input : String) -> String {
  let ticks = match _extract_json_int(input, "ticks") {
    Ok(n) => n
    Err(e) => return _ffi_error("TimeError", e)
  }
  let bpm = match _extract_json_double(input, "bpm") {
    Ok(n) => n
    Err(e) => return _ffi_error("TimeError", e)
  }
  let ppq = match _extract_json_int(input, "ppq") {
    Ok(n) => n
    Err(e) => return _ffi_error("TimeError", e)
  }
  match ticks_to_seconds(ticks, bpm, ppq) {
    Ok(sec) => _ffi_ok_field("seconds", sec.to_string())
    Err(e) => _ffi_error("TimeError", e.to_string())
  }
}

///|
/// FFI 小节长度：入 {"sig":"4/4","ppq":480} → {"ok":true,"ticks":1920}
pub fn ffi_bar_length_json(input : String) -> String {
  let sig = match _extract_json_string(input, "sig") {
    Ok(s) => s
    Err(e) => return _ffi_error("TimeError", e)
  }
  let ppq = match _extract_json_int(input, "ppq") {
    Ok(n) => n
    Err(e) => return _ffi_error("TimeError", e)
  }
  match parse_time_sig(sig) {
    Ok(parsed) =>
      match bar_length_ticks(parsed, ppq) {
        Ok(ticks) => _ffi_ok_field("ticks", ticks.to_string())
        Err(e) => _ffi_error("TimeError", e.to_string())
      }
    Err(e) => _ffi_error("TimeError", e.to_string())
  }
}

///|
/// FFI 解析拍号：入 "4/4" → {"ok":true,"num":4,"den":4}
pub fn ffi_parse_time_sig(input : String) -> String {
  match parse_time_sig(input) {
    Ok(sig) =>
      "{\"ok\":true,\"num\":\{sig.numerator},\"den\":\{sig.denominator}}"
    Err(e) => _ffi_error("TimeError", e.to_string())
  }
}

///|
/// FFI 解析速度：入 "120bpm" → {"ok":true,"bpm":120.0}
pub fn ffi_parse_tempo(input : String) -> String {
  match parse_tempo(input) {
    Ok(bpm) => _ffi_ok_field("bpm", bpm.to_string())
    Err(e) => _ffi_error("TimeError", e.to_string())
  }
}
