//
// 解析层 — 拍号、时值单位、速度
//

// ============================================================
// 解析辅助函数
// ============================================================

///|
/// 在字符串中查找字符码对应的位置，未找到返回 -1
fn index_of_char(s : String, target : Int) -> Int {
  for i = 0; i < s.length(); i = i + 1 {
    if s[i].to_int() == target {
      return i
    }
  }
  -1
}

///|
/// 从指定位置查找字符码，未找到返回 -1
fn index_of_char_from(s : String, target : Int, start : Int) -> Int {
  for i = start; i < s.length(); i = i + 1 {
    if s[i].to_int() == target {
      return i
    }
  }
  -1
}

///|
/// 解析整数字符串
fn parse_int_string(s : String) -> Result[Int, TimeError] {
  let trimmed = s.trim().to_owned()
  if trimmed.length() == 0 {
    return Err(TimeParseError("空数字字符串"))
  }
  let mut i = 0
  let mut negative = false
  if trimmed[0] == '+' {
    i = 1
  } else if trimmed[0] == '-' {
    negative = true
    i = 1
  }
  if i >= trimmed.length() {
    return Err(TimeParseError("空数字：\{trimmed}"))
  }
  let mut val : Int = 0
  let mut has_digit = false
  while i < trimmed.length() {
    let c = trimmed[i]
    if c >= '0' && c <= '9' {
      val = val * 10 + (c.to_int() - '0'.to_int())
      has_digit = true
      i = i + 1
    } else {
      return Err(TimeParseError("无效字符：\{c}"))
    }
  }
  if !has_digit {
    return Err(TimeParseError("无数字：\{trimmed}"))
  }
  if negative {
    val = -val
  }
  Ok(val)
}

///|
/// 解析 Double 字符串
fn parse_double_string(s : String) -> Result[Double, TimeError] {
  let trimmed = s.trim().to_owned()
  if trimmed.length() == 0 {
    return Err(TimeParseError("空数字字符串"))
  }
  let mut i = 0
  let mut negative = false
  if trimmed[0] == '+' {
    i = 1
  } else if trimmed[0] == '-' {
    negative = true
    i = 1
  }
  if i >= trimmed.length() {
    return Err(TimeParseError("空数字：\{trimmed}"))
  }
  let mut int_part : Int = 0
  let mut has_digit = false
  while i < trimmed.length() && trimmed[i] != '.' {
    let c = trimmed[i]
    if c >= '0' && c <= '9' {
      int_part = int_part * 10 + (c.to_int() - '0'.to_int())
      has_digit = true
      i = i + 1
    } else {
      return Err(TimeParseError("无效字符：\{c}"))
    }
  }
  if !has_digit {
    return Err(TimeParseError("无数字：\{trimmed}"))
  }
  let mut result = int_part.to_double()
  if i < trimmed.length() && trimmed[i] == '.' {
    i = i + 1
    let mut frac : Double = 0.0
    let mut div : Double = 10.0
    while i < trimmed.length() {
      let c = trimmed[i]
      if c >= '0' && c <= '9' {
        frac = frac + (c.to_int() - '0'.to_int()).to_double() / div
        div = div * 10.0
        i = i + 1
      } else {
        return Err(TimeParseError("无效字符：\{c}"))
      }
    }
    result = result + frac
  }
  if i != trimmed.length() {
    return Err(
      TimeParseError(
        "尾部多余字符：\{trimmed[i:trimmed.length()].to_owned()}",
      ),
    )
  }
  if negative {
    result = -result
  }
  Ok(result)
}

// ============================================================
// 拍号解析
// ============================================================

///|
/// 解析拍号："4/4"、"6/8"、"3/4" 等
pub fn parse_time_sig(s : String) -> Result[TimeSignature, TimeError] {
  let trimmed = s.trim().to_owned()
  if trimmed.length() == 0 {
    return Err(TimeParseError("空输入"))
  }
  let slash_idx = index_of_char(trimmed, '/'.to_int())
  if slash_idx < 0 || slash_idx == 0 || slash_idx == trimmed.length() - 1 {
    return Err(TimeParseError("格式错误，期望 'n/d'：\{trimmed}"))
  }
  let num_str = trimmed[0:slash_idx].to_owned()
  let den_str = trimmed[slash_idx + 1:trimmed.length()].to_owned()
  let num_r = parse_int_string(num_str)
  let den_r = parse_int_string(den_str)
  match (num_r, den_r) {
    (Ok(n), Ok(d)) => {
      if !is_valid_time_signature(n, d) {
        return Err(InvalidTimeSignature("无效拍号：\{n}/\{d}"))
      }
      Ok(time_signature(n, d))
    }
    (Err(e), _) => Err(e)
    (_, Err(e)) => Err(e)
  }
}

