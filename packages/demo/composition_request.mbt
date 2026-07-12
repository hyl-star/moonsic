// ============================================================
// CompositionRequest — 作曲请求协议
// ============================================================

///|
/// 作曲风格枚举
pub(all) enum CompositionStyle {
  StylePop
  StyleAmbient
  StyleGame
  StyleCinematic
  StyleStudy
  StyleCustom(String)
}

///|
pub fn CompositionStyle::to_string(self : CompositionStyle) -> String {
  match self {
    StylePop => "pop"
    StyleAmbient => "ambient"
    StyleGame => "game"
    StyleCinematic => "cinematic"
    StyleStudy => "study"
    StyleCustom(name) => name
  }
}

///|
/// 解析风格字符串 -> CompositionStyle
pub fn parse_composition_style(input : String) -> CompositionStyle {
  match input {
    "pop" => StylePop
    "ambient" => StyleAmbient
    "game" => StyleGame
    "cinematic" => StyleCinematic
    "study" => StyleStudy
    _ => StyleCustom(input)
  }
}

///|
/// 原始作曲请求（字符串字段）
pub(all) struct CompositionRequest {
  key : String
  scale : String
  tempo : Int
  bars : Int
  style : String
  chord_progression : Array[String]
  seed : Int
}

///|
/// 和弦进行解析结果：包含解析出的音级数组和警告
pub(all) struct ChordProgressionParseResult {
  degrees : Array[Int]
  warnings : Array[DemoWarning]
}

///|
/// 标准化结果：包含标准化请求和和弦解析阶段产生的 warnings
pub(all) struct NormalizeResult {
  request : NormalizedCompositionRequest
  warnings : Array[DemoWarning]
}

///|
/// 标准化后的作曲请求（强类型字段）
pub(all) struct NormalizedCompositionRequest {
  key_name : String
  scale_kind : @scale.ScaleKind
  key_obj : @scale.Key
  tempo : @score.Tempo
  bars : Int
  style : CompositionStyle
  chord_degrees : Array[Int]
  seed : Int
}

///|
/// JSON 解析结果：可能包含部分字段默认值 warning
pub(all) struct CompositionRequestParseResult {
  request : CompositionRequest
  warnings : Array[DemoWarning]
}

///|
/// 默认作曲请求
pub fn default_composition_request() -> CompositionRequest {
  {
    key: "C",
    scale: "major",
    tempo: 120,
    bars: 4,
    style: "pop",
    chord_progression: ["I", "V", "vi", "IV"],
    seed: 1,
  }
}

///|
/// 手动构造 checked 作曲请求
pub fn composition_request_checked(
  key : String,
  scale : String,
  tempo : Int,
  bars : Int,
  style : String,
  chord_progression : Array[String],
  seed : Int,
) -> Result[CompositionRequest, DemoError] {
  if key == "" {
    return Err(InvalidRequest("key must not be empty"))
  }
  if scale == "" {
    return Err(InvalidRequest("scale must not be empty"))
  }
  if tempo <= 0 {
    return Err(InvalidRequest("tempo must be > 0, got \{tempo}"))
  }
  if bars <= 0 {
    return Err(InvalidRequest("bars must be > 0, got \{bars}"))
  }
  Ok({ key, scale, tempo, bars, style, chord_progression, seed })
}

///|
/// 标准化请求：解析字符串字段为强类型。
/// 和弦解析阶段的 warnings 会被丢弃。如需保留 warnings，请使用 normalize_with_warnings_checked。
pub fn normalize_composition_request_checked(
  request : CompositionRequest,
) -> Result[NormalizedCompositionRequest, DemoError] {
  let result = match normalize_with_warnings_checked(request) {
    Ok(r) => r
    Err(e) => return Err(e)
  }
  Ok(result.request)
}

