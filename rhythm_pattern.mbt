//
// 节奏模板 — 内置模板、解析、构建
//

// ============================================================
// 核心枚举
// ============================================================

///|
/// 内置节奏模板种类
pub(all) enum RhythmTemplateKind {
  FourQuarters // q q q q
  TwoHalves // h h
  WholePad // w
  EighthFlow // 8 8 8 8 8 8 8 8
  Syncopated // 8 q 8 q q
  LongShort // h q q
  ShortShortLong // q q h
  Waltz // q q q
  Tresillo // q. q. q
  RestLead // R8 8 q h
}

///|
/// 重音强度，带力度倍率
pub(all) enum AccentStrength {
  NoAccent // 倍率 1.0
  Weak // 倍率 0.85
  Medium // 倍率 1.0
  Strong // 倍率 1.15
  Marcato // 倍率 1.3
}

///|
/// 获取重音的力度倍率
pub fn AccentStrength::velocity_multiplier(self : AccentStrength) -> Double {
  match self {
    NoAccent => 1.0
    Weak => 0.85
    Medium => 1.0
    Strong => 1.15
    Marcato => 1.3
  }
}

// ============================================================
// 核心数据结构
// ============================================================

///|
/// 节奏单元：时值 + 是否休止 + 重音 + 连音线
pub(all) struct RhythmCell {
  duration : Duration
  is_rest : Bool
  accent : AccentStrength
  tie_to_next : Bool
}

///|
/// 节奏模板 = 有序节奏单元序列 + 总拍数
pub(all) struct RhythmPattern {
  cells : Array[RhythmCell]
  total_beats : Double
}

// ============================================================
// 内部辅助函数
// ============================================================

///|
/// 计算 RhythmCell 数组的总拍数
fn calc_cells_beats(cells : Array[RhythmCell]) -> Double {
  let mut total = 0.0
  for c in cells {
    total = total + c.duration.beats()
  }
  total
}

///|
/// 创建默认 RhythmCell（无重音，无连音线，默认不休息）
fn default_cell(duration : Duration, is_rest : Bool) -> RhythmCell {
  { duration, is_rest, accent: NoAccent, tie_to_next: false }
}

///|
/// 将 RhythmDuration 转为 Duration（核心转换）
fn rhythm_duration_to_duration(rd : RhythmDuration) -> Duration {
  let base = match rd.unit {
    DurWhole => Whole
    DurHalf => Half
    DurQuarter => Quarter
    DurEighth => Eighth
    DurSixteenth => Sixteenth
    ThirtySecond => duration_from_beats(0.125)
    SixtyFourth => duration_from_beats(0.0625)
    OneTwentyEighth => duration_from_beats(0.03125)
  }
  let mut result = base
  for i = 0; i < rd.dots; i = i + 1 {
    result = Dotted(result)
  }
  match rd.tuplet {
    Some(ratio) => {
      let b = result.beats() *
        ratio.normal.to_double() /
        ratio.actual.to_double()
      duration_from_beats(b)
    }
    None => result
  }
}

///|
/// 按空格分割字符串为 token 数组
fn split_whitespace(s : String) -> Array[String] {
  let result = []
  let mut current = ""
  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i]
    if c == ' ' || c == '\t' || c == '\n' || c == '\r' {
      if current.length() > 0 {
        result.push(current)
        current = ""
      }
    } else {
      current += s[i:i + 1].to_owned()
    }
  }
  if current.length() > 0 {
    result.push(current)
  }
  result
}

///|
/// 解析单个节奏 token（如 "q"、"q."、"R8"、"Rq."）
/// 返回 (duration, is_rest)
fn parse_rhythm_token(token : String) -> Result[(Duration, Bool), MotifError] {
  let mut is_rest = false
  let dur_str = if token.length() > 1 && token[0] == 'R' {
    is_rest = true
    token[1:token.length()].to_owned()
  } else {
    token
  }
  if dur_str.length() == 0 {
    return Err(MotifParseError("空节奏 token"))
  }
  let rd = match parse_dur_unit(dur_str) {
    Ok(r) => r
    Err(e) =>
      return Err(
        MotifParseError(
          "无法解析节奏 token '\{dur_str}'：\{e.to_string()}",
        ),
      )
  }
  let dur = rhythm_duration_to_duration(rd)
  Ok((dur, is_rest))
}

// ============================================================
// 节奏模板 API
// ============================================================

///|
/// 构建强类型节奏模板（checked），校验空模板和无效 cell
pub fn rhythm_pattern_checked(
  cells : Array[RhythmCell],
) -> Result[RhythmPattern, MotifError] {
  if cells.length() == 0 {
    return Err(EmptyRhythmPattern("cells 数组为空"))
  }
  for c in cells {
    if c.duration.beats() <= 0.0 {
      return Err(InvalidRhythmCell("时值拍数必须 > 0"))
    }
  }
  let total = calc_cells_beats(cells)
  Ok({ cells, total_beats: total })
}