// ============================================================
// 时值单位解析
// ============================================================

///|
/// 分离附点：从 "q.." → ("q", 2)
fn split_dots(s : String) -> (String, Int) {
  let len = s.length()
  let mut dots = 0
  let mut i = len - 1
  while i >= 0 && s[i].to_int() == '.'.to_int() {
    dots = dots + 1
    i = i - 1
  }
  if dots > 0 {
    (s[0:len - dots].to_owned(), dots)
  } else {
    (s, 0)
  }
}

///|
/// 解析单位字符串："w", "h", "q", "8", "16", "32", "64", "128"
fn parse_unit_string(s : String) -> Result[DurUnit, TimeError] {
  match s {
    "w" | "whole" | "1" => Ok(DurWhole)
    "h" | "half" | "2" => Ok(DurHalf)
    "q" | "quarter" | "4" => Ok(DurQuarter)
    "e" | "eighth" | "8" => Ok(DurEighth)
    "s" | "sixteenth" | "16" => Ok(DurSixteenth)
    "32" | "thirtysecond" => Ok(ThirtySecond)
    "64" | "sixtyfourth" => Ok(SixtyFourth)
    "128" | "onetwentyeighth" => Ok(OneTwentyEighth)
    _ => Err(TimeParseError("未知时值单位：\{s}"))
  }
}

///|
/// 解析时值单位："q"、"8."、"3:2 8" 等
pub fn parse_dur_unit(s : String) -> Result[RhythmDuration, TimeError] {
  let trimmed = s.trim().to_owned()
  if trimmed.length() == 0 {
    return Err(TimeParseError("空输入"))
  }
  // 检查是否有连音格式 "N:M U"
  let colon_idx = index_of_char(trimmed, ':'.to_int())
  if colon_idx > 0 {
    // 连音格式
    let space_idx = index_of_char_from(trimmed, ' '.to_int(), colon_idx)
    if space_idx < 0 {
      return Err(
        TimeParseError("连音格式期望 'N:M U'，缺少空格：\{trimmed}"),
      )
    }
    let actual_r = parse_int_string(trimmed[0:colon_idx].to_owned())
    let normal_r = parse_int_string(trimmed[colon_idx + 1:space_idx].to_owned())
    let unit_str = trimmed[space_idx + 1:trimmed.length()]
      .to_owned()
      .trim()
      .to_owned()
    match (actual_r, normal_r) {
      (Ok(actual), Ok(normal)) => {
        if actual <= 0 || normal <= 0 {
          return Err(
            TimeParseError("连音比必须为正数：\{actual}:\{normal}"),
          )
        }
        let unit = parse_unit_string(unit_str)
        match unit {
          Ok(u) => Ok({ unit: u, dots: 0, tuplet: Some({ actual, normal }) })
          Err(e) => Err(e)
        }
      }
      (Err(e), _) => Err(e)
      (_, Err(e)) => Err(e)
    }
  } else {
    // 简单格式：单位 + 可选附点
    let (unit_str, dots) = split_dots(trimmed)
    let unit = parse_unit_string(unit_str)
    match unit {
      Ok(u) => Ok({ unit: u, dots, tuplet: None })
      Err(e) => Err(e)
    }
  }
}

// ============================================================
// 速度解析
// ============================================================

///|
/// 解析速度："120"、"120bpm" → Double BPM
pub fn parse_tempo(s : String) -> Result[Double, TimeError] {
  let trimmed = s.trim().to_owned()
  if trimmed.length() == 0 {
    return Err(TimeParseError("空输入"))
  }
  let num_str = if trimmed.has_suffix("bpm") {
    trimmed[0:trimmed.length() - 3].to_owned().trim().to_owned()
  } else if trimmed.has_suffix("BPM") {
    trimmed[0:trimmed.length() - 3].to_owned().trim().to_owned()
  } else {
    trimmed
  }
  let d = parse_double_string(num_str)
  match d {
    Ok(v) =>
      if v <= 0.0 {
        Err(InvalidTempo("BPM 必须 > 0，当前：\{v}"))
      } else {
        Ok(v)
      }
    Err(e) => Err(e)
  }
}
