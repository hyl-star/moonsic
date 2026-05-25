//
// 专业曲谱结构增强模块 — EnhancedMeasure/Voice/Staff/Part/ScoreLayout + Section/Repeat/Ending/Notation/Lyric
// 提供更接近专业乐谱和 MusicXML 的高层曲谱结构表达能力
// 不修改现有 ScoreLayout API，与 v1.x 并存
//

// ============================================================
// ScoreStructureError — 曲谱结构增强模块的统一错误类型
// ============================================================

///|
/// 曲谱结构增强模块的错误类型
pub(all) enum ScoreStructureError {
  InvalidSection(String)
  InvalidRepeat(String)
  InvalidEnding(String)
  StructInvalidMeasure(String)
  StructInvalidVoice(String)
  StructInvalidStaff(String)
  StructInvalidPart(String)
  InvalidNotation(String)
  InvalidLyric(String)
  InvalidPickup(String)
  InvalidTie(String)
  InvalidPPQ(String)
  ScoreStructureUnsupported(String)
}

///|
/// 转为可读的错误消息（中文）
pub fn ScoreStructureError::to_string(self : ScoreStructureError) -> String {
  match self {
    InvalidSection(msg) => "无效段落：\{msg}"
    InvalidRepeat(msg) => "无效反复：\{msg}"
    InvalidEnding(msg) => "无效结尾：\{msg}"
    StructInvalidMeasure(msg) => "无效小节：\{msg}"
    StructInvalidVoice(msg) => "无效声部：\{msg}"
    StructInvalidStaff(msg) => "无效五线谱：\{msg}"
    StructInvalidPart(msg) => "无效声部组：\{msg}"
    InvalidNotation(msg) => "无效演奏记号：\{msg}"
    InvalidLyric(msg) => "无效歌词：\{msg}"
    InvalidPickup(msg) => "无效弱起小节：\{msg}"
    InvalidTie(msg) => "无效连音：\{msg}"
    InvalidPPQ(msg) => "无效 PPQ：\{msg}"
    ScoreStructureUnsupported(msg) => "不支持：\{msg}"
  }
}

// ============================================================
// 基础枚举类型
// ============================================================

///|
/// 段落类型 — 对应乐谱中不同功能的段落
pub(all) enum SectionKind {
  Intro
  Verse
  Chorus
  Bridge
  Solo
  Outro
  CustomSection
}

///|
/// SectionKind 默认标签
pub fn SectionKind::default_label(self : SectionKind) -> String {
  match self {
    Intro => "Intro"
    Verse => "Verse"
    Chorus => "Chorus"
    Bridge => "Bridge"
    Solo => "Solo"
    Outro => "Outro"
    CustomSection => "Custom"
  }
}

///|
/// SectionKind 回放行为
pub fn SectionKind::playback_meaning(self : SectionKind) -> String {
  match self {
    Intro => "顺序播放"
    Verse => "顺序播放"
    Chorus => "顺序播放，可重复"
    Bridge => "顺序播放"
    Solo => "顺序播放"
    Outro => "结尾段"
    CustomSection => "顺序播放"
  }
}

///|
/// 反复标记类型
pub(all) enum RepeatKind {
  RepeatStart
  RepeatEnd
  RepeatBoth
  Fine
  DaCapo
  DalSegno
  ToCoda
  Coda
}

///|
/// RepeatKind 导航含义
pub fn RepeatKind::navigation_meaning(self : RepeatKind) -> String {
  match self {
    RepeatStart => "反复起点"
    RepeatEnd => "反复终点"
    RepeatBoth => "同时为终点和起点"
    Fine => "结束标记"
    DaCapo => "回到开头"
    DalSegno => "回到 Segno"
    ToCoda => "跳到 Coda"
    Coda => "Coda 位置"
  }
}

///|
/// 跳转类型 — DS/DC 及其变体
pub(all) enum RepeatJumpKind {
  DC
  DCAlFine
  DCAlCoda
  DS
  DSAlFine
  DSAlCoda
}

