//
// 节奏与时间模块 — 有理数、时值单位、节奏换算、BPM/拍号解析
//

// ============================================================
// 时间错误类型 TimeError
// ============================================================

///|
/// 节奏与时间模块的统一错误类型
pub(all) enum TimeError {
  InvalidRational(String)
  InvalidTimeSignature(String)
  InvalidDuration(String)
  InvalidTempo(String)
  InvalidPPQ(String)
  InvalidTick(String)
  TimeParseError(String)
  NonIntegralTick(String)
  TimeUnsupported(String)
}

///|
/// 转为可读的错误消息（中文）
pub fn TimeError::to_string(self : TimeError) -> String {
  match self {
    InvalidRational(msg) => "无效有理数：\{msg}"
    InvalidTimeSignature(msg) => "无效拍号：\{msg}"
    InvalidDuration(msg) => "无效时值：\{msg}"
    InvalidTempo(msg) => "无效速度：\{msg}"
    InvalidPPQ(msg) => "无效 PPQ：\{msg}"
    InvalidTick(msg) => "无效 tick：\{msg}"
    TimeParseError(msg) => "解析错误：\{msg}"
    NonIntegralTick(msg) => "非整数 tick：\{msg}"
    TimeUnsupported(msg) => "不支持：\{msg}"
  }
}

// ============================================================
// 有理数 Rational — 精确的分数表示
// ============================================================

///|
/// 有理数 = 分子/分母（自动约分，分母恒正）
pub(all) struct Rational {
  numerator : Int
  denominator : Int
}

///|
/// 创建有理数，分母必须 > 0，自动约分
pub fn rational(n : Int, d : Int) -> Result[Rational, TimeError] {
  if d <= 0 {
    return Err(InvalidRational("分母必须 > 0，当前：\{d}"))
  }
  let (n_red, d_red) = reduce_frac(n, d)
  Ok({ numerator: n_red, denominator: d_red })
}

///|
/// 内部：不验证、已约分的直接构造
fn rational_raw(n : Int, d : Int) -> Rational {
  let (n_red, d_red) = reduce_frac(n, d)
  { numerator: n_red, denominator: d_red }
}

///|
/// 约分（gcd，确保分母为正）
fn reduce_frac(n : Int, d : Int) -> (Int, Int) {
  let g = gcd(if n < 0 { -n } else { n }, if d < 0 { -d } else { d })
  let num = n / g
  let den = d / g
  if den < 0 {
    (-num, -den)
  } else {
    (num, den)
  }
}

///|
/// 最大公约数（欧几里得算法）
fn gcd(a : Int, b : Int) -> Int {
  let mut x = a
  let mut y = b
  while y != 0 {
    let t = y
    y = x % y
    x = t
  }
  x
}

///|
/// 有理数加法：a + b
pub fn rational_add(a : Rational, b : Rational) -> Rational {
  let n = a.numerator * b.denominator + b.numerator * a.denominator
  let d = a.denominator * b.denominator
  rational_reduce({ numerator: n, denominator: d })
}

///|
/// 有理数减法：a - b
pub fn rational_sub(a : Rational, b : Rational) -> Rational {
  let n = a.numerator * b.denominator - b.numerator * a.denominator
  let d = a.denominator * b.denominator
  rational_reduce({ numerator: n, denominator: d })
}

///|
/// 有理数乘法：a * b
pub fn rational_mul(a : Rational, b : Rational) -> Rational {
  let n = a.numerator * b.numerator
  let d = a.denominator * b.denominator
  rational_reduce({ numerator: n, denominator: d })
}

///|
/// 有理数除法：a / b（b 的分子不能为 0）
pub fn rational_div(a : Rational, b : Rational) -> Result[Rational, TimeError] {
  if b.numerator == 0 {
    return Err(InvalidRational("除数为 0"))
  }
  let n = a.numerator * b.denominator
  let d = a.denominator * b.numerator
  Ok(rational_reduce({ numerator: n, denominator: d }))
}

