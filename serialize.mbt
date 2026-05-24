//
// JSON 序列化模块 — Score / Track / NoteEvent 转 JSON
// 手写 JSON 编码/解码，不依赖外部 JSON 库
//

// ============================================================
// JSON AST 类型
// ============================================================

///|
/// JSON 值：Null、Bool、Number、String、Array、Object
pub(all) enum JsonValue {
  JNull
  JBool(Bool)
  JNumber(Double)
  JString(String)
  JArray(Array[JsonValue])
  JObject(Array[JsonField])
}

///|
/// JSON 对象字段：键值对
pub(all) struct JsonField {
  key : String
  value : JsonValue
}

// ============================================================
// JSON 构造快捷函数
// ============================================================

///|
fn jv_bool(b : Bool) -> JsonValue {
  JBool(b)
}

///|
fn jv_num(n : Double) -> JsonValue {
  JNumber(n)
}

///|
fn jv_int(n : Int) -> JsonValue {
  JNumber(n.to_double())
}

///|
fn jv_str(s : String) -> JsonValue {
  JString(s)
}

///|
fn jv_arr(items : Array[JsonValue]) -> JsonValue {
  JArray(items)
}

///|
fn jv_obj(fields : Array[JsonField]) -> JsonValue {
  JObject(fields)
}

///|
fn jv_field(key : String, value : JsonValue) -> JsonField {
  { key, value }
}

// ============================================================
// JSON 序列化
// ============================================================

///|
/// JsonValue 转紧凑 JSON 字符串
pub fn json_stringify(value : JsonValue) -> String {
  match value {
    JNull => "null"
    JBool(b) => if b { "true" } else { "false" }
    JNumber(n) => format_json_num(n)
    JString(s) => json_escape(s)
    JArray(items) => json_arr_str(items)
    JObject(fields) => json_obj_str(fields)
  }
}

///|
/// 格式化浮点数：整数不带小数点，其他保留原样
fn format_json_num(n : Double) -> String {
  let i = n.to_int()
  let d = i.to_double()
  if n == d {
    i.to_string()
  } else {
    n.to_string()
  }
}

///|
/// JSON 字符串转义（双引号、反斜杠、控制字符）
fn json_escape(s : String) -> String {
  let mut result = "\""
  let len = s.length()
  for i = 0; i < len; i = i + 1 {
    let c = s[i]
    if c == '\"' {
      result = result + "\\\""
    } else if c == '\\' {
      result = result + "\\\\"
    } else if c == '\n' {
      result = result + "\\n"
    } else if c == '\r' {
      result = result + "\\r"
    } else if c == '\t' {
      result = result + "\\t"
    } else {
      result = result + "\{c}"
    }
  }
  result + "\""
}

///|
/// JSON 数组字符串化
fn json_arr_str(items : Array[JsonValue]) -> String {
  let mut s = "["
  let n = items.length()
  for i = 0; i < n; i = i + 1 {
    s = s + json_stringify(items[i])
    if i < n - 1 {
      s = s + ","
    }
  }
  s + "]"
}

///|
/// JSON 对象字符串化
fn json_obj_str(fields : Array[JsonField]) -> String {
  let mut s = "{"
  let n = fields.length()
  for i = 0; i < n; i = i + 1 {
    let f = fields[i]
    s = s + json_escape(f.key) + ":" + json_stringify(f.value)
    if i < n - 1 {
      s = s + ","
    }
  }
  s + "}"
}

// ============================================================
// 领域对象 → JsonValue（内部）
// ============================================================

///|
/// Pitch → JsonValue
fn pitch_to_jv(p : Pitch) -> JsonValue {
  jv_obj([
    jv_field("note", jv_str(p.class.to_string())),
    jv_field("accidental", jv_str(p.accidental.to_string())),
    jv_field("octave", jv_int(p.octave)),
  ])
}

///|
/// 计 Duration 的附点数（Dotted 嵌套深度）
fn duration_dots(d : Duration) -> Int {
  match d {
    Dotted(base) => 1 + duration_dots(base)
    _ => 0
  }
}

///|
/// 剥离所有 Dotted 包装，返回基础时值
fn duration_base(d : Duration) -> Duration {
  match d {
    Dotted(base) => duration_base(base)
    _ => d
  }
}