///|
/// RepeatJumpKind 跳转目标描述
pub fn RepeatJumpKind::target(self : RepeatJumpKind) -> String {
  match self {
    DC => "measure 0"
    DCAlFine => "measure 0 then stop at Fine"
    DCAlCoda => "measure 0 then jump at ToCoda"
    DS => "nearest Segno"
    DSAlFine => "Segno then stop at Fine"
    DSAlCoda => "Segno then jump at ToCoda"
  }
}

///|
/// 结尾类型 — first/second/third 等结尾
pub(all) enum EndingKind {
  FirstEnding
  SecondEnding
  ThirdEnding
  CustomEnding(Int)
  OpenEnding
  ClosedEnding
}

///|
/// EndingKind 回放次数规则
pub fn EndingKind::playback_pass(self : EndingKind) -> String {
  match self {
    FirstEnding => "第 1 次"
    SecondEnding => "第 2 次"
    ThirdEnding => "第 3 次"
    CustomEnding(n) => "第 \{n} 次"
    OpenEnding => "未闭合 ending"
    ClosedEnding => "闭合 ending"
  }
}

///|
/// 演奏记号放置位置
pub(all) enum NotationPlacement {
  Above
  Below
}

///|
/// 演奏法类型
pub(all) enum ArticulationKind {
  Staccato
  Accent
  Tenuto
}

///|
/// ArticulationKind 回放提示
pub fn ArticulationKind::playback_hint(self : ArticulationKind) -> String {
  match self {
    Staccato => "短促"
    Accent => "加重"
    Tenuto => "保持"
  }
}

///|
/// 力度标记
pub(all) enum DynamicMark {
  Pianissimo
  Piano
  MezzoPiano
  MezzoForte
  Forte
  Fortissimo
}

///|
/// DynamicMark 对应的力度值提示
pub fn DynamicMark::velocity_hint(self : DynamicMark) -> Int {
  match self {
    Pianissimo => 40
    Piano => 55
    MezzoPiano => 70
    MezzoForte => 85
    Forte => 105
    Fortissimo => 120
  }
}

///|
/// DynamicMark 默认符号
pub fn DynamicMark::symbol(self : DynamicMark) -> String {
  match self {
    Pianissimo => "pp"
    Piano => "p"
    MezzoPiano => "mp"
    MezzoForte => "mf"
    Forte => "f"
    Fortissimo => "ff"
  }
}

///|
/// 演奏记号种类 — 涵盖 articulation, slur, tie, dynamic, ornament, fermata, breath, text
pub(all) enum NotationKind {
  Articulation(ArticulationKind)
  SlurStart
  SlurStop
  NotationTieStart
  NotationTieStop
  Dynamic(DynamicMark)
  Fermata
  Breath
  TextAnnotation
}

///|
/// NotationKind 的 MusicXML-friendly 分类
pub fn NotationKind::musicxml_category(self : NotationKind) -> String {
  match self {
    Articulation(a) =>
      match a {
        Staccato => "articulations/staccato"
        Accent => "articulations/accent"
        Tenuto => "articulations/tenuto"
      }
    SlurStart => "slur start"
    SlurStop => "slur stop"
    NotationTieStart => "tied start"
    NotationTieStop => "tied stop"
    Dynamic(d) =>
      match d {
        Pianissimo => "direction/dynamics/pp"
        Piano => "direction/dynamics/p"
        MezzoPiano => "direction/dynamics/mp"
        MezzoForte => "direction/dynamics/mf"
        Forte => "direction/dynamics/f"
        Fortissimo => "direction/dynamics/ff"
      }
    Fermata => "fermata"
    Breath => "breath-mark"
    TextAnnotation => "direction words"
  }
}

///|
/// 歌词音节类型
pub(all) enum LyricSyllableKind {
  Single
  Begin
  Middle
  End
  Melisma
}

///|
/// LyricSyllableKind 对应 MusicXML syllabic 值
pub fn LyricSyllableKind::musicxml_syllabic(self : LyricSyllableKind) -> String {
  match self {
    Single => "single"
    Begin => "begin"
    Middle => "middle"
    End => "end"
    Melisma => "extend"
  }
}

///|
/// 连音类型 — 描述音符间的连接关系
pub(all) enum TieKind {
  NoTie
  TieStart
  TieContinue
  TieStop
  TieStartStop
}