///|
/// 约分有理数
fn rational_reduce(r : Rational) -> Rational {
  let (n, d) = reduce_frac(r.numerator, r.denominator)
  { numerator: n, denominator: d }
}

///|
/// 判断有理数是否为整数
pub fn rational_is_integer(v : Rational) -> Bool {
  v.numerator % v.denominator == 0
}

///|
/// 有理数转为 Int（仅当为整数时成功）
pub fn rational_to_int(v : Rational) -> Result[Int, TimeError] {
  if rational_is_integer(v) {
    Ok(v.numerator / v.denominator)
  } else {
    Err(
      NonIntegralTick("有理数 \{v.numerator}/\{v.denominator} 不是整数"),
    )
  }
}

///|
/// 有理数转为 Double
pub fn rational_to_double(v : Rational) -> Double {
  v.numerator.to_double() / v.denominator.to_double()
}

///|
/// 有理数转为字符串
pub fn Rational::to_string(self : Rational) -> String {
  "\{self.numerator}/\{self.denominator}"
}

// ============================================================
// 时值单位 DurUnit
// ============================================================

///|
/// 时值单位：全音符到 128 分音符
pub(all) enum DurUnit {
  DurWhole
  DurHalf
  DurQuarter
  DurEighth
  DurSixteenth
  ThirtySecond
  SixtyFourth
  OneTwentyEighth
}

///|
/// DurUnit 转为字符串
pub fn DurUnit::to_string(self : DurUnit) -> String {
  match self {
    DurWhole => "w"
    DurHalf => "h"
    DurQuarter => "q"
    DurEighth => "8"
    DurSixteenth => "16"
    ThirtySecond => "32"
    SixtyFourth => "64"
    OneTwentyEighth => "128"
  }
}

///|
/// 连音比：actual 个音符替代 normal 个正常音符
pub(all) struct TupletRatio {
  actual : Int
  normal : Int
}

///|
/// 节奏时值 = 基本时值单位 + 附点数 + 连音比
pub(all) struct RhythmDuration {
  unit : DurUnit
  dots : Int
  tuplet : TupletRatio?
}

///|
/// 节奏事件种类：音符 / 休止
/// 注：变体名 NoteKind/RestKind 避免与 MusicEvent::Note/Rest 重名
pub(all) enum RhythmicKind {
  NoteKind
  RestKind
}

///|
/// 节奏值 = 时值 + 种类
pub(all) struct RhythmicValue {
  duration : RhythmDuration
  kind : RhythmicKind
}

///|
/// Tick 位置
pub(all) struct TickPosition {
  ticks : Int
}

///|
/// 小节位置 = 小节号 + 小节内拍位置 + 微调偏移
pub(all) struct BarPosition {
  bar : Int
  beat : Rational
  offset : Rational
}

// ============================================================
// 规则表（内部）
// ============================================================

///|
/// 时值单位 → 四分音符为单位的分数
/// 内部规则表，不公开
fn dur_unit_fraction(u : DurUnit) -> Rational {
  match u {
    DurWhole => rational_raw(4, 1)
    DurHalf => rational_raw(2, 1)
    DurQuarter => rational_raw(1, 1)
    DurEighth => rational_raw(1, 2)
    DurSixteenth => rational_raw(1, 4)
    ThirtySecond => rational_raw(1, 8)
    SixtyFourth => rational_raw(1, 16)
    OneTwentyEighth => rational_raw(1, 32)
  }
}

///|
/// 附点倍数：dots=0→1/1, 1→3/2, 2→7/4, 3→15/8
/// 内部规则表，dots 必须为 0-3
fn dot_multiplier(dots : Int) -> Result[Rational, TimeError] {
  if dots < 0 {
    return Err(InvalidDuration("附点数不能为负数：\{dots}"))
  }
  match dots {
    0 => Ok(rational_raw(1, 1))
    1 => Ok(rational_raw(3, 2))
    2 => Ok(rational_raw(7, 4))
    3 => Ok(rational_raw(15, 8))
    _ => Err(InvalidDuration("不支持的附点数：\{dots}，仅支持 0-3"))
  }
}

