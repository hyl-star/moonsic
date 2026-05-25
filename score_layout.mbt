//
// 曲谱布局模块 — Measure/Voice/Staff/Part/ScoreLayout 结构层
// 将已有 MusicEvent/Track/Score 组织为小节/声部/五线谱/声部组的层级结构
//

// ============================================================
// ScoreError — 曲谱布局模块的统一错误类型
// ============================================================

///|
/// 曲谱布局模块的错误类型
pub(all) enum ScoreError {
  LayoutInvalidMeasure(String)
  LayoutInvalidVoice(String)
  LayoutInvalidStaff(String)
  LayoutInvalidPart(String)
  InvalidScoreLayout(String)
  LayoutMeasureOverflow(String)
  InvalidPPQ(Int)
  LayoutInvalidChannel(Int)
  LayoutInvalidProgram(Int)
}

///|
/// 转为可读的错误消息（中文）
pub fn ScoreError::to_string(self : ScoreError) -> String {
  match self {
    LayoutInvalidMeasure(msg) => "无效小节：\{msg}"
    LayoutInvalidVoice(msg) => "无效声部：\{msg}"
    LayoutInvalidStaff(msg) => "无效五线谱：\{msg}"
    LayoutInvalidPart(msg) => "无效声部组：\{msg}"
    InvalidScoreLayout(msg) => "无效曲谱布局：\{msg}"
    LayoutMeasureOverflow(msg) => "小节溢出：\{msg}"
    InvalidPPQ(ppq) => "无效 PPQ：\{ppq}（必须 > 0）"
    LayoutInvalidChannel(ch) => "无效通道：\{ch}（合法范围 0-15）"
    LayoutInvalidProgram(prog) =>
      "无效乐器程序号：\{prog}（合法范围 0-127）"
  }
}

// ============================================================
// Measure — 小节
// ============================================================

///|
/// 小节 = 索引 + 可选拍号 + 音乐事件序列
/// 事件在节内按顺序排列，起始位置为小节第 0 拍
pub(all) struct Measure {
  index : Int
  signature : TimeSignature?
  events : Array[MusicEvent]
}

///|
/// 构造小节。index >= 0，signature 若存在则必须合法。
/// signature = None 表示继承前一个有效拍号
pub fn make_measure(
  index : Int,
  signature : TimeSignature?,
  events : Array[MusicEvent],
) -> Result[Measure, ScoreError] {
  if index < 0 {
    return Err(
      LayoutInvalidMeasure("小节索引必须 >= 0，当前：\{index}"),
    )
  }
  match signature {
    Some(sig) =>
      if !is_valid_time_signature(sig.numerator, sig.denominator) {
        return Err(
          LayoutInvalidMeasure(
            "无效拍号：\{sig.numerator}/\{sig.denominator}",
          ),
        )
      }
    None => ()
  }
  Ok({ index, signature, events })
}

///|
/// 创建空小节（无事件，继承拍号）
pub fn empty_measure(index : Int) -> Measure {
  { index, signature: None, events: [] }
}

///|
/// 小节内事件数量
pub fn Measure::event_count(self : Measure) -> Int {
  self.events.length()
}

// ============================================================
// Voice — 声部
// ============================================================

///|
/// 声部 = 名称 + 有序的小节序列
pub(all) struct Voice {
  name : String
  measures : Array[Measure]
}

///|
/// 构造声部。名称不能为空
pub fn make_voice(
  name : String,
  measures : Array[Measure],
) -> Result[Voice, ScoreError] {
  if name.length() == 0 {
    return Err(LayoutInvalidVoice("声部名称不能为空"))
  }
  Ok({ name, measures })
}

///|
/// 创建空声部
pub fn empty_voice(name : String) -> Voice {
  { name, measures: [] }
}

///|
/// 向声部追加小节（不可变风格，返回新 Voice）
pub fn voice_add_measure(
  voice : Voice,
  measure : Measure,
) -> Result[Voice, ScoreError] {
  let new_measures = []
  for m in voice.measures {
    new_measures.push(m)
  }
  new_measures.push(measure)
  Ok({ name: voice.name, measures: new_measures })
}

// ============================================================
// Staff — 五线谱
// ============================================================

///|
/// 五线谱 = 名称 + MIDI 投影提示 + 声部序列
/// channel/program 只作为 MIDI 投影提示，不直接生成 MIDI 事件
pub(all) struct Staff {
  name : String
  channel : Int?
  program : Int?
  instrument_name : String?
  voices : Array[Voice]
}