///|
/// TieKind 行为描述
pub fn TieKind::behavior(self : TieKind) -> String {
  match self {
    NoTie => "独立音符"
    TieStart => "与后续音符相连"
    TieContinue => "从前一音延续并继续"
    TieStop => "结束连音"
    TieStartStop => "同时结束前一 tie 并开启下一 tie"
  }
}

///|
/// 小节角色 — 控制校验时的容量策略
pub(all) enum MeasureRole {
  NormalMeasure
  PickupMeasure
  FinalMeasure
  CadenzaMeasure
  FreeTimeMeasure
}

///|
/// MeasureRole 的容量校验策略
pub fn MeasureRole::capacity_policy(self : MeasureRole) -> String {
  match self {
    NormalMeasure => "应等于拍号容量"
    PickupMeasure => "可小于拍号容量"
    FinalMeasure => "可小于或等于拍号容量"
    CadenzaMeasure => "可超过拍号容量"
    FreeTimeMeasure => "不按固定拍号校验"
  }
}

// ============================================================
// 数据结构
// ============================================================

///|
/// 乐谱段落 — 标记一个命名区段的小节范围
pub(all) struct ScoreSection {
  name : String
  kind : SectionKind
  start_measure : Int
  end_measure : Int
}

///|
/// 反复标记 — 在小节位置放置反复/跳转指令
pub(all) struct RepeatMark {
  kind : RepeatKind
  measure_index : Int
  target_measure : Int?
  repeat_count : Int
}

///|
/// 结尾括号 — first/second/multiple ending
pub(all) struct EndingBracket {
  number : Int
  start_measure : Int
  end_measure : Int
  kind : EndingKind
}

///|
/// Coda 标记位置
pub(all) struct CodaMark {
  measure_index : Int
}

///|
/// Segno 标记位置
pub(all) struct SegnoMark {
  measure_index : Int
}

///|
/// 演奏记号 — 绑定到特定音符/事件的标记
pub(all) struct Notation {
  kind : NotationKind
  placement : NotationPlacement
  text : String?
}

///|
/// 歌词 — 一行歌词文本，含音节信息
pub(all) struct Lyric {
  text : String
  verse : Int
  syllable : LyricSyllableKind
}

///|
/// 结构化音符 — Note 包装，附加 notations, lyric, tie 信息
pub(all) struct StructuredNote {
  note : Note
  notations : Array[Notation]
  lyric : Lyric?
  tie : TieKind
}

///|
/// 结构化事件 — MusicEvent 包装，附加 notations, lyric, tie 信息
pub(all) struct StructuredEvent {
  event : MusicEvent
  notations : Array[Notation]
  lyric : Lyric?
  tie : TieKind
}

///|
/// 增强小节 — 带角色、可选拍号的结构化事件序列
pub(all) struct EnhancedMeasure {
  index : Int
  time_signature : TimeSignature?
  role : MeasureRole
  events : Array[StructuredEvent]
}

///|
/// 增强声部 — 命名 + 有序小节序列
pub(all) struct EnhancedVoice {
  name : String
  measures : Array[EnhancedMeasure]
}

///|
/// 增强五线谱 — 命名 + MIDI 通道/乐器 + 声部序列
pub(all) struct EnhancedStaff {
  name : String
  channel : Int
  program : Int
  voices : Array[EnhancedVoice]
}

///|
/// 增强声部组 — 命名 + 五线谱序列
pub(all) struct EnhancedPart {
  name : String
  staves : Array[EnhancedStaff]
}

///|
/// 增强曲谱布局 — 声部组 + 段落/反复/结尾 + PPQ
pub(all) struct EnhancedScoreLayout {
  parts : Array[EnhancedPart]
  sections : Array[ScoreSection]
  repeats : Array[RepeatMark]
  endings : Array[EndingBracket]
  ppq : Int
}

// ============================================================
// Checked API — 返回 Result[..., ScoreStructureError]
// ============================================================