// ============================================================
// 换算层
// ============================================================

///|
/// RhythmDuration → Rational（四分音符为单位的分数）
pub fn rhythm_duration_to_fraction(d : RhythmDuration) -> Rational {
  let base = dur_unit_fraction(d.unit)
  let dot = match dot_multiplier(d.dots) {
    Ok(r) => r
    Err(_) => rational_raw(1, 1)
  }
  let frac = rational_mul(base, dot)
  match d.tuplet {
    Some(ratio) => {
      let tf = rational_raw(ratio.normal, ratio.actual)
      rational_mul(frac, tf)
    }
    None => frac
  }
}

///|
/// RhythmDuration → tick 数（需 PPQ），结果必须为整数
pub fn rhythm_duration_to_ticks(
  d : RhythmDuration,
  ppq : Int,
) -> Result[Int, TimeError] {
  if ppq <= 0 {
    return Err(InvalidPPQ("PPQ 必须 > 0，当前：\{ppq}"))
  }
  let frac = rhythm_duration_to_fraction(d)
  let ticks_frac = rational_mul(frac, rational_raw(ppq, 1))
  rational_to_int(ticks_frac)
}

///|
/// tick 数 → 四分音符拍数（tick 数 / PPQ）
pub fn ticks_to_quarter_beats(ticks : Int, ppq : Int) -> Rational {
  rational_raw(ticks, ppq)
}

///|
/// 小节长度（tick 数） = 分子 × 4 × PPQ / 分母
pub fn bar_length_ticks(
  sig : TimeSignature,
  ppq : Int,
) -> Result[Int, TimeError] {
  if ppq <= 0 {
    return Err(InvalidPPQ("PPQ 必须 > 0，当前：\{ppq}"))
  }
  if !is_valid_time_signature(sig.numerator, sig.denominator) {
    return Err(
      InvalidTimeSignature("无效拍号：\{sig.numerator}/\{sig.denominator}"),
    )
  }
  let frac = rational_mul(
    rational_raw(sig.numerator * 4, sig.denominator),
    rational_raw(ppq, 1),
  )
  rational_to_int(frac)
}

///|
/// BPM → 微秒/四分音符（MIDI tempo 标准）
pub fn bpm_to_microseconds_per_quarter(bpm : Double) -> Result[Int, TimeError] {
  if bpm <= 0.0 {
    return Err(InvalidTempo("BPM 必须 > 0，当前：\{bpm}"))
  }
  Ok((60000000.0 / bpm).to_int())
}

///|
/// tick 数 → 秒数（需 BPM 和 PPQ）
pub fn ticks_to_seconds(
  ticks : Int,
  bpm : Double,
  ppq : Int,
) -> Result[Double, TimeError] {
  if ppq <= 0 {
    return Err(InvalidPPQ("PPQ 必须 > 0，当前：\{ppq}"))
  }
  if bpm <= 0.0 {
    return Err(InvalidTempo("BPM 必须 > 0，当前：\{bpm}"))
  }
  Ok(ticks.to_double() * 60.0 / (ppq.to_double() * bpm))
}

///|
/// 秒数 → tick 数（floor 截断为整数）
pub fn seconds_to_ticks(seconds : Double, bpm : Double, ppq : Int) -> Int {
  (seconds * bpm * ppq.to_double() / 60.0).to_int()
}

// ============================================================
// 解析层
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
// Position 互转 — BarPosition ↔ tick
// ============================================================

