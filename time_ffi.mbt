//
// FFI JSON — 面向 JS/WASM 的字符串包装（time 模块）
//

///|
/// Strict string-only FFI. Input JSON: {"duration":"q","ppq":480}
pub fn ffi_duration_ticks_json(input : String) -> String {
  let fields = match ffi_time_fields(input) {
    Ok(f) => f
    Err(e) => return ffi_time_error(e)
  }
  let dur_text = match ffi_time_string_field(fields, "duration") {
    Ok(s) => s
    Err(e) => return ffi_time_error(e)
  }
  let ppq = match ffi_time_int_field(fields, "ppq") {
    Ok(n) => n
    Err(e) => return ffi_time_error(e)
  }
  ffi_duration_ticks(dur_text, ppq)
}

///|
/// Strict string-only FFI. Input JSON: {"ticks":480,"bpm":120.0,"ppq":480}
pub fn ffi_ticks_to_seconds_json(input : String) -> String {
  let fields = match ffi_time_fields(input) {
    Ok(f) => f
    Err(e) => return ffi_time_error(e)
  }
  let ticks = match ffi_time_int_field(fields, "ticks") {
    Ok(n) => n
    Err(e) => return ffi_time_error(e)
  }
  let bpm = match ffi_time_double_field(fields, "bpm") {
    Ok(n) => n
    Err(e) => return ffi_time_error(e)
  }
  let ppq = match ffi_time_int_field(fields, "ppq") {
    Ok(n) => n
    Err(e) => return ffi_time_error(e)
  }
  ffi_ticks_to_seconds(ticks, bpm, ppq)
}

///|
/// Strict string-only FFI. Input JSON: {"sig":"4/4","ppq":480}
pub fn ffi_bar_length_json(input : String) -> String {
  let fields = match ffi_time_fields(input) {
    Ok(f) => f
    Err(e) => return ffi_time_error(e)
  }
  let sig = match ffi_time_string_field(fields, "sig") {
    Ok(s) => s
    Err(e) => return ffi_time_error(e)
  }
  let ppq = match ffi_time_int_field(fields, "ppq") {
    Ok(n) => n
    Err(e) => return ffi_time_error(e)
  }
  ffi_bar_length(sig, ppq)
}

///|
/// FFI 解析拍号：入 "4/4" → {"ok":true,"num":4,"den":4}
fn ffi_time_error(message : String) -> String {
  ffi_error("TimeError", message)
}

///|
fn ffi_time_fields(input : String) -> Result[Array[JsonField], String] {
  match json_parse(input) {
    Ok(v) => jv_get_fields(v)
    Err(e) => Err(e)
  }
}

///|
fn ffi_time_string_field(
  fields : Array[JsonField],
  key : String,
) -> Result[String, String] {
  match jv_lookup(fields, key) {
    Ok(v) => jv_as_string(v)
    Err(e) => Err(e)
  }
}

///|
fn ffi_time_int_field(
  fields : Array[JsonField],
  key : String,
) -> Result[Int, String] {
  match jv_lookup(fields, key) {
    Ok(v) => jv_as_int(v)
    Err(e) => Err(e)
  }
}

///|
fn ffi_time_double_field(
  fields : Array[JsonField],
  key : String,
) -> Result[Double, String] {
  match jv_lookup(fields, key) {
    Ok(v) => jv_as_double(v)
    Err(e) => Err(e)
  }
}

///|
pub fn ffi_parse_time_sig(input : String) -> String {
  match parse_time_sig(input) {
    Ok(sig) =>
      "{\"ok\":true,\"num\":\{sig.numerator},\"den\":\{sig.denominator}}"
    Err(e) => ffi_error("TimeError", e.to_string())
  }
}

///|
/// @deprecated Use ffi_duration_ticks_json instead.
/// FFI 时值转 tick：入 "q",480 → {"ok":true,"ticks":480}
pub fn ffi_duration_ticks(input : String, ppq : Int) -> String {
  match parse_dur_unit(input) {
    Ok(dur) =>
      match rhythm_duration_to_ticks(dur, ppq) {
        Ok(ticks) => ffi_ok_field("ticks", ticks.to_string())
        Err(e) => ffi_error("TimeError", e.to_string())
      }
    Err(e) => ffi_error("TimeError", e.to_string())
  }
}

///|
/// FFI 解析 BPM：入 "120bpm" → {"ok":true,"bpm":120.0}
pub fn ffi_parse_tempo(input : String) -> String {
  match parse_tempo(input) {
    Ok(bpm) => ffi_ok_field("bpm", bpm.to_string())
    Err(e) => ffi_error("TimeError", e.to_string())
  }
}

///|
/// @deprecated Use ffi_ticks_to_seconds_json instead.
/// FFI tick→秒：入 480,120.0,480 → {"ok":true,"seconds":0.5}
pub fn ffi_ticks_to_seconds(ticks : Int, bpm : Double, ppq : Int) -> String {
  match ticks_to_seconds(ticks, bpm, ppq) {
    Ok(sec) => ffi_ok_field("seconds", sec.to_string())
    Err(e) => ffi_error("TimeError", e.to_string())
  }
}

///|
/// @deprecated Use ffi_bar_length_json instead.
/// FFI 小节长度：入 "4/4",480 → {"ok":true,"ticks":1920}
pub fn ffi_bar_length(sig : String, ppq : Int) -> String {
  match parse_time_sig(sig) {
    Ok(parsed) =>
      match bar_length_ticks(parsed, ppq) {
        Ok(ticks) => ffi_ok_field("ticks", ticks.to_string())
        Err(e) => ffi_error("TimeError", e.to_string())
      }
    Err(e) => ffi_error("TimeError", e.to_string())
  }
}
