//
// 节奏短句 — PhrasePattern、拼接、小节适配
//

// ============================================================
// 核心枚举类型
// ============================================================

///|
/// Pattern 拼接模式
pub(all) enum PatternJoinMode {
  Sequential // 前后顺序拼接
  Overlay // 同时开始，合并事件
  CallResponse // A 后接 B
  Loop // 拼接后标记为可循环
  Interleave // 按 motif 交替取事件
}

///|
/// 小节适配模式
pub(all) enum PatternFillMode {
  Strict // 长度不匹配则报错
  PadRest // 不足时补休止，超出报错
  Truncate // 超出时截断，不足不处理
  RepeatToFit // 重复 pattern 适配，超出截断
  StretchLast // 拉长最后一个 cell，超出报错
}

// ============================================================
// 核心数据结构
// ============================================================

///|
/// 短句模式 = 多个动机 + 展开事件 + 总拍数
pub(all) struct PhrasePattern {
  motifs : Array[Motif]
  events : Array[MotifEvent]
  total_beats : Double
}

// ============================================================
// 重复与拼接 API
// ============================================================

///|
/// 重复动机生成短句 pattern（checked）
pub fn repeat_motif_checked(
  motif : Motif,
  count : Int,
) -> Result[PhrasePattern, MotifError] {
  if count <= 0 {
    return Err(InvalidRepeatCount("重复次数必须 > 0，当前：\{count}"))
  }
  if motif.events.length() == 0 {
    return Err(InvalidMotif("动机事件为空"))
  }
  let motifs : Array[Motif] = []
  let all_events : Array[MotifEvent] = []
  for i = 0; i < count; i = i + 1 {
    motifs.push(motif)
    for e in motif.events {
      all_events.push(e)
    }
  }
  let total = calc_events_beats(all_events)
  Ok({ motifs, events: all_events, total_beats: total })
}

///|
/// 便捷 API：count <= 0 时 fallback 到 count=1
pub fn repeat_motif(motif : Motif, count : Int) -> PhrasePattern {
  let safe_count = if count <= 0 { 1 } else { count }
  match repeat_motif_checked(motif, safe_count) {
    Ok(p) => p
    Err(_) =>
      { motifs: [motif], events: motif.events, total_beats: motif.total_beats }
  }
}

///|
/// 拼接多个 pattern（checked）
pub fn join_patterns_checked(
  patterns : Array[PhrasePattern],
  mode : PatternJoinMode,
) -> Result[PhrasePattern, MotifError] {
  if patterns.length() == 0 {
    return Err(InvalidPatternLength("patterns 数组为空"))
  }
  match mode {
    Sequential => {
      let all_motifs : Array[Motif] = []
      let all_events : Array[MotifEvent] = []
      for p in patterns {
        for m in p.motifs {
          all_motifs.push(m)
        }
        for e in p.events {
          all_events.push(e)
        }
      }
      let total = calc_events_beats(all_events)
      Ok({ motifs: all_motifs, events: all_events, total_beats: total })
    }
    Overlay => {
      // 同时开始，合并所有 motifs 和 events，总拍数取最大值
      let all_motifs : Array[Motif] = []
      let all_events : Array[MotifEvent] = []
      let mut max_beats = 0.0
      for p in patterns {
        for m in p.motifs {
          all_motifs.push(m)
        }
        for e in p.events {
          all_events.push(e)
        }
        if p.total_beats > max_beats {
          max_beats = p.total_beats
        }
      }
      Ok({ motifs: all_motifs, events: all_events, total_beats: max_beats })
    }
    CallResponse => {
      if patterns.length() < 2 {
        return Err(
          InvalidPatternLength("CallResponse 至少需要 2 个 pattern"),
        )
      }
      // 顺序拼接，保留标记
      let all_motifs : Array[Motif] = []
      let all_events : Array[MotifEvent] = []
      for p in patterns {
        for m in p.motifs {
          all_motifs.push(m)
        }
        for e in p.events {
          all_events.push(e)
        }
      }
      let total = calc_events_beats(all_events)
      Ok({ motifs: all_motifs, events: all_events, total_beats: total })
    }
    Loop => {
      let all_motifs : Array[Motif] = []
      let all_events : Array[MotifEvent] = []
      for p in patterns {
        for m in p.motifs {
          all_motifs.push(m)
        }
        for e in p.events {
          all_events.push(e)
        }
      }
      let total = calc_events_beats(all_events)
      Ok({ motifs: all_motifs, events: all_events, total_beats: total })
    }
    Interleave => {
      // 收集所有 motifs
      let all_motifs_list : Array[Motif] = []
      for p in patterns {
        for m in p.motifs {
          all_motifs_list.push(m)
        }
      }
      if all_motifs_list.length() == 0 {
        return Err(InvalidPatternLength("无可交织的 motif"))
      }
      // 找最长 motif
      let mut max_len = 0
      for m in all_motifs_list {
        if m.events.length() > max_len {
          max_len = m.events.length()
        }
      }
      // 按列交织
      let interleaved_events : Array[MotifEvent] = []
      for i = 0; i < max_len; i = i + 1 {
        for m in all_motifs_list {
          if i < m.events.length() {
            interleaved_events.push(m.events[i])
          }
        }
      }
      let total = calc_events_beats(interleaved_events)
      Ok({
        motifs: all_motifs_list,
        events: interleaved_events,
        total_beats: total,
      })
    }
  }
}