///|
/// 小节位置 → tick 数（单一拍号下）
pub fn position_to_ticks(
  pos : BarPosition,
  sig : TimeSignature,
  ppq : Int,
) -> Result[Int, TimeError] {
  if !is_valid_time_signature(sig.numerator, sig.denominator) {
    return Err(
      InvalidTimeSignature("无效拍号：\{sig.numerator}/\{sig.denominator}"),
    )
  }
  if ppq <= 0 {
    return Err(InvalidPPQ("PPQ 必须 > 0，当前：\{ppq}"))
  }
  let bar_ticks = match bar_length_ticks(sig, ppq) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  // beat_unit = 1 / sig.denominator（以全音符为单位的分数）
  let beat_unit = rational_raw(1, sig.denominator)
  let in_bar = rational_add(pos.beat, pos.offset)
  let in_bar_whole = rational_mul(in_bar, beat_unit)
  // 全音符 = 4 * ppq tick
  let in_bar_ticks_frac = rational_mul(in_bar_whole, rational_raw(4 * ppq, 1))
  match rational_to_int(in_bar_ticks_frac) {
    Ok(ibt) => Ok(pos.bar * bar_ticks + ibt)
    Err(e) => Err(e)
  }
}

///|
/// tick 数 → 小节位置（单一拍号下）
pub fn ticks_to_position(
  ticks : Int,
  sig : TimeSignature,
  ppq : Int,
) -> Result[BarPosition, TimeError] {
  if ticks < 0 {
    return Err(InvalidTick("tick 必须 >= 0，当前：\{ticks}"))
  }
  if !is_valid_time_signature(sig.numerator, sig.denominator) {
    return Err(
      InvalidTimeSignature("无效拍号：\{sig.numerator}/\{sig.denominator}"),
    )
  }
  if ppq <= 0 {
    return Err(InvalidPPQ("PPQ 必须 > 0，当前：\{ppq}"))
  }
  let bar_ticks = match bar_length_ticks(sig, ppq) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let bar = ticks / bar_ticks
  let in_bar_ticks = ticks % bar_ticks
  // 每 beat-unit 的 tick 数 = 4 * ppq / sig.denominator
  let beat_ticks = 4 * ppq / sig.denominator
  let beat = in_bar_ticks / beat_ticks
  let remainder = in_bar_ticks % beat_ticks
  let beat_r = rational_raw(beat, 1)
  let offset = rational_raw(remainder, beat_ticks)
  Ok({ bar, beat: beat_r, offset })
}

// ============================================================
// TimeMap 类型与 API — 多 tempo / 多拍号时间地图
// ============================================================

///|
/// 速度变化点
pub(all) struct TempoChange {
  at_tick : Int
  tempo_bpm : Double
}

///|
/// 拍号变化点
pub(all) struct TimeSigChange {
  at_bar : Int
  sig_num : Int
  sig_den : Int
}

///|
/// 时间地图 = PPQ + 初始拍号/速度 + 变化点列表
pub(all) struct TimeMap {
  ppq : Int
  sig_num : Int
  sig_den : Int
  tempo_bpm : Double
  tempo_changes : Array[TempoChange]
  sig_changes : Array[TimeSigChange]
}

///|
/// 构造 TimeMap，验证 ppq > 0、拍号合法、bpm > 0
pub fn make_time_map(
  ppq : Int,
  sig : TimeSignature,
  bpm : Double,
) -> Result[TimeMap, TimeError] {
  if ppq <= 0 {
    return Err(InvalidPPQ("PPQ 必须 > 0，当前：\{ppq}"))
  }
  if !is_valid_time_signature(sig.numerator, sig.denominator) {
    return Err(
      InvalidTimeSignature("无效拍号：\{sig.numerator}/\{sig.denominator}"),
    )
  }
  if bpm <= 0.0 {
    return Err(InvalidTempo("BPM 必须 > 0，当前：\{bpm}"))
  }
  Ok({
    ppq,
    sig_num: sig.numerator,
    sig_den: sig.denominator,
    tempo_bpm: bpm,
    tempo_changes: [],
    sig_changes: [],
  })
}