///|
/// 构造五线谱。名称不能为空，channel 若存在必须在 0-15，
/// program 若存在必须在 0-127
pub fn make_staff(
  name : String,
  channel : Int?,
  program : Int?,
  instrument_name : String?,
  voices : Array[Voice],
) -> Result[Staff, ScoreError] {
  if name.length() == 0 {
    return Err(LayoutInvalidStaff("五线谱名称不能为空"))
  }
  match channel {
    Some(ch) =>
      if ch < 0 || ch > MAX_CHANNEL {
        return Err(LayoutInvalidChannel(ch))
      }
    None => ()
  }
  match program {
    Some(prog) =>
      if prog < 0 || prog > MAX_MIDI_NOTE {
        return Err(LayoutInvalidProgram(prog))
      }
    None => ()
  }
  Ok({ name, channel, program, instrument_name, voices })
}

///|
/// 创建空五线谱
pub fn empty_staff(name : String) -> Staff {
  { name, channel: None, program: None, instrument_name: None, voices: [] }
}

///|
/// 向五线谱追加声部（不可变风格，返回新 Staff）
pub fn staff_add_voice(
  staff : Staff,
  voice : Voice,
) -> Result[Staff, ScoreError] {
  let new_voices = []
  for v in staff.voices {
    new_voices.push(v)
  }
  new_voices.push(voice)
  Ok({
    name: staff.name,
    channel: staff.channel,
    program: staff.program,
    instrument_name: staff.instrument_name,
    voices: new_voices,
  })
}

// ============================================================
// Part — 声部组
// ============================================================

///|
/// 声部组 = 名称 + 五线谱序列
/// 例如钢琴声部组包含高音谱表和低音谱表两个 Staff
pub(all) struct Part {
  name : String
  staves : Array[Staff]
}

///|
/// 构造声部组。名称不能为空
pub fn make_part(
  name : String,
  staves : Array[Staff],
) -> Result[Part, ScoreError] {
  if name.length() == 0 {
    return Err(LayoutInvalidPart("声部组名称不能为空"))
  }
  Ok({ name, staves })
}

///|
/// 创建空声部组
pub fn empty_part(name : String) -> Part {
  { name, staves: [] }
}

///|
/// 向声部组追加五线谱（不可变风格，返回新 Part）
pub fn part_add_staff(part : Part, staff : Staff) -> Result[Part, ScoreError] {
  let new_staves = []
  for s in part.staves {
    new_staves.push(s)
  }
  new_staves.push(staff)
  Ok({ name: part.name, staves: new_staves })
}

// ============================================================
// ScoreLayout — 曲谱总布局
// ============================================================

///|
/// 曲谱总布局 = 标题 + PPQ + 作曲者 + 声部组列表 + 初始速度/拍号
pub(all) struct ScoreLayout {
  title : String
  ppq : Int
  composer : String
  parts : Array[Part]
  initial_tempo : Tempo
  initial_signature : TimeSignature
}

///|
/// 构造曲谱布局。ppq > 0，默认速度 120、拍号 4/4
pub fn make_score_layout(
  title : String,
  ppq : Int,
  parts : Array[Part],
) -> Result[ScoreLayout, ScoreError] {
  if ppq <= 0 {
    return Err(InvalidPPQ(ppq))
  }
  Ok({
    title,
    ppq,
    composer: "",
    parts,
    initial_tempo: default_tempo(),
    initial_signature: four_four(),
  })
}

///|
/// 创建空曲谱布局（无声部组）
pub fn empty_score_layout(
  title : String,
  ppq : Int,
) -> Result[ScoreLayout, ScoreError] {
  if ppq <= 0 {
    return Err(InvalidPPQ(ppq))
  }
  Ok({
    title,
    ppq,
    composer: "",
    parts: [],
    initial_tempo: default_tempo(),
    initial_signature: four_four(),
  })
}

///|
/// 向曲谱布局追加声部组（不可变风格）
pub fn layout_add_part(layout : ScoreLayout, part : Part) -> ScoreLayout {
  let new_parts = []
  for p in layout.parts {
    new_parts.push(p)
  }
  new_parts.push(part)
  {
    title: layout.title,
    ppq: layout.ppq,
    composer: layout.composer,
    parts: new_parts,
    initial_tempo: layout.initial_tempo,
    initial_signature: layout.initial_signature,
  }
}

// ============================================================
// 校验
// ============================================================