// ============================================================
// 小节适配 API
// ============================================================

///|
/// 将 pattern 适配到指定小节长度
pub fn fit_pattern_to_bars_checked(
  pattern : PhrasePattern,
  sig : TimeSignature,
  bars : Int,
  fill : PatternFillMode,
) -> Result[PhrasePattern, MotifError] {
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
            "当前拍数(\{current_beats})超出目标拍数(\{target_beats})（PadRest 模式只补不删）",
          ),
        )
      }
      let diff = target_beats - current_beats
      if diff <= 0.0001 {
        return Ok(pattern)
      }
      let rest_dur = duration_from_beats(diff)
      let rest_cell = default_cell(rest_dur, true)
      let rest_event = { degree: 0, cell: rest_cell }
      let new_events : Array[MotifEvent] = []
      for e in pattern.events {
        new_events.push(e)
      }
      new_events.push(rest_event)
      Ok({
        motifs: pattern.motifs,
        events: new_events,
        total_beats: calc_events_beats(new_events),
      })
    }
    Truncate => {
      if current_beats <= target_beats + 0.0001 {
        return Ok(pattern)
      }
      let new_events : Array[MotifEvent] = []
      let mut acc = 0.0
      for e in pattern.events {
        let beat = e.cell.duration.beats()
        if acc + beat <= target_beats + 0.0001 {
          new_events.push(e)
          acc = acc + beat
        }
      }
      Ok({
        motifs: pattern.motifs,
        events: new_events,
        total_beats: calc_events_beats(new_events),
      })
    }
    RepeatToFit => {
      if current_beats <= 0.0 {
        return Err(
          PatternDoesNotFit("当前 pattern 拍数为 0，无法 RepeatToFit"),
        )
      }
      let new_events : Array[MotifEvent] = []
      let mut acc = 0.0
      while acc + 0.0001 < target_beats {
        for e in pattern.events {
          let beat = e.cell.duration.beats()
          if acc + beat <= target_beats + 0.0001 {
            new_events.push(e)
            acc = acc + beat
          } else {
            break
          }
        }
      }
      Ok({
        motifs: pattern.motifs,
        events: new_events,
        total_beats: calc_events_beats(new_events),
      })
    }
    StretchLast => {
      if current_beats > target_beats + 0.0001 {
        return Err(
          PatternDoesNotFit(
            "当前拍数(\{current_beats})超出目标拍数(\{target_beats})（StretchLast 模式不支持超出）",
          ),
        )
      }
      let n = pattern.events.length()
      if n == 0 {
        return Err(PatternDoesNotFit("无事件可拉伸"))
      }
      if (current_beats - target_beats).abs() <= 0.0001 {
        return Ok(pattern)
      }
      // 拉长最后一个 cell 至填满目标
      let prev_beats = current_beats -
        pattern.events[n - 1].cell.duration.beats()
      let needed = target_beats - prev_beats
      let last_dur = duration_from_beats(needed)
      let new_events : Array[MotifEvent] = []
      for i = 0; i < n - 1; i = i + 1 {
        new_events.push(pattern.events[i])
      }
      let last = pattern.events[n - 1]
      new_events.push({
        degree: last.degree,
        cell: {
          duration: last_dur,
          is_rest: last.cell.is_rest,
          accent: last.cell.accent,
          tie_to_next: last.cell.tie_to_next,
        },
      })
      Ok({
        motifs: pattern.motifs,
        events: new_events,
        total_beats: calc_events_beats(new_events),
      })
    }
  }
}