///|
/// 查询指定 tick 对应的 BPM（遍历所有变化点取最后匹配的）
pub fn tempo_at_tick(map : TimeMap, tick : Int) -> Double {
  let mut result = map.tempo_bpm
  for i = 0; i < map.tempo_changes.length(); i = i + 1 {
    if map.tempo_changes[i].at_tick <= tick {
      result = map.tempo_changes[i].tempo_bpm
    }
  }
  result
}

///|
/// 查询指定 bar 对应的拍号 (num, den)
pub fn signature_at_bar(map : TimeMap, bar : Int) -> (Int, Int) {
  let mut num = map.sig_num
  let mut den = map.sig_den
  for i = 0; i < map.sig_changes.length(); i = i + 1 {
    if map.sig_changes[i].at_bar <= bar {
      num = map.sig_changes[i].sig_num
      den = map.sig_changes[i].sig_den
    }
  }
  (num, den)
}

///|
/// 向 TimeMap 添加速度变化（保持 at_tick 升序）
pub fn add_tempo_change(map : TimeMap, ch : TempoChange) -> TimeMap {
  let new_changes = insert_sorted_tempo(map.tempo_changes, ch)
  {
    ppq: map.ppq,
    sig_num: map.sig_num,
    sig_den: map.sig_den,
    tempo_bpm: map.tempo_bpm,
    tempo_changes: new_changes,
    sig_changes: map.sig_changes,
  }
}

///|
/// 向 TimeMap 添加拍号变化（保持 at_bar 升序）
pub fn add_sig_change(map : TimeMap, ch : TimeSigChange) -> TimeMap {
  let new_changes = insert_sorted_sig(map.sig_changes, ch)
  {
    ppq: map.ppq,
    sig_num: map.sig_num,
    sig_den: map.sig_den,
    tempo_bpm: map.tempo_bpm,
    tempo_changes: map.tempo_changes,
    sig_changes: new_changes,
  }
}

///|
/// 将 TempoChange 插入已排序数组（内部函数）
fn insert_sorted_tempo(
  changes : Array[TempoChange],
  ch : TempoChange,
) -> Array[TempoChange] {
  let result : Array[TempoChange] = []
  let mut inserted = false
  for i = 0; i < changes.length(); i = i + 1 {
    if !inserted && ch.at_tick < changes[i].at_tick {
      result.push(ch)
      inserted = true
    }
    result.push(changes[i])
  }
  if !inserted {
    result.push(ch)
  }
  result
}

///|
/// 将 TimeSigChange 插入已排序数组（内部函数）
fn insert_sorted_sig(
  changes : Array[TimeSigChange],
  ch : TimeSigChange,
) -> Array[TimeSigChange] {
  let result : Array[TimeSigChange] = []
  let mut inserted = false
  for i = 0; i < changes.length(); i = i + 1 {
    if !inserted && ch.at_bar < changes[i].at_bar {
      result.push(ch)
      inserted = true
    }
    result.push(changes[i])
  }
  if !inserted {
    result.push(ch)
  }
  result
}

///|
/// 排序 TempoChange 列表（按 at_tick 升序）
fn sort_tempo_changes(changes : Array[TempoChange]) -> Array[TempoChange] {
  let len = changes.length()
  if len <= 1 {
    return changes
  }
  let arr : Array[TempoChange] = []
  for i = 0; i < len; i = i + 1 {
    arr.push(changes[i])
  }
  // 冒泡排序
  for i = 0; i < len; i = i + 1 {
    for j = 0; j < len - i - 1; j = j + 1 {
      if arr[j].at_tick > arr[j + 1].at_tick {
        let tmp = arr[j]
        arr[j] = arr[j + 1]
        arr[j + 1] = tmp
      }
    }
  }
  arr
}