///|
/// 标准化请求（带 warnings）：返回 NormalizeResult，包含和弦解析阶段的 warnings。
/// 推荐在 pipeline 中使用此函数，以便将和弦解析 warnings 合并到最终 bundle 中。
pub fn normalize_with_warnings_checked(
  request : CompositionRequest,
) -> Result[NormalizeResult, DemoError] {
  // 解析 key + scale
  let full_scale_str = request.key + " " + request.scale
  let scale_obj = match @scale.parse_scale(full_scale_str) {
    Ok(s) => s
    Err(e) => return Err(InvalidRequest("invalid key/scale: " + e.to_string()))
  }
  let key_obj = @scale.key(
    @pitch.pitch(scale_obj.root, scale_obj.root_accidental, 4),
    scale_obj.scale_type,
  )

  // 解析 tempo
  let tempo = match @score.tempo_checked(request.tempo) {
    Ok(t) => t
    Err(e) => return Err(InvalidRequest(e.to_string()))
  }

  // 解析 bars
  if request.bars <= 0 {
    return Err(InvalidRequest("bars must be > 0"))
  }

  // 解析 chord_progression（带 warning）
  let chord_result = parse_chord_progression_checked(
    request.chord_progression,
    key_obj,
  )

  let normalized_request = {
    key_name: request.key,
    scale_kind: scale_obj.scale_type,
    key_obj,
    tempo,
    bars: request.bars,
    style: parse_composition_style(request.style),
    chord_degrees: chord_result.degrees,
    seed: request.seed,
  }

  Ok({ request: normalized_request, warnings: chord_result.warnings })
}

///|
/// 从 JSON 字符串解析作曲请求
pub fn composition_request_from_json_checked(
  input : String,
) -> Result[CompositionRequestParseResult, DemoError] {
  let value = match @json.json_parse(input) {
    Ok(v) => v
    Err(e) => return Err(InvalidRequest("JSON parse error: " + e.to_string()))
  }
  let fields = match @json.json_as_object(value) {
    Ok(f) => f
    Err(e) =>
      return Err(InvalidRequest("expected JSON object: " + e.to_string()))
  }

  let warnings : Array[DemoWarning] = []

  let key = match json_field_string_optional(fields, "key") {
    Some(v) => v
    None => {
      warnings.push(
        demo_warning("request", "default_key", "using default key 'C'"),
      )
      "C"
    }
  }

  let scale = match json_field_string_optional(fields, "scale") {
    Some(v) => v
    None => {
      warnings.push(
        demo_warning("request", "default_scale", "using default scale 'major'"),
      )
      "major"
    }
  }

  let tempo = match json_field_int_optional(fields, "tempo") {
    Some(v) => v
    None => {
      warnings.push(
        demo_warning("request", "default_tempo", "using default tempo 120"),
      )
      120
    }
  }

  let bars = match json_field_int_optional(fields, "bars") {
    Some(v) => v
    None => {
      warnings.push(
        demo_warning("request", "default_bars", "using default bars 4"),
      )
      4
    }
  }

  let style = match json_field_string_optional(fields, "style") {
    Some(v) => v
    None => {
      warnings.push(
        demo_warning("request", "default_style", "using default style 'pop'"),
      )
      "pop"
    }
  }

  let chord_progression = match
    json_field_string_array_optional(fields, "chord_progression") {
    Some(v) => v
    None => {
      warnings.push(
        demo_warning(
          "request", "default_chords", "using default chord progression I-V-vi-IV",
        ),
      )
      ["I", "V", "vi", "IV"]
    }
  }

  let seed = match json_field_int_optional(fields, "seed") {
    Some(v) => v
    None => {
      warnings.push(
        demo_warning("request", "default_seed", "using default seed 1"),
      )
      1
    }
  }

  // 验证关键值
  if tempo <= 0 {
    return Err(InvalidRequest("tempo must be > 0, got \{tempo}"))
  }
  if bars <= 0 {
    return Err(InvalidRequest("bars must be > 0, got \{bars}"))
  }

  Ok({
    request: { key, scale, tempo, bars, style, chord_progression, seed },
    warnings,
  })
}