///|
/// 校验单小节：索引合法、拍号合法、事件总时值不超出小节容量
pub fn validate_measure(
  measure : Measure,
  default_sig : TimeSignature,
  ppq : Int,
) -> Result[Unit, ScoreError] {
  if ppq <= 0 {
    return Err(InvalidPPQ(ppq))
  }
  if measure.index < 0 {
    return Err(
      LayoutInvalidMeasure(
        "小节索引必须 >= 0，当前：\{measure.index}",
      ),
    )
  }
  let sig = match measure.signature {
    Some(s) => s
    None => default_sig
  }
  if !is_valid_time_signature(sig.numerator, sig.denominator) {
    return Err(
      LayoutInvalidMeasure("无效拍号：\{sig.numerator}/\{sig.denominator}"),
    )
  }
  let bar_ticks = match bar_length_ticks(sig, ppq) {
    Ok(v) => v
    Err(e) => return Err(LayoutInvalidMeasure(e.to_string()))
  }
  let mut total_ticks = 0
  for i = 0; i < measure.events.length(); i = i + 1 {
    total_ticks = total_ticks + measure.events[i].duration().ticks(ppq)
  }
  if total_ticks > bar_ticks {
    return Err(
      LayoutMeasureOverflow(
        "小节 \{measure.index} 的总时值 \{total_ticks} tick 超过小节容量 \{bar_ticks} tick（拍号 \{sig.numerator}/\{sig.denominator}）",
      ),
    )
  }
  Ok(())
}

///|
/// 校验声部：每个小节通过 validate_measure
pub fn validate_voice(
  voice : Voice,
  default_sig : TimeSignature,
  ppq : Int,
) -> Result[Unit, ScoreError] {
  if voice.name.length() == 0 {
    return Err(LayoutInvalidVoice("声部名称不能为空"))
  }
  for i = 0; i < voice.measures.length(); i = i + 1 {
    match validate_measure(voice.measures[i], default_sig, ppq) {
      Ok(_) => ()
      Err(e) => return Err(e)
    }
  }
  Ok(())
}

///|
/// 校验五线谱：通道/乐器范围合法 + 每个声部校验
pub fn validate_staff(
  staff : Staff,
  default_sig : TimeSignature,
  ppq : Int,
) -> Result[Unit, ScoreError] {
  if staff.name.length() == 0 {
    return Err(LayoutInvalidStaff("五线谱名称不能为空"))
  }
  match staff.channel {
    Some(ch) =>
      if ch < MIN_CHANNEL || ch > MAX_CHANNEL {
        return Err(LayoutInvalidChannel(ch))
      }
    None => ()
  }
  match staff.program {
    Some(prog) =>
      if prog < 0 || prog > MAX_MIDI_NOTE {
        return Err(LayoutInvalidProgram(prog))
      }
    None => ()
  }
  for i = 0; i < staff.voices.length(); i = i + 1 {
    match validate_voice(staff.voices[i], default_sig, ppq) {
      Ok(_) => ()
      Err(e) => return Err(e)
    }
  }
  Ok(())
}

///|
/// 校验声部组：每个五线谱校验
pub fn validate_part(
  part : Part,
  default_sig : TimeSignature,
  ppq : Int,
) -> Result[Unit, ScoreError] {
  if part.name.length() == 0 {
    return Err(LayoutInvalidPart("声部组名称不能为空"))
  }
  for i = 0; i < part.staves.length(); i = i + 1 {
    match validate_staff(part.staves[i], default_sig, ppq) {
      Ok(_) => ()
      Err(e) => return Err(e)
    }
  }
  Ok(())
}

///|
/// 校验曲谱布局：ppq > 0 + 所有声部组校验
pub fn validate_score_layout(layout : ScoreLayout) -> Result[Unit, ScoreError] {
  if layout.ppq <= 0 {
    return Err(InvalidPPQ(layout.ppq))
  }
  let sig = layout.initial_signature
  for i = 0; i < layout.parts.length(); i = i + 1 {
    match validate_part(layout.parts[i], sig, layout.ppq) {
      Ok(_) => ()
      Err(e) => return Err(e)
    }
  }
  Ok(())
}

// ============================================================
// 查询
// ============================================================

///|
/// 曲谱布局中的最大小节数（遍历所有声部组/五线谱/声部取 max）
pub fn score_layout_measure_count(layout : ScoreLayout) -> Int {
  let mut max_count = 0
  for i = 0; i < layout.parts.length(); i = i + 1 {
    let pc = _part_max_measure_count(layout.parts[i])
    if pc > max_count {
      max_count = pc
    }
  }
  max_count
}

///|
/// 内部：Part 的最大小节数
fn _part_max_measure_count(part : Part) -> Int {
  let mut max_count = 0
  for i = 0; i < part.staves.length(); i = i + 1 {
    let sc = staff_measure_count(part.staves[i])
    if sc > max_count {
      max_count = sc
    }
  }
  max_count
}

///|
/// 五线谱内的小节数（各声部取最大值）
pub fn staff_measure_count(staff : Staff) -> Int {
  let mut max_count = 0
  for i = 0; i < staff.voices.length(); i = i + 1 {
    let vc = staff.voices[i].measures.length()
    if vc > max_count {
      max_count = vc
    }
  }
  max_count
}

///|
/// 声部内的小节数
pub fn voice_measure_count(voice : Voice) -> Int {
  voice.measures.length()
}