///|
/// 便捷 API：构建节奏模板，空模板 fallback 到 [Quarter]
pub fn rhythm_pattern(cells : Array[RhythmCell]) -> RhythmPattern {
  match rhythm_pattern_checked(cells) {
    Ok(p) => p
    Err(_) => {
      let fallback = [default_cell(Quarter, false)]
      { cells: fallback, total_beats: 1.0 }
    }
  }
}

///|
/// 返回内置节奏模板
pub fn rhythm_template(kind : RhythmTemplateKind) -> RhythmPattern {
  let cells = match kind {
    FourQuarters =>
      [
        default_cell(Quarter, false),
        default_cell(Quarter, false),
        default_cell(Quarter, false),
        default_cell(Quarter, false),
      ]
    TwoHalves => [default_cell(Half, false), default_cell(Half, false)]
    WholePad => [default_cell(Whole, false)]
    EighthFlow =>
      [
        default_cell(Eighth, false),
        default_cell(Eighth, false),
        default_cell(Eighth, false),
        default_cell(Eighth, false),
        default_cell(Eighth, false),
        default_cell(Eighth, false),
        default_cell(Eighth, false),
        default_cell(Eighth, false),
      ]
    Syncopated =>
      [
        default_cell(Eighth, false),
        default_cell(Quarter, false),
        default_cell(Eighth, false),
        default_cell(Quarter, false),
        default_cell(Quarter, false),
      ]
    LongShort =>
      [
        default_cell(Half, false),
        default_cell(Quarter, false),
        default_cell(Quarter, false),
      ]
    ShortShortLong =>
      [
        default_cell(Quarter, false),
        default_cell(Quarter, false),
        default_cell(Half, false),
      ]
    Waltz =>
      [
        default_cell(Quarter, false),
        default_cell(Quarter, false),
        default_cell(Quarter, false),
      ]
    Tresillo =>
      [
        default_cell(Dotted(Quarter), false),
        default_cell(Dotted(Quarter), false),
        default_cell(Quarter, false),
      ]
    RestLead =>
      [
        default_cell(Eighth, true),
        default_cell(Eighth, false),
        default_cell(Quarter, false),
        default_cell(Half, false),
      ]
  }
  { cells, total_beats: calc_cells_beats(cells) }
}

///|
/// 解析字符串节奏模板："q q h"、"8 8 q q"、"R8 q q." 等
pub fn parse_rhythm_pattern(
  input : String,
) -> Result[RhythmPattern, MotifError] {
  let trimmed = input.trim().to_owned()
  if trimmed.length() == 0 {
    return Err(MotifParseError("空输入"))
  }
  let tokens = split_whitespace(trimmed)
  if tokens.length() == 0 {
    return Err(MotifParseError("无有效 token"))
  }
  let cells : Array[RhythmCell] = []
  for token in tokens {
    let (dur, is_rest) = match parse_rhythm_token(token) {
      Ok(r) => r
      Err(e) => return Err(e)
    }
    cells.push(default_cell(dur, is_rest))
  }
  rhythm_pattern_checked(cells)
}

// ============================================================
// FFI API
// ============================================================

///|
/// FFI：解析节奏模板字符串，返回 JSON
/// 成功：{"ok":true,"data":{"total_beats":N,"cells":[...]}}
/// 失败：{"ok":false,"error":"MotifError","message":"..."}
pub fn ffi_parse_rhythm_pattern_json(input : String) -> String {
  match parse_rhythm_pattern(input) {
    Ok(pattern) => {
      let data = build_rhythm_pattern_json(pattern)
      "{\"ok\":true,\"data\":" + data + "}"
    }
    Err(e) => build_ffi_error("MotifError", e.to_string())
  }
}

///|
/// 构建 RhythmPattern 的 JSON 表示
fn build_rhythm_pattern_json(p : RhythmPattern) -> String {
  let mut cells_out = "["
  for i = 0; i < p.cells.length(); i = i + 1 {
    if i > 0 {
      cells_out += ","
    }
    cells_out += cell_json(p.cells[i])
  }
  cells_out += "]"
  "{\"total_beats\":" +
  format_double(p.total_beats) +
  ",\"cells\":" +
  cells_out +
  "}"
}

///|
/// RhythmCell 转 JSON
fn cell_json(c : RhythmCell) -> String {
  "{\"duration\":\"" +
  c.duration.to_string() +
  "\",\"is_rest\":" +
  (if c.is_rest { "true" } else { "false" }) +
  ",\"beats\":" +
  format_double(c.duration.beats()) +
  "}"
}

///|
/// 构建 FFI 错误响应 {"ok":false,"error":"...","message":"..."}
fn build_ffi_error(error : String, message : String) -> String {
  "{\"ok\":false,\"error\":" +
  json_escape(error) +
  ",\"message\":" +
  json_escape(message) +
  "}"
}

///|
/// 格式化 Double 为 JSON 友好的字符串
fn format_double(d : Double) -> String {
  let int_part = d.to_int()
  let frac = d - int_part.to_double()
  if frac * frac < 0.000001 {
    int_part.to_string()
  } else {
    int_part.to_string() +
    "." +
    ((frac.abs() * 1000000.0).to_int() % 1000000).to_string()
  }
}