///|
/// 将作曲请求序列化为 JSON
pub fn composition_request_to_json(request : CompositionRequest) -> String {
  let chords : Array[@json.JsonValue] = []
  for c in request.chord_progression {
    chords.push(@json.json_string(c))
  }
  @json.json_stringify(
    @json.json_object([
      @json.json_field("key", @json.json_string(request.key)),
      @json.json_field("scale", @json.json_string(request.scale)),
      @json.json_field("tempo", @json.json_int(request.tempo)),
      @json.json_field("bars", @json.json_int(request.bars)),
      @json.json_field("style", @json.json_string(request.style)),
      @json.json_field("chord_progression", @json.json_array(chords)),
      @json.json_field("seed", @json.json_int(request.seed)),
    ]),
  )
}

// ============================================================
// 和弦进行解析（公共 API）
// ============================================================

///|
/// 解析和弦进行（checked 版本）：
/// - 支持罗马数字：I, ii, IV, V7, vi 等
/// - 支持常见和弦符号：C, G, Am, F, Bb, F# 等（按 root 映射到当前 key 的 degree）
/// - 无法解析的项产生 warning
/// - 如果全部无法解析，fallback 到 [1,5,6,4] 并记录 warning
pub fn parse_chord_progression_checked(
  symbols : Array[String],
  key_obj : @scale.Key,
) -> ChordProgressionParseResult {
  let degrees : Array[Int] = []
  let warnings : Array[DemoWarning] = []
  for symbol in symbols {
    let trimmed = symbol.trim().to_owned()
    if trimmed.length() == 0 {
      warnings.push(
        demo_warning("request", "empty_chord", "empty chord symbol ignored"),
      )
      continue
    }
    // 尝试罗马数字解析
    match parse_roman_degree(trimmed) {
      Some(d) => {
        degrees.push(d)
        continue
      }
      None => ()
    }
    // 尝试和弦符号解析
    match parse_chord_symbol_degree(trimmed, key_obj) {
      Some(d) => {
        degrees.push(d)
        continue
      }
      None => ()
    }
    // 无法解析
    warnings.push(
      demo_warning(
        "request",
        "unknown_chord",
        "cannot parse chord symbol: " + trimmed,
      ),
    )
  }
  if degrees.length() == 0 {
    warnings.push(
      demo_warning(
        "request", "chord_progression_fallback_default", "all chord symbols failed to parse, fallback to I-V-vi-IV",
      ),
    )
    { degrees: [1, 5, 6, 4], warnings }
  } else {
    { degrees, warnings }
  }
}

// ============================================================
// 内部 helper: JSON 字段提取
// ============================================================

///|
/// 从 JSON fields 中获取可选字符串字段
fn json_field_string_optional(
  fields : Array[@json.JsonField],
  key : String,
) -> String? {
  match @json.json_lookup(fields, key) {
    Ok(@json.JString(s)) => Some(s)
    _ => None
  }
}

///|
/// 从 JSON fields 中获取可选 Int 字段
fn json_field_int_optional(
  fields : Array[@json.JsonField],
  key : String,
) -> Int? {
  match @json.json_lookup(fields, key) {
    Ok(@json.JNumber(n)) => Some(n.to_int())
    _ => None
  }
}

///|
/// 从 JSON fields 中获取可选字符串数组字段
fn json_field_string_array_optional(
  fields : Array[@json.JsonField],
  key : String,
) -> Array[String]? {
  match @json.json_lookup(fields, key) {
    Ok(@json.JArray(items)) => {
      let result : Array[String] = []
      for item in items {
        match item {
          @json.JString(s) => result.push(s)
          _ => ()
        }
      }
      if result.length() > 0 {
        Some(result)
      } else {
        None
      }
    }
    _ => None
  }
}

