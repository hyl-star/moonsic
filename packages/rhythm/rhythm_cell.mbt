//
// 节奏单元 — RhythmCell, AccentStrength, RhythmPattern, 内置模板
//

// --- AccentStrength ---

///|
pub(all) enum AccentStrength {
  NoAccent
  Weak
  Medium
  Strong
  Marcato
}

///|
pub fn AccentStrength::velocity_multiplier(self : AccentStrength) -> Double {
  match self {
    NoAccent => 1.0
    Weak => 0.85
    Medium => 1.0
    Strong => 1.15
    Marcato => 1.3
  }
}

// --- RhythmCell ---

///|
/// 节奏单元：时值 + 是否休止 + 重音 + 连音线
pub(all) struct RhythmCell {
  duration : @time.RhythmDuration
  is_rest : Bool
  accent : AccentStrength
  tie_to_next : Bool
}

///|
pub fn rhythm_cell(
  duration : @time.RhythmDuration,
  is_rest : Bool,
  accent : AccentStrength,
  tie_to_next : Bool,
) -> RhythmCell {
  { duration, is_rest, accent, tie_to_next }
}

///|
fn default_cell(duration : @time.RhythmDuration, is_rest : Bool) -> RhythmCell {
  { duration, is_rest, accent: NoAccent, tie_to_next: false }
}

///|
/// 计算 RhythmCell 数组的总拍数
fn calc_cells_beats(cells : Array[RhythmCell]) -> Double {
  let mut total = 0.0
  for c in cells {
    let frac = @time.rhythm_duration_to_fraction(c.duration)
    total = total + @time.rational_to_double(frac)
  }
  total
}

///|
/// 快捷构造：创建四分音符 cell
fn q_cell() -> RhythmCell {
  default_cell({ unit: @time.DurQuarter, dots: 0, tuplet: None }, false)
}

///|
/// 快捷构造：创建二分音符 cell
fn h_cell() -> RhythmCell {
  default_cell({ unit: @time.DurHalf, dots: 0, tuplet: None }, false)
}

///|
/// 快捷构造：创建全音符 cell
fn w_cell() -> RhythmCell {
  default_cell({ unit: @time.DurWhole, dots: 0, tuplet: None }, false)
}

///|
/// 快捷构造：创建八分音符 cell
fn e_cell() -> RhythmCell {
  default_cell({ unit: @time.DurEighth, dots: 0, tuplet: None }, false)
}

///|
/// 快捷构造：创建休止 cell
fn r_cell(d : @time.RhythmDuration) -> RhythmCell {
  default_cell(d, true)
}

// --- RhythmPattern ---

///|
/// 节奏模板 = 有序节奏单元序列 + 总拍数
pub(all) struct RhythmPattern {
  cells : Array[RhythmCell]
  total_beats : Double
}

///|
pub fn rhythm_pattern_checked(
  cells : Array[RhythmCell],
) -> Result[RhythmPattern, RhythmError] {
  if cells.length() == 0 {
    return Err(EmptyRhythmPattern("cells 数组为空"))
  }
  let total = calc_cells_beats(cells)
  Ok({ cells, total_beats: total })
}

///|
pub fn rhythm_pattern(cells : Array[RhythmCell]) -> RhythmPattern {
  match rhythm_pattern_checked(cells) {
    Ok(p) => p
    Err(_) => {
      let fallback = [q_cell()]
      { cells: fallback, total_beats: 1.0 }
    }
  }
}

// --- RhythmTemplateKind ---

///|
pub(all) enum RhythmTemplateKind {
  FourQuarters
  TwoHalves
  WholePad
  EighthFlow
  Syncopated
  LongShort
  ShortShortLong
  Waltz
  Tresillo
  RestLead
}

///|
pub fn rhythm_template(kind : RhythmTemplateKind) -> RhythmPattern {
  let cells = match kind {
    FourQuarters => [q_cell(), q_cell(), q_cell(), q_cell()]
    TwoHalves => [h_cell(), h_cell()]
    WholePad => [w_cell()]
    EighthFlow =>
      [
        e_cell(),
        e_cell(),
        e_cell(),
        e_cell(),
        e_cell(),
        e_cell(),
        e_cell(),
        e_cell(),
      ]
    Syncopated => [e_cell(), q_cell(), e_cell(), q_cell(), q_cell()]
    LongShort => [h_cell(), q_cell(), q_cell()]
    ShortShortLong => [q_cell(), q_cell(), h_cell()]
    Waltz => [q_cell(), q_cell(), q_cell()]
    Tresillo =>
      [
        default_cell({ unit: @time.DurQuarter, dots: 1, tuplet: None }, false),
        default_cell({ unit: @time.DurQuarter, dots: 1, tuplet: None }, false),
        q_cell(),
      ]
    RestLead =>
      [
        r_cell({ unit: @time.DurEighth, dots: 0, tuplet: None }),
        e_cell(),
        q_cell(),
        h_cell(),
      ]
  }
  { cells, total_beats: calc_cells_beats(cells) }
}
