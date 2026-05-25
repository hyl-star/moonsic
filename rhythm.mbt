//
// 节奏模板与动机模块
// 表达、解析、变换和拼接节奏模板与旋律动机
//

// ============================================================
// 错误类型 MotifError
// ============================================================

///|
/// 节奏模板与动机模块的统一错误类型
pub(all) enum MotifError {
  EmptyRhythmPattern(String)
  InvalidRhythmCell(String)
  InvalidMotif(String)
  InvalidPatternLength(String)
  InvalidRepeatCount(String)
  InvalidTransform(String)
  PatternDoesNotFit(String)
  MotifParseError(String)
  MotifUnsupported(String)
}

///|
/// 转为可读的错误消息（中文）
pub fn MotifError::to_string(self : MotifError) -> String {
  match self {
    EmptyRhythmPattern(msg) => "空节奏模板：\{msg}"
    InvalidRhythmCell(msg) => "无效节奏单元：\{msg}"
    InvalidMotif(msg) => "无效动机：\{msg}"
    InvalidPatternLength(msg) => "无效模式长度：\{msg}"
    InvalidRepeatCount(msg) => "无效重复次数：\{msg}"
    InvalidTransform(msg) => "无效变换：\{msg}"
    PatternDoesNotFit(msg) => "模式不适配：\{msg}"
    MotifParseError(msg) => "动机解析错误：\{msg}"
    MotifUnsupported(msg) => "不支持：\{msg}"
  }
}

// ============================================================
// 核心枚举类型
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

///|
/// 动机变换操作
pub(all) enum MotifTransform {
  TransposeDegrees(Int) // 所有 degree 加 n
  InvertAround(Int) // degree = 2*axis - degree
  Retrograde // 反转事件序列
  Augment // 所有时值 × 2
  Diminish // 所有时值 × 1/2
  Rotate(Int) // 循环移动 n 位
  Repeat(Int) // 重复 n 次（n=1 不重复，n=2 两倍）
  KeepRhythmChangeDegrees(Array[Int]) // 节奏不变，替换 degrees
  KeepDegreesChangeRhythm(RhythmPattern) // degrees 不变，替换节奏
}

///|
/// 动机变奏策略（复合变换序列）
pub(all) enum MotifVariationStrategy {
  ExactRepeat // [Repeat(2)]
  SequenceUp // [TransposeDegrees(1)]
  SequenceDown // [TransposeDegrees(-1)]
  Inversion // [InvertAround(first_degree)]
  RetrogradeVariation // [Retrograde]
  RhythmicAugmentation // [Augment]
  RhythmicDiminution // [Diminish]
  CallResponse // [Repeat(2), TransposeDegrees(2)]
}

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

///|
/// 动机事件 = 音级度数 + 节奏单元
pub(all) struct MotifEvent {
  degree : Int
  cell : RhythmCell
}

///|
/// 动机 = 有序动机事件序列 + 总拍数
pub(all) struct Motif {
  events : Array[MotifEvent]
  total_beats : Double
}