// ============================================================
// 内部 helper: 和弦解析
// ============================================================

///|
/// 解析罗马数字音级：I=1, II=2, ..., VII=7（大小写不敏感）
/// 支持后缀 7（如 V7、ii7）
fn parse_roman_degree(symbol : String) -> Int? {
  match symbol {
    "I" | "i" => Some(1)
    "II" | "ii" => Some(2)
    "III" | "iii" => Some(3)
    "IV" | "iv" => Some(4)
    "V" | "v" => Some(5)
    "VI" | "vi" => Some(6)
    "VII" | "vii" => Some(7)
    "I7" | "i7" => Some(1)
    "II7" | "ii7" => Some(2)
    "III7" | "iii7" => Some(3)
    "IV7" | "iv7" => Some(4)
    "V7" | "v7" => Some(5)
    "VI7" | "vi7" => Some(6)
    "VII7" | "vii7" => Some(7)
    _ => None
  }
}

///|
/// 解析和弦符号为音级（相对于 key 的 scale）
/// 提取根音 semitone，然后在 key 的 scale 中查找匹配的音级
fn parse_chord_symbol_degree(symbol : String, key : @scale.Key) -> Int? {
  let semitone = match parse_chord_root_semitone(symbol) {
    Some(st) => st
    None => return None
  }
  map_semitone_to_degree(semitone, key)
}

///|
/// 将 semitone (0-11) 映射到 key 的音级 (1-7)
/// 在 key 的 scale（7 个音）中查找匹配 semitone 的音，返回其音级编号
fn map_semitone_to_degree(semitone : Int, key : @scale.Key) -> Int? {
  let scale_pitches = key.scale(4, 1)
  for i = 0; i < scale_pitches.length(); i = i + 1 {
    if scale_pitches[i].to_midi() % 12 == semitone {
      return Some(i + 1)
    }
  }
  None
}

///|
/// 从和弦符号中提取根音的 semitone 值（0-11）
/// 支持 "C"→0, "D"→2, "C#"→1, "Db"→1, "F#m7"→6, "Bbmaj7"→10
/// 拒绝非和弦符号的字符串（如 "???", "bad_chord"）
fn parse_chord_root_semitone(symbol : String) -> Int? {
  let len = symbol.length()
  if len == 0 {
    return None
  }
  // 解析根音字母（第 1 字符，必须是大写 C-B）
  let base = match symbol[0] {
    'C' => 0
    'D' => 2
    'E' => 4
    'F' => 5
    'G' => 7
    'A' => 9
    'B' => 11
    _ => return None
  }
  // 解析可选变音记号（第 2 字符为 # 或 b）
  let mut offset = 0
  let mut root_len = 1
  if len >= 2 && (symbol[1] == '#' || symbol[1] == 'b') {
    offset = if symbol[1] == '#' { 1 } else { -1 }
    root_len = 2
  }
  // 验证剩余部分（quality）是否合理
  // 截取 quality 子串
  if root_len < len {
    let quality = symbol_substring(symbol, root_len, len)
    if !is_plausible_quality(quality) {
      return None
    }
  }
  Some((base + offset + 12) % 12)
}

///|
/// 检查 chord quality 子串是否合理（仅含字母数字和 + - #）
/// 拒绝含下划线、空格等特殊字符的字符串
fn is_plausible_quality(quality : String) -> Bool {
  for i = 0; i < quality.length(); i = i + 1 {
    let ch = quality[i]
    if (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') {
      continue
    }
    if ch >= '0' && ch <= '9' {
      continue
    }
    if ch == '+' || ch == '-' || ch == '#' {
      continue
    }
    return false
  }
  true
}

///|
/// 从字符串中截取子串 [start, end)
fn symbol_substring(symbol : String, start : Int, end : Int) -> String {
  let mut result : String = ""
  for i = start; i < end; i = i + 1 {
    result = result + symbol[i].to_string()
  }
  result
}