///|
/// 小节内事件的总拍数
pub fn measure_beat_duration(measure : Measure) -> Double {
  let mut total = 0.0
  for i = 0; i < measure.events.length(); i = i + 1 {
    total = total + measure.events[i].duration().beats()
  }
  total
}

///|
/// 小节内事件的总 tick 数（需 PPQ）
pub fn measure_tick_duration(measure : Measure, ppq : Int) -> Int {
  let mut total = 0
  for i = 0; i < measure.events.length(); i = i + 1 {
    total = total + measure.events[i].duration().ticks(ppq)
  }
  total
}

// ============================================================
// 转换 — Staff/Track, ScoreLayout/Score 互转
// ============================================================

///|
/// 五线谱 → 扁平 Track
/// 逐小节、逐声部拼接事件，使用 Staff 的 channel/program
pub fn staff_to_track(staff : Staff) -> Track {
  let total_events = []
  // 确定最大小节数
  let max_measures = staff_measure_count(staff)
  // 逐小节、逐声部收集事件
  for mi = 0; mi < max_measures; mi = mi + 1 {
    for vi = 0; vi < staff.voices.length(); vi = vi + 1 {
      if mi < staff.voices[vi].measures.length() {
        let m = staff.voices[vi].measures[mi]
        for ei = 0; ei < m.events.length(); ei = ei + 1 {
          total_events.push(m.events[ei])
        }
      }
    }
  }
  let ch = match staff.channel {
    Some(c) => c
    None => 0
  }
  let prog = match staff.program {
    Some(p) => p
    None => -1
  }
  {
    events: total_events,
    channel: ch,
    program: prog,
    volume: 1.0,
    pan: 0.0,
    mute: false,
  }
}

///|
/// 曲谱布局 → Score（现有乐谱类型）
/// 每个 Part 的每个 Staff 转为一条 Track
pub fn score_layout_to_score(layout : ScoreLayout) -> Score {
  let tracks = []
  for i = 0; i < layout.parts.length(); i = i + 1 {
    for j = 0; j < layout.parts[i].staves.length(); j = j + 1 {
      tracks.push(staff_to_track(layout.parts[i].staves[j]))
    }
  }
  {
    tempo: layout.initial_tempo,
    time_signature: layout.initial_signature,
    tracks,
    master_gain: 0.85,
  }
}

///|
/// 从现有 Track 反推为 Voice（简单映射：整个 Track 作为一个声部的小节序列）
/// 按默认拍号 4/4 切分事件到小节
pub fn track_to_voice(
  track : Track,
  name : String,
  ppq : Int,
  sig : TimeSignature,
) -> Result[Voice, ScoreError] {
  if ppq <= 0 {
    return Err(InvalidPPQ(ppq))
  }
  if !is_valid_time_signature(sig.numerator, sig.denominator) {
    return Err(
      LayoutInvalidMeasure("无效拍号：\{sig.numerator}/\{sig.denominator}"),
    )
  }
  let bar_ticks = match bar_length_ticks(sig, ppq) {
    Ok(v) => v
    Err(e) => return Err(LayoutInvalidMeasure(e.to_string()))
  }
  let measures = []
  let mut measure_index = 0
  let mut current_tick = 0
  let mut current_events = []
  for i = 0; i < track.events.length(); i = i + 1 {
    let evt = track.events[i]
    let evt_ticks = evt.duration().ticks(ppq)
    // 尝试将事件放入当前小节
    if current_tick + evt_ticks <= bar_ticks {
      current_events.push(evt)
      current_tick = current_tick + evt_ticks
    } else {
      // 当前事件放不下，先闭合当前小节
      if current_events.length() > 0 {
        measures.push({
          index: measure_index,
          signature: if measure_index == 0 {
            Some(sig)
          } else {
            None
          },
          events: current_events,
        })
        measure_index = measure_index + 1
      }
      current_events = [evt]
      current_tick = evt_ticks
    }
  }
  // 闭合最后一个小节
  if current_events.length() > 0 {
    measures.push({
      index: measure_index,
      signature: None,
      events: current_events,
    })
  }
  Ok({ name, measures })
}

///|
/// 从现有 Track 反推为 Staff（单声部五线谱）
pub fn track_to_staff(
  track : Track,
  name : String,
  ppq : Int,
  sig : TimeSignature,
) -> Result[Staff, ScoreError] {
  let voice = match track_to_voice(track, name, ppq, sig) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let ch = if track.channel >= MIN_CHANNEL && track.channel <= MAX_CHANNEL {
    Some(track.channel)
  } else {
    None
  }
  let prog = if track.program >= 0 { Some(track.program) } else { None }
  Ok({
    name,
    channel: ch,
    program: prog,
    instrument_name: None,
    voices: [voice],
  })
}
