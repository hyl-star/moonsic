//
// 旋律动机 — Motif、变换、变奏、FFI
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

// ============================================================
// 核心数据结构
// ============================================================

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

// ============================================================
// 内部辅助函数
// ============================================================

///|
/// 计算 MotifEvent 数组的总拍数
fn calc_events_beats(events : Array[MotifEvent]) -> Double {
  let mut total = 0.0
  for e in events {
    total = total + e.cell.duration.beats()
  }
  total
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
// Track 转换 API
// ============================================================

///|
/// 将动机转换为可插入曲谱的 Track
pub fn motif_to_track_checked(
  motif : Motif,
  key : Key,
  start_octave : Int,
  _dur_fallback : Duration,
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
/// 构建 FFI 成功响应 {"ok":true,"data":...}
fn build_ffi_ok_data(data_json : String) -> String {
  "{\"ok\":true,\"data\":" + data_json + "}"
}
