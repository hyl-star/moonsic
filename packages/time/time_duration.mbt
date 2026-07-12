//
// 时值单位、节奏时值、换算
//

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
/// 创建 RhythmDuration
pub fn rhythm_duration(
  unit : DurUnit,
  dots : Int,
  tuplet : TupletRatio?,
) -> RhythmDuration {
  { unit, dots, tuplet }
}

///|
/// 节奏事件种类：音符 / 休止
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

// ============================================================
// 规则表（内部）
// ============================================================

///|
/// 时值单位 → 四分音符为单位的分数
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
/// @deprecated Use rhythm_duration_to_fraction_checked instead.
/// RhythmDuration → Rational（四分音符为单位的分数）。非法输入时 abort。
pub fn rhythm_duration_to_fraction(d : RhythmDuration) -> Rational {
  match rhythm_duration_to_fraction_checked(d) {
    Ok(frac) => frac
    Err(e) => abort(e.to_string())
  }
}

///|
/// RhythmDuration → Rational with structured validation.
pub fn rhythm_duration_to_fraction_checked(
  d : RhythmDuration,
) -> Result[Rational, TimeError] {
  let base = dur_unit_fraction(d.unit)
  let dot = match dot_multiplier(d.dots) {
    Ok(r) => r
    Err(e) => return Err(e)
  }
  let frac = rational_mul(base, dot)
  match d.tuplet {
    Some(ratio) => {
      if ratio.actual <= 0 || ratio.normal <= 0 {
        return Err(
          InvalidDuration(
            "tuplet ratio must be positive: \{ratio.actual}:\{ratio.normal}",
          ),
        )
      }
      let tf = rational_raw(ratio.normal, ratio.actual)
      Ok(rational_mul(frac, tf))
    }
    None => Ok(frac)
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
  let frac = match rhythm_duration_to_fraction_checked(d) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
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

///|
/// 秒数 → tick 数（checked，验证 ppq/bpm/seconds 合法性）
pub fn seconds_to_ticks_checked(
  seconds : Double,
  bpm : Double,
  ppq : Int,
) -> Result[Int, TimeError] {
  if ppq <= 0 {
    return Err(InvalidPPQ("PPQ 必须 > 0，当前：\{ppq}"))
  }
  if bpm <= 0.0 {
    return Err(InvalidTempo("BPM 必须 > 0，当前：\{bpm}"))
  }
  if seconds < 0.0 {
    return Err(InvalidTick("秒数不能为负数：\{seconds}"))
  }
  Ok((seconds * bpm * ppq.to_double() / 60.0).to_int())
}