///|
/// 短句模式 = 多个动机 + 展开事件 + 总拍数
pub(all) struct PhrasePattern {
  motifs : Array[Motif]
  events : Array[MotifEvent]
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
/// 计算 MotifEvent 数组的总拍数
fn calc_events_beats(events : Array[MotifEvent]) -> Double {
  let mut total = 0.0
  for e in events {
    total = total + e.cell.duration.beats()
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
// 动机 API
// ============================================================

///|
/// 根据 scale degree 与节奏模板构建旋律动机
/// degree 数量必须与 rhythm cell 数量相等，否则返回错误
pub fn motif_checked(
  degrees : Array[Int],
  rhythm : RhythmPattern,
) -> Result[Motif, MotifError] {
  if degrees.length() == 0 {
    return Err(InvalidMotif("degree 序列为空"))
  }
  if rhythm.cells.length() == 0 {
    return Err(InvalidMotif("节奏模板为空"))
  }
  if degrees.length() != rhythm.cells.length() {
    return Err(
      InvalidMotif(
        "degree 数量(\{degrees.length()})与 rhythm cell 数量(\{rhythm.cells.length()})不匹配",
      ),
    )
  }
  let events : Array[MotifEvent] = []
  for i = 0; i < degrees.length(); i = i + 1 {
    events.push({ degree: degrees[i], cell: rhythm.cells[i] })
  }
  let total = calc_events_beats(events)
  Ok({ events, total_beats: total })
}

///|
/// 便捷 API：degree 与 rhythm 数量不匹配时截断到较短者
pub fn motif(degrees : Array[Int], rhythm : RhythmPattern) -> Motif {
  match motif_checked(degrees, rhythm) {
    Ok(m) => m
    Err(_) => {
      let min_len = if degrees.length() < rhythm.cells.length() {
        degrees.length()
      } else {
        rhythm.cells.length()
      }
      let events : Array[MotifEvent] = []
      for i = 0; i < min_len; i = i + 1 {
        events.push({ degree: degrees[i], cell: rhythm.cells[i] })
      }
      let total = calc_events_beats(events)
      { events, total_beats: total }
    }
  }
}

// ============================================================
// 动机变换 API
// ============================================================

///|
/// 执行单个动机变换（checked）
pub fn transform_motif_checked(
  motif : Motif,
  transform : MotifTransform,
) -> Result[Motif, MotifError] {
  if motif.events.length() == 0 {
    return Err(InvalidMotif("动机事件为空"))
  }
  match transform {
    TransposeDegrees(n) => {
      let new_events : Array[MotifEvent] = []
      for e in motif.events {
        new_events.push({ degree: e.degree + n, cell: e.cell })
      }
      Ok({ events: new_events, total_beats: motif.total_beats })
    }
    InvertAround(axis) => {
      let new_events : Array[MotifEvent] = []
      for e in motif.events {
        let new_degree = 2 * axis - e.degree
        new_events.push({ degree: new_degree, cell: e.cell })
      }
      Ok({ events: new_events, total_beats: motif.total_beats })
    }
    Retrograde => {
      let new_events : Array[MotifEvent] = []
      let n = motif.events.length()
      for i = 0; i < n; i = i + 1 {
        new_events.push(motif.events[n - 1 - i])
      }
      Ok({ events: new_events, total_beats: motif.total_beats })
    }
    Augment => {
      let new_events : Array[MotifEvent] = []
      for e in motif.events {
        let new_dur = e.cell.duration.stretch(2.0)
        let new_cell = {
          duration: new_dur,
          is_rest: e.cell.is_rest,
          accent: e.cell.accent,
          tie_to_next: e.cell.tie_to_next,
        }
        new_events.push({ degree: e.degree, cell: new_cell })
      }
      let total = calc_events_beats(new_events)
      Ok({ events: new_events, total_beats: total })
    }
    Diminish => {
      let new_events : Array[MotifEvent] = []
      for e in motif.events {
        let new_dur = e.cell.duration.stretch(0.5)
        let new_cell = {
          duration: new_dur,
          is_rest: e.cell.is_rest,
          accent: e.cell.accent,
          tie_to_next: e.cell.tie_to_next,
        }
        new_events.push({ degree: e.degree, cell: new_cell })
      }
      let total = calc_events_beats(new_events)
      Ok({ events: new_events, total_beats: total })
    }
    Rotate(n) => {
      let len = motif.events.length()
      if len == 0 {
        return Err(InvalidTransform("不能旋转空的动机"))
      }
      // 处理负数：归一化到 0..len-1
      let shift = (n % len + len) % len
      let new_events : Array[MotifEvent] = []
      for i = 0; i < len; i = i + 1 {
        let src_idx = (i + shift) % len
        new_events.push(motif.events[src_idx])
      }
      Ok({ events: new_events, total_beats: motif.total_beats })
    }
    Repeat(n) => {
      // Repeat(n)：输出包含 n 份原动机（n 为总份数）
      if n <= 0 {
        return Err(InvalidRepeatCount("重复次数必须 > 0，当前：\{n}"))
      }
      let new_events : Array[MotifEvent] = []
      for r = 0; r < n; r = r + 1 {
        for e in motif.events {
          new_events.push(e)
        }
      }
      let total = calc_events_beats(new_events)
      Ok({ events: new_events, total_beats: total })
    }
    KeepRhythmChangeDegrees(degrees) => {
      if degrees.length() != motif.events.length() {
        return Err(
          InvalidTransform(
            "degree 数量(\{degrees.length()})与原动机事件数(\{motif.events.length()})不匹配",
          ),
        )
      }
      let new_events : Array[MotifEvent] = []
      for i = 0; i < motif.events.length(); i = i + 1 {
        new_events.push({ degree: degrees[i], cell: motif.events[i].cell })
      }
      Ok({ events: new_events, total_beats: motif.total_beats })
    }
    KeepDegreesChangeRhythm(pattern) => {
      if pattern.cells.length() != motif.events.length() {
        return Err(
          InvalidTransform(
            "新 rhythm cell 数量(\{pattern.cells.length()})与原动机事件数(\{motif.events.length()})不匹配",
          ),
        )
      }
      let new_events : Array[MotifEvent] = []
      for i = 0; i < motif.events.length(); i = i + 1 {
        new_events.push({
          degree: motif.events[i].degree,
          cell: pattern.cells[i],
        })
      }
      let total = calc_events_beats(new_events)
      Ok({ events: new_events, total_beats: total })
    }
  }
}

// ============================================================
// 变奏策略 API
// ============================================================

///|
/// 按策略生成变奏（checked）
pub fn vary_motif_checked(
  motif : Motif,
  strategy : MotifVariationStrategy,
) -> Result[Motif, MotifError] {
  if motif.events.length() == 0 {
    return Err(InvalidMotif("动机事件为空"))
  }
  match strategy {
    ExactRepeat => transform_motif_checked(motif, Repeat(2))
    SequenceUp => transform_motif_checked(motif, TransposeDegrees(1))
    SequenceDown => transform_motif_checked(motif, TransposeDegrees(-1))
    Inversion => {
      let axis = motif.events[0].degree
      transform_motif_checked(motif, InvertAround(axis))
    }
    RetrogradeVariation => transform_motif_checked(motif, Retrograde)
    RhythmicAugmentation => transform_motif_checked(motif, Augment)
    RhythmicDiminution => transform_motif_checked(motif, Diminish)
    CallResponse => {
      // 先重复（2 份），再整体升 2 度
      let repeated = match transform_motif_checked(motif, Repeat(2)) {
        Ok(m) => m
        Err(e) => return Err(e)
      }
      transform_motif_checked(repeated, TransposeDegrees(2))
    }
  }
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

// ============================================================
// Track 转换 API
// ============================================================

///|
/// 将动机转换为可插入曲谱的 Track
pub fn motif_to_track_checked(
  motif : Motif,
  key : Key,
  start_octave : Int,
  dur_fallback : Duration,
) -> Result[Track, MotifError] {
  if motif.events.length() == 0 {
    return Err(InvalidMotif("动机事件为空"))
  }
  let music_events : Array[MusicEvent] = []
  for e in motif.events {
    if e.cell.is_rest {
      music_events.push(Rest(rest(e.cell.duration)))
    } else {
      let pitch = key.degree(e.degree, start_octave)
      let vel_raw = DEFAULT_VELOCITY.to_double() *
        e.cell.accent.velocity_multiplier()
      let vel = vel_raw.to_int()
      let clamped_vel = if vel > MAX_VELOCITY {
        MAX_VELOCITY
      } else if vel < 1 {
        1
      } else {
        vel
      }
      music_events.push(
        Note(note_with_velocity(pitch, e.cell.duration, clamped_vel)),
      )
    }
  }
  Ok(track(music_events))
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
/// FFI：对动机执行变换，返回 JSON
pub fn ffi_transform_motif_json(input_json : String) -> String {
  // 解析 JSON 输入
  let parsed = match json_parse(input_json) {
    Ok(v) => v
    Err(e) =>
      return build_ffi_error("MotifParseError", "JSON 解析失败：\{e}")
  }
  // 提取 transform 字段
  let (transform_name, motif_degrees, rhythm_str) = match parsed {
    JObject(fields) => {
      let t = match find_jv_field(fields, "transform") {
        Some(JString(s)) => s
        _ =>
          return build_ffi_error("MotifParseError", "缺少 transform 字段")
      }
      // 提取 motif 的 degrees 和 rhythm
      let degs = match find_jv_field(fields, "degrees") {
        Some(JArray(arr)) => {
          let result : Array[Int] = []
          for item in arr {
            match item {
              JNumber(n) => result.push(n.to_int())
              _ => ()
            }
          }
          result
        }
        _ => []
      }
      let rhy = match find_jv_field(fields, "rhythm") {
        Some(JString(s)) => s
        _ => "q q q q"
      }
      (t, degs, rhy)
    }
    _ => return build_ffi_error("MotifParseError", "JSON 必须为对象")
  }
  // 构造临时动机并执行变换
  if motif_degrees.length() == 0 {
    return build_ffi_error("MotifParseError", "缺少有效的 degrees 字段")
  }
  let rhy_pat = match parse_rhythm_pattern(rhythm_str) {
    Ok(p) => p
    Err(e) => return build_ffi_error("MotifParseError", e.to_string())
  }
  let mot = match motif_checked(motif_degrees, rhy_pat) {
    Ok(m) => m
    Err(e) => return build_ffi_error("MotifError", e.to_string())
  }
  let transform = parse_transform_name(transform_name)
  match transform {
    Ok(t) =>
      match transform_motif_checked(mot, t) {
        Ok(result) => build_ffi_ok_data(build_motif_json(result))
        Err(e) => build_ffi_error("MotifError", e.to_string())
      }
    Err(e) => build_ffi_error("MotifParseError", e.to_string())
  }
}

///|
/// 在 JsonField 数组中查找指定 key 的 value
fn find_jv_field(fields : Array[JsonField], key : String) -> JsonValue? {
  for f in fields {
    if f.key == key {
      return Some(f.value)
    }
  }
  None
}

///|
/// 解析变换名称字符串到 MotifTransform
fn parse_transform_name(name : String) -> Result[MotifTransform, MotifError] {
  match name {
    "Retrograde" => Ok(Retrograde)
    "Augment" => Ok(Augment)
    "Diminish" => Ok(Diminish)
    "TransposeUp" | "TransposeDegrees(1)" => Ok(TransposeDegrees(1))
    "TransposeDown" | "TransposeDegrees(-1)" => Ok(TransposeDegrees(-1))
    "Invert" => Ok(InvertAround(5))
    "Repeat" => Ok(Repeat(2))
    "Rotate" => Ok(Rotate(1))
    _ => Err(MotifUnsupported("未知变换名称：\{name}"))
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
/// 构建 Motif 的 JSON 表示
fn build_motif_json(m : Motif) -> String {
  let mut events_out = "["
  for i = 0; i < m.events.length(); i = i + 1 {
    if i > 0 {
      events_out += ","
    }
    let e = m.events[i]
    events_out += "{\"degree\":" +
      e.degree.to_string() +
      ",\"cell\":" +
      cell_json(e.cell) +
      "}"
  }
  events_out += "]"
  "{\"total_beats\":" +
  format_double(m.total_beats) +
  ",\"events\":" +
  events_out +
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
/// 构建 FFI 成功响应 {"ok":true,"data":...}
fn build_ffi_ok_data(data_json : String) -> String {
  "{\"ok\":true,\"data\":" + data_json + "}"
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