///|
/// 基础时值的字符串名
fn duration_kind_name(d : Duration) -> String {
  match d {
    Whole => "whole"
    Half => "half"
    Quarter => "quarter"
    Eighth => "eighth"
    Sixteenth => "sixteenth"
    _ => "quarter"
  }
}

///|
/// Duration → JsonValue
fn duration_to_jv(d : Duration) -> JsonValue {
  let dots = duration_dots(d)
  let base = duration_base(d)
  jv_obj([
    jv_field("kind", jv_str(duration_kind_name(base))),
    jv_field("dots", jv_int(dots)),
  ])
}

///|
/// Tempo → JsonValue
fn tempo_to_jv(t : Tempo) -> JsonValue {
  jv_obj([jv_field("bpm", jv_int(t.bpm))])
}

///|
/// TimeSignature → JsonValue
fn time_sig_to_jv(ts : TimeSignature) -> JsonValue {
  jv_obj([
    jv_field("numerator", jv_int(ts.numerator)),
    jv_field("denominator", jv_int(ts.denominator)),
  ])
}

///|
/// MusicEvent → JsonValue
fn music_event_to_jv(e : MusicEvent) -> JsonValue {
  match e {
    Note(n) =>
      jv_obj([
        jv_field("type", jv_str("note")),
        jv_field("pitch", pitch_to_jv(n.pitch)),
        jv_field("duration", duration_to_jv(n.duration)),
        jv_field("velocity", jv_int(n.velocity)),
      ])
    Rest(r) =>
      jv_obj([
        jv_field("type", jv_str("rest")),
        jv_field("duration", duration_to_jv(r.duration)),
      ])
    Chord(c) => {
      let pitch_arr = []
      for p in c.pitches {
        pitch_arr.push(pitch_to_jv(p))
      }
      jv_obj([
        jv_field("type", jv_str("chord")),
        jv_field("pitches", jv_arr(pitch_arr)),
        jv_field("duration", duration_to_jv(c.duration)),
        jv_field("velocity", jv_int(c.velocity)),
      ])
    }
  }
}

///|
/// Track → JsonValue
fn track_to_jv(t : Track) -> JsonValue {
  let event_arr = []
  for e in t.events {
    event_arr.push(music_event_to_jv(e))
  }
  jv_obj([
    jv_field("channel", jv_int(t.channel)),
    jv_field("program", jv_int(t.program)),
    jv_field("volume", jv_num(t.volume)),
    jv_field("pan", jv_num(t.pan)),
    jv_field("mute", jv_bool(t.mute)),
    jv_field("events", jv_arr(event_arr)),
  ])
}

///|
/// Score → JsonValue（带 schema/version 包装）
fn score_to_jv(score : Score) -> JsonValue {
  let track_arr = []
  for t in score.tracks {
    track_arr.push(track_to_jv(t))
  }
  let data = jv_obj([
    jv_field("tempo", tempo_to_jv(score.tempo)),
    jv_field("time_signature", time_sig_to_jv(score.time_signature)),
    jv_field("master_gain", jv_num(score.master_gain)),
    jv_field("tracks", jv_arr(track_arr)),
  ])
  jv_obj([
    jv_field("schema", jv_str("moonsic.score")),
    jv_field("version", jv_int(1)),
    jv_field("data", data),
  ])
}

///|
/// NoteEvent → JsonValue
fn note_event_to_jv(e : NoteEvent) -> JsonValue {
  jv_obj([
    jv_field("start", jv_num(e.start)),
    jv_field("duration", jv_num(e.duration)),
    jv_field("midi_note", jv_int(e.midi_note)),
    jv_field("velocity", jv_int(e.velocity)),
    jv_field("channel", jv_int(e.channel)),
  ])
}

// ============================================================
// 公开序列化 API
// ============================================================

///|
/// 乐谱转 JSON 字符串（带 schema: "moonsic.score", version: 1）
pub fn score_to_json(score : Score) -> String {
  json_stringify(score_to_jv(score))
}

///|
/// 轨道转 JSON 字符串
pub fn track_to_json(track : Track) -> String {
  json_stringify(track_to_jv(track))
}

///|
/// NoteEvent 转 JSON 字符串
pub fn note_event_to_json(e : NoteEvent) -> String {
  json_stringify(note_event_to_jv(e))
}

///|
/// Pitch 转 JSON 字符串
pub fn pitch_to_json_string(p : Pitch) -> String {
  json_stringify(pitch_to_jv(p))
}