///|
/// 创建段落结构，校验名称与小节范围。
/// name 不能为空，start_measure >= 0，end_measure >= start_measure。
pub fn make_section_checked(
  name : String,
  kind : SectionKind,
  start_measure : Int,
  end_measure : Int,
) -> Result[ScoreSection, ScoreStructureError] {
  if name.length() == 0 {
    return Err(InvalidSection("段落名称不能为空"))
  }
  if start_measure < 0 {
    return Err(
      InvalidSection("起始小节必须 >= 0，当前：\{start_measure}"),
    )
  }
  if end_measure < start_measure {
    return Err(
      InvalidSection(
        "结束小节 \{end_measure} 不能小于起始小节 \{start_measure}",
      ),
    )
  }
  Ok({ name, kind, start_measure, end_measure })
}

///|
/// 创建反复或跳转标记。
/// measure_index >= 0，repeat_count 至少为 1。
pub fn make_repeat_checked(
  kind : RepeatKind,
  measure_index : Int,
  target_measure : Int?,
) -> Result[RepeatMark, ScoreStructureError] {
  if measure_index < 0 {
    return Err(
      InvalidRepeat("小节索引必须 >= 0，当前：\{measure_index}"),
    )
  }
  let repeat_count = 2
  Ok({ kind, measure_index, target_measure, repeat_count })
}

///|
/// 创建结尾括号。
/// number > 0，start_measure >= 0，end_measure >= start_measure。
pub fn make_ending_checked(
  number : Int,
  start_measure : Int,
  end_measure : Int,
  kind : EndingKind,
) -> Result[EndingBracket, ScoreStructureError] {
  if number <= 0 {
    return Err(InvalidEnding("结尾编号必须 > 0，当前：\{number}"))
  }
  if start_measure < 0 {
    return Err(
      InvalidEnding("起始小节必须 >= 0，当前：\{start_measure}"),
    )
  }
  if end_measure < start_measure {
    return Err(
      InvalidEnding(
        "结束小节 \{end_measure} 不能小于起始小节 \{start_measure}",
      ),
    )
  }
  Ok({ number, start_measure, end_measure, kind })
}

///|
/// 创建演奏记号。
pub fn make_notation_checked(
  kind : NotationKind,
  placement : NotationPlacement,
) -> Result[Notation, ScoreStructureError] {
  Ok({ kind, placement, text: None })
}

///|
/// 创建歌词，支持 verse 和 syllabic 信息。
/// text 不能为空，verse >= 0。
pub fn make_lyric_checked(
  text : String,
  verse : Int,
  syllable : LyricSyllableKind,
) -> Result[Lyric, ScoreStructureError] {
  if text.length() == 0 {
    return Err(InvalidLyric("歌词文本不能为空"))
  }
  if verse < 0 {
    return Err(InvalidLyric("歌词段落号必须 >= 0，当前：\{verse}"))
  }
  Ok({ text, verse, syllable })
}

///|
/// 把基础 note 包装为带歌词、notation、tie 的结构化事件。
pub fn structured_note_checked(
  note : Note,
  notations : Array[Notation],
  lyric : Lyric?,
  tie : TieKind,
) -> Result[StructuredEvent, ScoreStructureError] {
  Ok({ event: MusicEvent::Note(note), notations, lyric, tie })
}

///|
/// 创建增强小节。只做基础合法性校验（index >= 0），不强制容量完整。
pub fn enhanced_measure_checked(
  index : Int,
  sig : TimeSignature?,
  role : MeasureRole,
  events : Array[StructuredEvent],
) -> Result[EnhancedMeasure, ScoreStructureError] {
  if index < 0 {
    return Err(
      StructInvalidMeasure("小节索引必须 >= 0，当前：\{index}"),
    )
  }
  match sig {
    Some(s) =>
      if !is_valid_time_signature(s.numerator, s.denominator) {
        return Err(
          StructInvalidMeasure("无效拍号：\{s.numerator}/\{s.denominator}"),
        )
      }
    None => ()
  }
  Ok({ index, time_signature: sig, role, events })
}

///|
/// 创建增强声部。name 不能为空。
pub fn enhanced_voice_checked(
  name : String,
  measures : Array[EnhancedMeasure],
) -> Result[EnhancedVoice, ScoreStructureError] {
  if name.length() == 0 {
    return Err(StructInvalidVoice("声部名称不能为空"))
  }
  Ok({ name, measures })
}