///|
/// 多 tempo 分段累加：从 tick=0 到 target 的秒数
pub fn ticks_to_seconds_timemap(
  target : Int,
  map : TimeMap,
) -> Result[Double, TimeError] {
  if target < 0 {
    return Err(InvalidTick("tick 必须 >= 0，当前：\{target}"))
  }
  if map.ppq <= 0 {
    return Err(InvalidPPQ("PPQ 必须 > 0，当前：\{map.ppq}"))
  }
  let changes = sort_tempo_changes(map.tempo_changes)
  let mut current_tick : Int = 0
  let mut current_bpm = map.tempo_bpm
  let mut seconds = 0.0
  let mut idx = 0
  while current_tick < target {
    let next_change_tick = if idx < changes.length() {
      changes[idx].at_tick
    } else {
      target
    }
    let seg_end = if next_change_tick < target {
      next_change_tick
    } else {
      target
    }
    let delta = seg_end - current_tick
    let seg_seconds = delta.to_double() *
      60.0 /
      (map.ppq.to_double() * current_bpm)
    seconds = seconds + seg_seconds
    current_tick = seg_end
    if idx < changes.length() && current_tick == changes[idx].at_tick {
      current_bpm = changes[idx].tempo_bpm
      idx = idx + 1
    }
  }
  Ok(seconds)
}

// ============================================================
// FFI JSON — 面向 JS/WASM 的字符串包装
// ============================================================

///|
/// FFI 解析拍号：入 "4/4" → {"ok":true,"num":4,"den":4}
pub fn ffi_parse_time_sig(input : String) -> String {
  match parse_time_sig(input) {
    Ok(sig) =>
      "{\"ok\":true,\"num\":\{sig.numerator},\"den\":\{sig.denominator}}"
    Err(e) => "{\"ok\":false,\"error\":\"\{e.to_string()}\"}"
  }
}

///|
/// FFI 时值转 tick：入 "q",480 → {"ok":true,"ticks":480}
pub fn ffi_duration_ticks(input : String, ppq : Int) -> String {
  match parse_dur_unit(input) {
    Ok(dur) =>
      match rhythm_duration_to_ticks(dur, ppq) {
        Ok(ticks) => "{\"ok\":true,\"ticks\":\{ticks}}"
        Err(e) => "{\"ok\":false,\"error\":\"\{e.to_string()}\"}"
      }
    Err(e) => "{\"ok\":false,\"error\":\"\{e.to_string()}\"}"
  }
}

///|
/// FFI 解析 BPM：入 "120bpm" → {"ok":true,"bpm":120.0}
pub fn ffi_parse_tempo(input : String) -> String {
  match parse_tempo(input) {
    Ok(bpm) => "{\"ok\":true,\"bpm\":\{bpm}}"
    Err(e) => "{\"ok\":false,\"error\":\"\{e.to_string()}\"}"
  }
}

///|
/// FFI tick→秒：入 480,120.0,480 → {"ok":true,"seconds":0.5}
pub fn ffi_ticks_to_seconds(ticks : Int, bpm : Double, ppq : Int) -> String {
  match ticks_to_seconds(ticks, bpm, ppq) {
    Ok(sec) => "{\"ok\":true,\"seconds\":\{sec}}"
    Err(e) => "{\"ok\":false,\"error\":\"\{e.to_string()}\"}"
  }
}

///|
/// FFI 小节长度：入 "4/4",480 → {"ok":true,"ticks":1920}
pub fn ffi_bar_length(sig : String, ppq : Int) -> String {
  match parse_time_sig(sig) {
    Ok(parsed) =>
      match bar_length_ticks(parsed, ppq) {
        Ok(ticks) => "{\"ok\":true,\"ticks\":\{ticks}}"
        Err(e) => "{\"ok\":false,\"error\":\"\{e.to_string()}\"}"
      }
    Err(e) => "{\"ok\":false,\"error\":\"\{e.to_string()}\"}"
  }
}