///|
/// Duration 转 JSON 字符串
pub fn duration_to_json_string(d : Duration) -> String {
  json_stringify(duration_to_jv(d))
}

///|
/// Chord 转 JSON 字符串
pub fn chord_to_json_string(c : Chord) -> String {
  let pitch_arr = []
  for p in c.pitches {
    pitch_arr.push(pitch_to_jv(p))
  }
  let jv = jv_obj([
    jv_field("pitches", jv_arr(pitch_arr)),
    jv_field("duration", duration_to_jv(c.duration)),
    jv_field("velocity", jv_int(c.velocity)),
  ])
  json_stringify(jv)
}

// ============================================================
// JSON 解析器（基础递归下降）
// ============================================================

///|
/// 跳过空白字符，返回新位置
fn skip_json_ws(input : String, pos : Int, len : Int) -> Int {
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
/// 解析 JSON 字符串为 JsonValue
pub fn json_parse(input : String) -> Result[JsonValue, String] {
  let len = input.length()
  let pos = skip_json_ws(input, 0, len)
  if pos >= len {
    return Err("空 JSON 输入")
  }
  match parse_json_value(input, pos, len) {
    Ok((val, next)) => {
      let after = skip_json_ws(input, next, len)
      if after < len {
        return Err("JSON 解析后还有多余字符")
      }
      Ok(val)
    }
    Err(e) => Err(e)
  }
}

///|
/// 解析单个 JSON 值，返回 (值, 新位置)
fn parse_json_value(
  input : String,
  pos : Int,
  len : Int,
) -> Result[(JsonValue, Int), String] {
  let p = skip_json_ws(input, pos, len)
  if p >= len {
    return Err("nexpected JSON 值结尾")
  }
  let c = input[p]
  if c == '{' {
    parse_json_obj_inner(input, p, len)
  } else if c == '[' {
    parse_json_arr_inner(input, p, len)
  } else if c == '\"' {
    match parse_json_str_inner(input, p, len) {
      Ok((s, np)) => Ok((JString(s), np))
      Err(e) => Err(e)
    }
  } else if c == 't' {
    parse_json_literal(input, p, len, "true", JBool(true))
  } else if c == 'f' {
    parse_json_literal(input, p, len, "false", JBool(false))
  } else if c == 'n' {
    parse_json_literal(input, p, len, "null", JNull)
  } else if c == '-' || (c >= '0' && c <= '9') {
    parse_json_num_inner(input, p, len)
  } else {
    Err("JSON 非法字符：\{c}")
  }
}

///|
/// 解析 JSON 字面量（true / false / null）
fn parse_json_literal(
  input : String,
  pos : Int,
  len : Int,
  target : String,
  value : JsonValue,
) -> Result[(JsonValue, Int), String] {
  let tl = target.length()
  if pos + tl > len {
    return Err("JSON 字面量截断")
  }
  let mut i = 0
  while i < tl {
    if input[pos + i] != target[i] {
      return Err("JSON 非法字面量：期望 \{target}")
    }
    i = i + 1
  }
  Ok((value, pos + tl))
}

///|
/// 解析 JSON 字符串，返回 (字符串值, 新位置)
fn parse_json_str_inner(
  input : String,
  pos : Int,
  len : Int,
) -> Result[(String, Int), String] {
  // 跳过开头的双引号
  let mut p = pos + 1
  let mut s = ""
  while p < len {
    let c = input[p]
    if c == '\"' {
      return Ok((s, p + 1))
    } else if c == '\\' {
      p = p + 1
      if p >= len {
        return Err("JSON 字符串转义截断")
      }
      let ec = input[p]
      if ec == '\"' {
        s = s + "\""
      } else if ec == '\\' {
        s = s + "\\"
      } else if ec == '/' {
        s = s + "/"
      } else if ec == 'n' {
        s = s + "\n"
      } else if ec == 'r' {
        s = s + "\r"
      } else if ec == 't' {
        s = s + "\t"
      } else {
        return Err("JSON 非法转义：\\\{ec}")
      }
      p = p + 1
    } else {
      s = s + "\{c}"
      p = p + 1
    }
  }
  Err("JSON 字符串未闭合")
}

///|
/// 解析 JSON 数字
fn parse_json_num_inner(
  input : String,
  pos : Int,
  len : Int,
) -> Result[(JsonValue, Int), String] {
  let mut p = pos
  // 可选负号
  if p < len && input[p] == '-' {
    p = p + 1
  }
  let mut has_digit = false
  while p < len && input[p] >= '0' && input[p] <= '9' {
    has_digit = true
    p = p + 1
  }
  if !has_digit {
    return Err("JSON 数字无有效数字")
  }
  // 可选小数部分
  if p < len && input[p] == '.' {
    p = p + 1
    let mut frac = false
    while p < len && input[p] >= '0' && input[p] <= '9' {
      frac = true
      p = p + 1
    }
    if !frac {
      return Err("JSON 数字小数点后无数字")
    }
  }
  // 可选指数部分
  if p < len && (input[p] == 'e' || input[p] == 'E') {
    p = p + 1
    if p < len && (input[p] == '+' || input[p] == '-') {
      p = p + 1
    }
    let mut exp = false
    while p < len && input[p] >= '0' && input[p] <= '9' {
      exp = true
      p = p + 1
    }
    if !exp {
      return Err("JSON 数字指数部分无数字")
    }
  }
  let num_str = input[pos:p].to_owned()
  match parse_double_str(num_str) {
    Ok(d) => Ok((JNumber(d), p))
    Err(e) => Err(e)
  }
}

///|
/// 解析字符串为 Double
fn parse_double_str(s : String) -> Result[Double, String] {
  let len = s.length()
  if len == 0 {
    return Err("空数字字符串")
  }
  let mut i = 0
  let mut neg = false
  if s[0] == '-' {
    neg = true
    i = 1
  }
  if i >= len {
    return Err("空数字：\{s}")
  }
  let mut int_part : Int = 0
  let mut has_digit = false
  while i < len && s[i] >= '0' && s[i] <= '9' {
    int_part = int_part * 10 + (s[i].to_int() - '0'.to_int())
    has_digit = true
    i = i + 1
  }
  if !has_digit {
    return Err("无数字：\{s}")
  }
  let mut result = int_part.to_double()
  if i < len && s[i] == '.' {
    i = i + 1
    let mut frac : Double = 0.0
    let mut div : Double = 10.0
    while i < len && s[i] >= '0' && s[i] <= '9' {
      frac = frac + (s[i].to_int() - '0'.to_int()).to_double() / div
      div = div * 10.0
      i = i + 1
    }
    result = result + frac
  }
  if neg {
    result = -result
  }
  Ok(result)
}

///|
/// 解析 JSON 对象
fn parse_json_obj_inner(
  input : String,
  pos : Int,
  len : Int,
) -> Result[(JsonValue, Int), String] {
  let mut p = pos + 1 // 跳过 {
  let fields : Array[JsonField] = []
  p = skip_json_ws(input, p, len)
  if p < len && input[p] == '}' {
    return Ok((JObject(fields), p + 1))
  }
  while true {
    p = skip_json_ws(input, p, len)
    if p >= len || input[p] != '\"' {
      return Err("JSON 对象期望字符串键")
    }
    match parse_json_str_inner(input, p, len) {
      Ok((key, p2)) => {
        p = skip_json_ws(input, p2, len)
        if p >= len || input[p] != ':' {
          return Err("JSON 对象期望冒号")
        }
        p = p + 1
        match parse_json_value(input, p, len) {
          Ok((val, p3)) => {
            fields.push({ key, value: val })
            p = skip_json_ws(input, p3, len)
            if p >= len {
              return Err("JSON 对象未闭合")
            }
            if input[p] == '}' {
              return Ok((JObject(fields), p + 1))
            } else if input[p] == ',' {
              p = p + 1
            } else {
              return Err("JSON 对象期望逗号或右括号")
            }
          }
          Err(e) => return Err(e)
        }
      }
      Err(e) => return Err(e)
    }
  } nobreak {
    Err("JSON 对象解析内部错误：无法到达")
  }
}

///|
/// 解析 JSON 数组
fn parse_json_arr_inner(
  input : String,
  pos : Int,
  len : Int,
) -> Result[(JsonValue, Int), String] {
  let mut p = pos + 1 // 跳过 [
  let items : Array[JsonValue] = []
  p = skip_json_ws(input, p, len)
  if p < len && input[p] == ']' {
    return Ok((JArray(items), p + 1))
  }
  while true {
    match parse_json_value(input, p, len) {
      Ok((val, p2)) => {
        items.push(val)
        p = skip_json_ws(input, p2, len)
        if p >= len {
          return Err("JSON 数组未闭合")
        }
        if input[p] == ']' {
          return Ok((JArray(items), p + 1))
        } else if input[p] == ',' {
          p = p + 1
        } else {
          return Err("JSON 数组期望逗号或右括号")
        }
      }
      Err(e) => return Err(e)
    }
  } nobreak {
    Err("JSON 数组解析内部错误：无法到达")
  }
}

// ============================================================
// JSON → 领域对象反序列化
// ============================================================

///|
/// 从 JsonValue 安全读取对象字段
fn jv_get_fields(v : JsonValue) -> Result[Array[JsonField], String] {
  match v {
    JObject(fields) => Ok(fields)
    _ => Err("期望 JSON 对象")
  }
}

///|
/// 从字段列表中按 key 查找字段值
fn jv_lookup(
  fields : Array[JsonField],
  key : String,
) -> Result[JsonValue, String] {
  for f in fields {
    if f.key == key {
      return Ok(f.value)
    }
  }
  Err("缺少字段：\{key}")
}

///|
/// 从 JsonValue 提取字符串
fn jv_as_string(v : JsonValue) -> Result[String, String] {
  match v {
    JString(s) => Ok(s)
    _ => Err("期望 JSON 字符串")
  }
}

///|
/// 从 JsonValue 提取整数
fn jv_as_int(v : JsonValue) -> Result[Int, String] {
  match v {
    JNumber(n) => Ok(n.to_int())
    _ => Err("期望 JSON 数字")
  }
}

///|
/// 从 JsonValue 提取浮点数
fn jv_as_double(v : JsonValue) -> Result[Double, String] {
  match v {
    JNumber(n) => Ok(n)
    _ => Err("期望 JSON 数字")
  }
}

///|
/// 从 JsonValue 提取布尔值
fn jv_as_bool(v : JsonValue) -> Result[Bool, String] {
  match v {
    JBool(b) => Ok(b)
    _ => Err("期望 JSON 布尔")
  }
}

///|
/// 从 JsonValue 提取数组
fn jv_as_array(v : JsonValue) -> Result[Array[JsonValue], String] {
  match v {
    JArray(arr) => Ok(arr)
    _ => Err("期望 JSON 数组")
  }
}

///|
/// 从 JsonValue 还原 Pitch
fn pitch_from_jv(v : JsonValue) -> Result[Pitch, String] {
  let fields = match jv_get_fields(v) {
    Ok(f) => f
    Err(e) => return Err(e)
  }
  let note_str = match jv_lookup(fields, "note") {
    Ok(jv) =>
      match jv_as_string(jv) {
        Ok(s) => s
        Err(e) => return Err(e)
      }
    Err(e) => return Err(e)
  }
  let acc_str = match jv_lookup(fields, "accidental") {
    Ok(jv) =>
      match jv_as_string(jv) {
        Ok(s) => s
        Err(e) => return Err(e)
      }
    Err(e) => return Err(e)
  }
  let octave = match jv_lookup(fields, "octave") {
    Ok(jv) =>
      match jv_as_int(jv) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
    Err(e) => return Err(e)
  }
  let class = match note_str {
    "C" => C
    "D" => D
    "E" => E
    "F" => F
    "G" => G
    "A" => A
    "B" => B
    _ => return Err("无效音名：\{note_str}")
  }
  let accidental = match acc_str {
    "" => Natural
    "#" => Sharp
    "b" => Flat
    "x" => DoubleSharp
    "bb" => DoubleFlat
    _ => return Err("无效变音记号：\{acc_str}")
  }
  Ok(pitch(class, accidental, octave))
}

///|
/// 从 JsonValue 还原 Duration
fn duration_from_jv(v : JsonValue) -> Result[Duration, String] {
  let fields = match jv_get_fields(v) {
    Ok(f) => f
    Err(e) => return Err(e)
  }
  let kind_str = match jv_lookup(fields, "kind") {
    Ok(jv) =>
      match jv_as_string(jv) {
        Ok(s) => s
        Err(e) => return Err(e)
      }
    Err(e) => return Err(e)
  }
  let dots = match jv_lookup(fields, "dots") {
    Ok(jv) =>
      match jv_as_int(jv) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
    Err(_e) => 0
  }
  let mut base = match kind_str {
    "whole" => Whole
    "half" => Half
    "quarter" => Quarter
    "eighth" => Eighth
    "sixteenth" => Sixteenth
    _ => return Err("无效时值类型：\{kind_str}")
  }
  for _d = 0; _d < dots; _d = _d + 1 {
    base = Dotted(base)
  }
  Ok(base)
}

///|
/// 从 JsonValue 还原 TimeSignature
fn time_sig_from_jv(v : JsonValue) -> Result[TimeSignature, String] {
  let fields = match jv_get_fields(v) {
    Ok(f) => f
    Err(e) => return Err(e)
  }
  let num = match jv_lookup(fields, "numerator") {
    Ok(jv) =>
      match jv_as_int(jv) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
    Err(e) => return Err(e)
  }
  let den = match jv_lookup(fields, "denominator") {
    Ok(jv) =>
      match jv_as_int(jv) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
    Err(e) => return Err(e)
  }
  Ok(time_signature(num, den))
}

///|
/// 从 JsonValue 还原 Tempo
fn tempo_from_jv(v : JsonValue) -> Result[Tempo, String] {
  let fields = match jv_get_fields(v) {
    Ok(f) => f
    Err(e) => return Err(e)
  }
  let bpm = match jv_lookup(fields, "bpm") {
    Ok(jv) =>
      match jv_as_int(jv) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
    Err(e) => return Err(e)
  }
  if bpm <= 0 {
    return Err("BPM 必须 > 0")
  }
  Ok(tempo(bpm))
}

///|
/// 从 JsonValue 还原 MusicEvent
fn music_event_from_jv(v : JsonValue) -> Result[MusicEvent, String] {
  let fields = match jv_get_fields(v) {
    Ok(f) => f
    Err(e) => return Err(e)
  }
  let typ = match jv_lookup(fields, "type") {
    Ok(jv) =>
      match jv_as_string(jv) {
        Ok(s) => s
        Err(e) => return Err(e)
      }
    Err(e) => return Err(e)
  }
  match typ {
    "note" => {
      let pjv = match jv_lookup(fields, "pitch") {
        Ok(jv) => jv
        Err(e) => return Err(e)
      }
      let p = match pitch_from_jv(pjv) {
        Ok(p) => p
        Err(e) => return Err(e)
      }
      let djv = match jv_lookup(fields, "duration") {
        Ok(jv) => jv
        Err(e) => return Err(e)
      }
      let d = match duration_from_jv(djv) {
        Ok(d) => d
        Err(e) => return Err(e)
      }
      let vel = match jv_lookup(fields, "velocity") {
        Ok(jv) =>
          match jv_as_int(jv) {
            Ok(n) => n
            Err(e) => return Err(e)
          }
        Err(_e) => DEFAULT_VELOCITY
      }
      Ok(Note(note_with_velocity(p, d, vel)))
    }
    "rest" => {
      let djv = match jv_lookup(fields, "duration") {
        Ok(jv) => jv
        Err(e) => return Err(e)
      }
      let d = match duration_from_jv(djv) {
        Ok(d) => d
        Err(e) => return Err(e)
      }
      Ok(Rest(rest(d)))
    }
    "chord" => {
      let pitches_jv = match jv_lookup(fields, "pitches") {
        Ok(jv) => jv
        Err(e) => return Err(e)
      }
      let pitch_arr = match jv_as_array(pitches_jv) {
        Ok(arr) => arr
        Err(e) => return Err(e)
      }
      let pitches = []
      for pjv in pitch_arr {
        match pitch_from_jv(pjv) {
          Ok(p) => pitches.push(p)
          Err(e) => return Err(e)
        }
      }
      let djv = match jv_lookup(fields, "duration") {
        Ok(jv) => jv
        Err(e) => return Err(e)
      }
      let d = match duration_from_jv(djv) {
        Ok(d) => d
        Err(e) => return Err(e)
      }
      let vel = match jv_lookup(fields, "velocity") {
        Ok(jv) =>
          match jv_as_int(jv) {
            Ok(n) => n
            Err(e) => return Err(e)
          }
        Err(_e) => DEFAULT_VELOCITY
      }
      Ok(Chord(chord_with_velocity(pitches, d, vel)))
    }
    _ => Err("无效音乐事件类型：\{typ}")
  }
}

///|
/// 从 JsonValue 还原 Track
fn track_from_jv(v : JsonValue) -> Result[Track, String] {
  let fields = match jv_get_fields(v) {
    Ok(f) => f
    Err(e) => return Err(e)
  }
  let channel = match jv_lookup(fields, "channel") {
    Ok(jv) =>
      match jv_as_int(jv) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
    Err(_e) => 0
  }
  let program = match jv_lookup(fields, "program") {
    Ok(jv) =>
      match jv_as_int(jv) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
    Err(_e) => -1
  }
  let volume = match jv_lookup(fields, "volume") {
    Ok(jv) =>
      match jv_as_double(jv) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
    Err(_e) => 1.0
  }
  let pan = match jv_lookup(fields, "pan") {
    Ok(jv) =>
      match jv_as_double(jv) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
    Err(_e) => 0.0
  }
  let mute = match jv_lookup(fields, "mute") {
    Ok(jv) =>
      match jv_as_bool(jv) {
        Ok(b) => b
        Err(e) => return Err(e)
      }
    Err(_e) => false
  }
  let events_jv = match jv_lookup(fields, "events") {
    Ok(jv) => jv
    Err(e) => return Err(e)
  }
  let event_arr = match jv_as_array(events_jv) {
    Ok(arr) => arr
    Err(e) => return Err(e)
  }
  let events = []
  for evjv in event_arr {
    match music_event_from_jv(evjv) {
      Ok(ev) => events.push(ev)
      Err(e) => return Err(e)
    }
  }
  Ok({ events, channel, program, volume, pan, mute })
}

///|
/// 从 JSON 字符串反序列化为 Score
pub fn score_from_json_string(input : String) -> Result[Score, String] {
  let root = match json_parse(input) {
    Ok(jv) => jv
    Err(e) => return Err(e)
  }
  let root_fields = match jv_get_fields(root) {
    Ok(f) => f
    Err(e) => return Err(e)
  }
  // 验证 schema
  let _schema = match jv_lookup(root_fields, "schema") {
    Ok(jv) =>
      match jv_as_string(jv) {
        Ok(s) =>
          if s != "moonsic.score" {
            return Err("不支持的 schema：\{s}")
          } else {
            s
          }
        Err(e) => return Err(e)
      }
    Err(e) => return Err(e)
  }
  let _version = match jv_lookup(root_fields, "version") {
    Ok(jv) =>
      match jv_as_int(jv) {
        Ok(n) =>
          if n != 1 {
            return Err("不支持的 version：\{n}")
          } else {
            n
          }
        Err(e) => return Err(e)
      }
    Err(e) => return Err(e)
  }
  let data_jv = match jv_lookup(root_fields, "data") {
    Ok(jv) => jv
    Err(e) => return Err(e)
  }
  let data_fields = match jv_get_fields(data_jv) {
    Ok(f) => f
    Err(e) => return Err(e)
  }
  let tempo_jv = match jv_lookup(data_fields, "tempo") {
    Ok(jv) => jv
    Err(e) => return Err(e)
  }
  let tempo_val = match tempo_from_jv(tempo_jv) {
    Ok(t) => t
    Err(e) => return Err(e)
  }
  let ts_jv = match jv_lookup(data_fields, "time_signature") {
    Ok(jv) => jv
    Err(e) => return Err(e)
  }
  let ts_val = match time_sig_from_jv(ts_jv) {
    Ok(ts) => ts
    Err(e) => return Err(e)
  }
  let mg = match jv_lookup(data_fields, "master_gain") {
    Ok(jv) =>
      match jv_as_double(jv) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
    Err(_e) => 0.85
  }
  let tracks_jv = match jv_lookup(data_fields, "tracks") {
    Ok(jv) => jv
    Err(e) => return Err(e)
  }
  let track_arr = match jv_as_array(tracks_jv) {
    Ok(arr) => arr
    Err(e) => return Err(e)
  }
  let tracks = []
  for tjv in track_arr {
    match track_from_jv(tjv) {
      Ok(t) => tracks.push(t)
      Err(e) => return Err(e)
    }
  }
  Ok({ tempo: tempo_val, time_signature: ts_val, tracks, master_gain: mg })
}

// ============================================================
// 统一解析入口 — 封装已有 parse_* 函数，返回 JSON
// ============================================================

///|
/// 统一解析入口。kind 支持："pitch", "chord", "scale", "interval", "time", "tempo", "melody", "score"
/// 返回 JSON 字符串：{"ok":true,"data":...} 或 {"ok":false,"error":"..."}
pub fn parse_to_json(input : String, kind : String) -> String {
  match kind {
    "pitch" => wrap_pitch_to_json(input)
    "chord" => wrap_chord_to_json(input)
    "scale" => wrap_scale_to_json(input)
    "interval" => wrap_interval_to_json(input)
    "time" => wrap_time_sig_to_json(input)
    "tempo" => wrap_tempo_to_json(input)
    "melody" => wrap_melody_to_json(input)
    "score" => wrap_score_str_to_json(input)
    _ => "{\"ok\":false,\"error\":\"不支持的类型：\{kind}\"}"
  }
}

///|
fn wrap_pitch_to_json(input : String) -> String {
  match parse_pitch(input) {
    Ok(p) => "{\"ok\":true,\"data\":" + json_stringify(pitch_to_jv(p)) + "}"
    Err(e) => "{\"ok\":false,\"error\":\"\{e}\"}"
  }
}

///|
fn wrap_chord_to_json(input : String) -> String {
  match parse_chord(input) {
    Ok(c) => "{\"ok\":true,\"data\":" + chord_to_json_string(c) + "}"
    Err(e) => "{\"ok\":false,\"error\":\"\{e}\"}"
  }
}

///|
fn wrap_scale_to_json(input : String) -> String {
  match parse_scale(input) {
    Ok(s) => {
      let tone_strs = []
      for t in s.tones {
        tone_strs.push(jv_str(t.to_string()))
      }
      let data = json_stringify(
        jv_obj([
          jv_field("root", jv_str(s.root.to_string())),
          jv_field("scale_type", jv_str(scale_kind_name(s.scale_type))),
          jv_field("tones", jv_arr(tone_strs)),
        ]),
      )
      "{\"ok\":true,\"data\":" + data + "}"
    }
    Err(e) => "{\"ok\":false,\"error\":\"\{e}\"}"
  }
}

///|
fn scale_kind_name(k : ScaleKind) -> String {
  match k {
    Major => "major"
    NaturalMinor => "natural minor"
    MajorPentatonic => "major pentatonic"
    MinorPentatonic => "minor pentatonic"
    HarmonicMinor => "harmonic minor"
    MelodicMinor => "melodic minor"
    Dorian => "dorian"
    Phrygian => "phrygian"
    Lydian => "lydian"
    Mixolydian => "mixolydian"
    Locrian => "locrian"
    Chromatic => "chromatic"
  }
}

///|
fn wrap_interval_to_json(input : String) -> String {
  match parse_interval(input) {
    Ok(iv) => {
      let data = json_stringify(
        jv_obj([
          jv_field("quality", jv_str(iv.quality.to_string())),
          jv_field("number", jv_int(iv.number)),
          jv_field("semitones", jv_int(iv.semitones)),
        ]),
      )
      "{\"ok\":true,\"data\":" + data + "}"
    }
    Err(e) => "{\"ok\":false,\"error\":\"\{e}\"}"
  }
}

///|
fn wrap_time_sig_to_json(input : String) -> String {
  match parse_time_sig(input) {
    Ok(ts) => {
      let data = json_stringify(time_sig_to_jv(ts))
      "{\"ok\":true,\"data\":" + data + "}"
    }
    Err(e) => "{\"ok\":false,\"error\":\"\{e.to_string()}\"}"
  }
}

///|
fn wrap_tempo_to_json(input : String) -> String {
  match parse_tempo(input) {
    Ok(bpm) => {
      let data = "{\"bpm\":" + bpm.to_string() + "}"
      "{\"ok\":true,\"data\":" + data + "}"
    }
    Err(e) => "{\"ok\":false,\"error\":\"\{e.to_string()}\"}"
  }
}

///|
fn wrap_melody_to_json(input : String) -> String {
  let track = melody_str(input)
  let json = track_to_json(track)
  "{\"ok\":true,\"data\":" + json + "}"
}

///|
fn wrap_score_str_to_json(input : String) -> String {
  let s = score_str(input)
  let json = score_to_json(s)
  "{\"ok\":true,\"data\":" + json + "}"
}