///|
/// 创建增强谱表，校验 MIDI channel/program 边界。
/// channel: 0-15，program: 0-127。
pub fn enhanced_staff_checked(
  name : String,
  channel : Int,
  program : Int,
  voices : Array[EnhancedVoice],
) -> Result[EnhancedStaff, ScoreStructureError] {
  if name.length() == 0 {
    return Err(StructInvalidStaff("五线谱名称不能为空"))
  }
  if !is_valid_channel(channel) {
    return Err(
      StructInvalidStaff("无效通道：\{channel}（合法范围 0-15）"),
    )
  }
  if !is_valid_midi_note(program) {
    return Err(
      StructInvalidStaff(
        "无效乐器程序号：\{program}（合法范围 0-127）",
      ),
    )
  }
  Ok({ name, channel, program, voices })
}

///|
/// 创建增强声部组。name 不能为空。
pub fn enhanced_part_checked(
  name : String,
  staves : Array[EnhancedStaff],
) -> Result[EnhancedPart, ScoreStructureError] {
  if name.length() == 0 {
    return Err(StructInvalidPart("声部组名称不能为空"))
  }
  Ok({ name, staves })
}

///|
/// 创建增强曲谱结构。ppq > 0。
pub fn enhanced_score_layout_checked(
  parts : Array[EnhancedPart],
  sections : Array[ScoreSection],
  repeats : Array[RepeatMark],
  endings : Array[EndingBracket],
  ppq : Int,
) -> Result[EnhancedScoreLayout, ScoreStructureError] {
  if ppq <= 0 {
    return Err(InvalidPPQ("PPQ 必须 > 0，当前：\{ppq}"))
  }
  Ok({ parts, sections, repeats, endings, ppq })
}

///|
/// 从现有 Track 转成 enhanced voice。
/// 按时间顺序把 Track 事件装入 measure/voice，使用指定拍号切分。
pub fn track_to_enhanced_voice_checked(
  track : Track,
  sig : TimeSignature,
  ppq : Int,
  voice_name : String,
) -> Result[EnhancedVoice, ScoreStructureError] {
  if voice_name.length() == 0 {
    return Err(StructInvalidVoice("声部名称不能为空"))
  }
  if ppq <= 0 {
    return Err(InvalidPPQ("PPQ 必须 > 0，当前：\{ppq}"))
  }
  if !is_valid_time_signature(sig.numerator, sig.denominator) {
    return Err(
      StructInvalidMeasure("无效拍号：\{sig.numerator}/\{sig.denominator}"),
    )
  }
  let bar_ticks = match bar_length_ticks(sig, ppq) {
    Ok(v) => v
    Err(e) => return Err(StructInvalidMeasure(e.to_string()))
  }
  let measures : Array[EnhancedMeasure] = []
  let mut measure_index = 0
  let mut current_tick = 0
  let mut current_events : Array[StructuredEvent] = []
  for i = 0; i < track.events.length(); i = i + 1 {
    let evt = track.events[i]
    let evt_ticks = evt.duration().ticks(ppq)
    let se = { event: evt, notations: [], lyric: None, tie: NoTie }
    if current_tick + evt_ticks <= bar_ticks {
      current_events.push(se)
      current_tick = current_tick + evt_ticks
    } else {
      if current_events.length() > 0 {
        measures.push({
          index: measure_index,
          time_signature: if measure_index == 0 {
            Some(sig)
          } else {
            None
          },
          role: NormalMeasure,
          events: current_events,
        })
        measure_index = measure_index + 1
      }
      current_events = [se]
      current_tick = evt_ticks
    }
  }
  if current_events.length() > 0 {
    measures.push({
      index: measure_index,
      time_signature: None,
      role: NormalMeasure,
      events: current_events,
    })
  }
  Ok({ name: voice_name, measures })
}

