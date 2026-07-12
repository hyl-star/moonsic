//
// 节奏模式 — join, repeat, fit_to_bars
//

// --- PatternJoinMode ---

///|
pub(all) enum PatternJoinMode {
  Sequential
  Overlay
  CallResponse
  Loop
  Interleave
}

// --- PatternFillMode ---

///|
pub(all) enum PatternFillMode {
  Strict
  PadRest
  Truncate
  RepeatToFit
  StretchLast
}

// --- PhrasePattern ---

///|
/// 短句模式 = 有序节奏单元序列 + 总拍数
pub(all) struct PhrasePattern {
  cells : Array[RhythmCell]
  total_beats : Double
}

///|
fn phrase_from_cells(cells : Array[RhythmCell]) -> PhrasePattern {
  { cells, total_beats: calc_cells_beats(cells) }
}

// ============================================================
// 重复
// ============================================================

///|
pub fn repeat_pattern_checked(
  pattern : RhythmPattern,
  count : Int,
) -> Result[PhrasePattern, RhythmError] {
  if count <= 0 {
    return Err(InvalidRepeatCount("重复次数必须 > 0，当前：\{count}"))
  }
  if pattern.cells.length() == 0 {
    return Err(EmptyRhythmPattern("pattern cells 为空"))
  }
  let cells : Array[RhythmCell] = []
  for i = 0; i < count; i = i + 1 {
    for c in pattern.cells {
      cells.push(c)
    }
  }
  Ok(phrase_from_cells(cells))
}

// ============================================================
// 拼接
// ============================================================

///|
pub fn join_patterns_checked(
  patterns : Array[PhrasePattern],
  mode : PatternJoinMode,
) -> Result[PhrasePattern, RhythmError] {
  if patterns.length() == 0 {
    return Err(InvalidPatternLength("patterns 数组为空"))
  }
  match mode {
    Sequential | Loop | CallResponse => {
      let cells : Array[RhythmCell] = []
      for p in patterns {
        for c in p.cells {
          cells.push(c)
        }
      }
      Ok(phrase_from_cells(cells))
    }
    Overlay => {
      let cells : Array[RhythmCell] = []
      let mut max_beats = 0.0
      for p in patterns {
        for c in p.cells {
          cells.push(c)
        }
        if p.total_beats > max_beats {
          max_beats = p.total_beats
        }
      }
      Ok({ cells, total_beats: max_beats })
    }
    Interleave => {
      if patterns.length() == 0 {
        return Err(InvalidPatternLength("无可交织的 pattern"))
      }
      let mut max_len = 0
      for p in patterns {
        if p.cells.length() > max_len {
          max_len = p.cells.length()
        }
      }
      let interleaved : Array[RhythmCell] = []
      for i = 0; i < max_len; i = i + 1 {
        for p in patterns {
          if i < p.cells.length() {
            interleaved.push(p.cells[i])
          }
        }
      }
      Ok(phrase_from_cells(interleaved))
    }
  }
}

// ============================================================
// 小节适配
// ============================================================

///|
pub fn fit_pattern_to_bars_checked(
  pattern : PhrasePattern,
  sig : @time.TimeSignature,
  bars : Int,
  fill : PatternFillMode,
) -> Result[PhrasePattern, RhythmError] {
  let target_beats = sig.measure_beats() * bars.to_double()
  let current_beats = pattern.total_beats
  match fill {
    Strict => {
      if (current_beats - target_beats).abs() > 0.0001 {
        return Err(
          PatternDoesNotFit(
            "当前拍数(\{current_beats})与目标拍数(\{target_beats})不匹配（Strict 模式）",
          ),
        )
      }
      Ok(pattern)
    }
    PadRest => {
      if current_beats > target_beats + 0.0001 {
        return Err(
          PatternDoesNotFit(
            "当前拍数超出目标拍数（PadRest 模式只补不删）",
          ),
        )
      }
      let diff = target_beats - current_beats
      if diff <= 0.0001 {
        return Ok(pattern)
      }
      // 补休止：创建一个近似时值的休止 cell
      let rest_dur = approx_duration(diff)
      let cells : Array[RhythmCell] = []
      for c in pattern.cells {
        cells.push(c)
      }
      cells.push(r_cell(rest_dur))
      Ok(phrase_from_cells(cells))
    }
    Truncate => {
      if current_beats <= target_beats + 0.0001 {
        return Ok(pattern)
      }
      let cells : Array[RhythmCell] = []
      let mut acc = 0.0
      for c in pattern.cells {
        let beat = @time.rational_to_double(
          @time.rhythm_duration_to_fraction(c.duration),
        )
        if acc + beat <= target_beats + 0.0001 {
          cells.push(c)
          acc = acc + beat
        }
      }
      Ok(phrase_from_cells(cells))
    }
    RepeatToFit => {
      if current_beats <= 0.0 {
        return Err(
          PatternDoesNotFit("当前 pattern 拍数为 0，无法 RepeatToFit"),
        )
      }
      let cells : Array[RhythmCell] = []
      let mut acc = 0.0
      while acc + 0.0001 < target_beats {
        for c in pattern.cells {
          let beat = @time.rational_to_double(
            @time.rhythm_duration_to_fraction(c.duration),
          )
          if acc + beat <= target_beats + 0.0001 {
            cells.push(c)
            acc = acc + beat
          } else {
            break
          }
        }
      }
      Ok(phrase_from_cells(cells))
    }
    StretchLast => {
      if current_beats > target_beats + 0.0001 {
        return Err(
          PatternDoesNotFit(
            "当前拍数超出目标拍数（StretchLast 模式不支持超出）",
          ),
        )
      }
      let n = pattern.cells.length()
      if n == 0 {
        return Err(PatternDoesNotFit("无事件可拉伸"))
      }
      if (current_beats - target_beats).abs() <= 0.0001 {
        return Ok(pattern)
      }
      let prev_beats = current_beats -
        @time.rational_to_double(
          @time.rhythm_duration_to_fraction(pattern.cells[n - 1].duration),
        )
      let needed = target_beats - prev_beats
      let cells : Array[RhythmCell] = []
      for i = 0; i < n - 1; i = i + 1 {
        cells.push(pattern.cells[i])
      }
      let last = pattern.cells[n - 1]
      cells.push({
        duration: approx_duration(needed),
        is_rest: last.is_rest,
        accent: last.accent,
        tie_to_next: last.tie_to_next,
      })
      Ok(phrase_from_cells(cells))
    }
  }
}

///|
/// 根据拍数近似创建 RhythmDuration（粗糙近似，用于填补空白）
fn approx_duration(beats : Double) -> @time.RhythmDuration {
  if beats >= 3.9 {
    { unit: @time.DurWhole, dots: 0, tuplet: None }
  } else if beats >= 1.9 {
    { unit: @time.DurHalf, dots: 0, tuplet: None }
  } else if beats >= 0.95 {
    { unit: @time.DurQuarter, dots: 0, tuplet: None }
  } else if beats >= 0.45 {
    { unit: @time.DurEighth, dots: 0, tuplet: None }
  } else {
    { unit: @time.DurSixteenth, dots: 0, tuplet: None }
  }
}
