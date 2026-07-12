//
// Position 类型与互转 — BarPosition ↔ tick
//

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
  let beat_unit = rational_raw(1, sig.denominator)
  let in_bar = rational_add(pos.beat, pos.offset)
  let in_bar_whole = rational_mul(in_bar, beat_unit)
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
  let beat_ticks = 4 * ppq / sig.denominator
  let beat = in_bar_ticks / beat_ticks
  let remainder = in_bar_ticks % beat_ticks
  let beat_r = rational_raw(beat, 1)
  let offset = rational_raw(remainder, beat_ticks)
  Ok({ bar, beat: beat_r, offset })
}