///|
/// 从现有 Score 转成 enhanced layout。
/// 每个 Track 映射为一个 EnhancedPart + EnhancedStaff + EnhancedVoice。
pub fn score_to_enhanced_layout_checked(
  score : Score,
  ppq : Int,
) -> Result[EnhancedScoreLayout, ScoreStructureError] {
  if ppq <= 0 {
    return Err(InvalidPPQ("PPQ 必须 > 0，当前：\{ppq}"))
  }
  let parts : Array[EnhancedPart] = []
  for i = 0; i < score.tracks.length(); i = i + 1 {
    let trk = score.tracks[i]
    let voice_name = "Voice_\{i}"
    let voice = match
      track_to_enhanced_voice_checked(
        trk,
        score.time_signature,
        ppq,
        voice_name,
      ) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    let staff = match
      enhanced_staff_checked(
        "Staff_\{i}",
        trk.channel,
        if trk.program >= 0 {
          trk.program
        } else {
          0
        },
        [voice],
      ) {
      Ok(s) => s
      Err(e) => return Err(e)
    }
    let part = match enhanced_part_checked("Part_\{i}", [staff]) {
      Ok(p) => p
      Err(e) => return Err(e)
    }
    parts.push(part)
  }
  Ok({ parts, sections: [], repeats: [], endings: [], ppq })
}

///|
/// 把 enhanced layout 降级回现有 Score，供 MIDI/Timeline 复用。
/// 使用默认速度 120 和拍号 4/4。
pub fn enhanced_layout_to_score_checked(
  layout : EnhancedScoreLayout,
) -> Result[Score, ScoreStructureError] {
  let tracks : Array[Track] = []
  for i = 0; i < layout.parts.length(); i = i + 1 {
    for j = 0; j < layout.parts[i].staves.length(); j = j + 1 {
      let stf = layout.parts[i].staves[j]
      let events : Array[MusicEvent] = []
      for vi = 0; vi < stf.voices.length(); vi = vi + 1 {
        for mi = 0; mi < stf.voices[vi].measures.length(); mi = mi + 1 {
          for ei = 0
              ei < stf.voices[vi].measures[mi].events.length()
              ei = ei + 1 {
            events.push(stf.voices[vi].measures[mi].events[ei].event)
          }
        }
      }
      let trk = {
        events,
        channel: stf.channel,
        program: stf.program,
        volume: 1.0,
        pan: 0.0,
        mute: false,
      }
      tracks.push(trk)
    }
  }
  Ok({
    tempo: default_tempo(),
    time_signature: four_four(),
    tracks,
    master_gain: 0.85,
  })
}

// ============================================================
// Convenience API — 允许 fallback，注释说明
// ============================================================

///|
/// 便捷创建歌词（single syllable, verse 0）。
pub fn lyric(text : String) -> Lyric {
  { text, verse: 0, syllable: Single }
}

///|
/// 便捷创建演奏记号（placement = Above）。
pub fn notation(kind : NotationKind) -> Notation {
  { kind, placement: Above, text: None }
}

///|
/// 便捷创建增强声部。name 为空时使用 "Untitled"。
pub fn enhanced_voice(
  name : String,
  measures : Array[EnhancedMeasure],
) -> EnhancedVoice {
  let actual_name = if name.length() == 0 { "Untitled" } else { name }
  { name: actual_name, measures }
}

// ============================================================
// FFI API
// ============================================================

///|
/// FFI 入口：输入 JSON 字符串，返回结构摘要 JSON。
/// 成功：{"ok":true,"data":{...}}，失败：{"ok":false,"error":"ScoreStructureError","message":"..."}
/// 当前版本基于简单字符串匹配，不做完整 JSON 解析。
pub fn ffi_score_structure_summary_json(input : String) -> String {
  let ppq_val = _ffi_extract_ppq(input)
  if ppq_val <= 0 {
    let e = ScoreStructureError::InvalidPPQ(
      "PPQ must be > 0, got " + ppq_val.to_string(),
    )
    return _ffi_error_json(e)
  }
  let parts_count = _ffi_count_occurrences(input, "\"parts\"")
  let sections_count = _ffi_count_occurrences(input, "\"sections\"")
  let repeats_count = _ffi_count_occurrences(input, "\"repeats\"")
  let endings_count = _ffi_count_occurrences(input, "\"endings\"")
  let data = "\"parts\":" +
    parts_count.to_string() +
    ",\"sections\":" +
    sections_count.to_string() +
    ",\"repeats\":" +
    repeats_count.to_string() +
    ",\"endings\":" +
    endings_count.to_string() +
    ",\"ppq\":" +
    ppq_val.to_string()
  "{" + "\"ok\":true,\"data\":{" + data + "}" + "}"
}

///|
/// 内部：从 JSON 字符串提取 ppq 值。默认 480。
fn _ffi_extract_ppq(input : String) -> Int {
  let pattern = "\"ppq\":"
  let pos = _str_find(input, pattern)
  if pos < 0 {
    return 480
  }
  let after = input[pos + pattern.length():]
  let mut num_str = ""
  let mut i = 0
  while i < after.length() {
    let ch = after[i]
    if ch == '-' || (ch >= '0' && ch <= '9') {
      num_str = num_str + ch.to_string()
      i = i + 1
    } else {
      break
    }
  }
  if num_str.length() == 0 {
    return 480
  }
  match _str_to_int(num_str) {
    Ok(v) => v
    Err(_) => 480
  }
}

///|
/// 内部：统计 pattern 在 s 中的出现次数
fn _ffi_count_occurrences(s : String, pattern : String) -> Int {
  let mut count = 0
  let mut pos = 0
  let plen = pattern.length()
  let slen = s.length()
  while pos + plen <= slen {
    let mut matched = true
    let mut j = 0
    while j < plen {
      if s[pos + j] != pattern[j] {
        matched = false
        break
      }
      j = j + 1
    }
    if matched {
      count = count + 1
      pos = pos + plen
    } else {
      pos = pos + 1
    }
  }
  // 返回 key 出现次数（成功数组中会有逗号分隔的对象）
  if pattern.contains("parts") ||
    pattern.contains("sections") ||
    pattern.contains("repeats") ||
    pattern.contains("endings") {
    count
  } else {
    count
  }
}

///|
/// 内部：在字符串 s 中查找子串 pattern，返回首次出现位置（-1 表示未找到）
fn _str_find(s : String, pattern : String) -> Int {
  let plen = pattern.length()
  let slen = s.length()
  if plen == 0 {
    return 0
  }
  if plen > slen {
    return -1
  }
  let mut i = 0
  while i + plen <= slen {
    let mut matched = true
    let mut j = 0
    while j < plen {
      if s[i + j] != pattern[j] {
        matched = false
        break
      }
      j = j + 1
    }
    if matched {
      return i
    }
    i = i + 1
  }
  -1
}

///|
/// 内部：字符串转整数（手动解析）
fn _str_to_int(s : String) -> Result[Int, ScoreStructureError] {
  if s.length() == 0 {
    return Err(ScoreStructureUnsupported("empty string"))
  }
  let mut result = 0
  let mut sign = 1
  let mut start = 0
  if s[0] == '-' {
    sign = -1
    start = 1
  }
  for i = start; i < s.length(); i = i + 1 {
    let ch = s[i]
    if ch >= '0' && ch <= '9' {
      result = result * 10 + (ch.to_int() - 48)
    } else {
      return Err(ScoreStructureUnsupported("non-digit char"))
    }
  }
  Ok(result * sign)
}

///|
/// 内部：构建错误 JSON 响应
fn _ffi_error_json(e : ScoreStructureError) -> String {
  let err_name = match e {
    InvalidSection(_) => "InvalidSection"
    InvalidRepeat(_) => "InvalidRepeat"
    InvalidEnding(_) => "InvalidEnding"
    StructInvalidMeasure(_) => "StructInvalidMeasure"
    StructInvalidVoice(_) => "StructInvalidVoice"
    StructInvalidStaff(_) => "StructInvalidStaff"
    StructInvalidPart(_) => "StructInvalidPart"
    InvalidNotation(_) => "InvalidNotation"
    InvalidLyric(_) => "InvalidLyric"
    InvalidPickup(_) => "InvalidPickup"
    InvalidTie(_) => "InvalidTie"
    InvalidPPQ(_) => "InvalidPPQ"
    ScoreStructureUnsupported(_) => "ScoreStructureUnsupported"
  }
  let msg = e.to_string()
  "{" +
  "\"ok\":false,\"error\":\"" +
  err_name +
  "\",\"message\":\"" +
  msg +
  "\"" +
  "}"
}
