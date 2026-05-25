// ============================================================
// MusicXML 准备与导出适配模块
// 把 Moonsic 内部 Score/ScoreLayout 转换为 MusicXML-friendly 的中间结构
// 提供基础 MusicXML 导出字符串能力
// ============================================================

// ============================================================
// MusicXmlError — 模块统一错误类型
// ============================================================

///|
/// MusicXML 模块统一错误类型
pub(all) enum MusicXmlError {
  /// 无效导出选项（如 divisions <= 0）
  InvalidMusicXmlOptions(String)
  /// 不支持的特性
  MusicXmlUnsupported(String)
  /// 校验失败
  MusicXmlValidationFailed(String)
  /// 时值转换错误
  MusicXmlDurationError(String)
  /// 音高转换错误
  MusicXmlPitchError(String)
  /// 小节构造错误
  MusicXmlMeasureError(String)
  /// XML 序列化错误
  MusicXmlSerializationError(String)
}

///|
/// 转为可读的错误消息（中文）
pub fn MusicXmlError::to_string(self : MusicXmlError) -> String {
  match self {
    InvalidMusicXmlOptions(msg) => "无效 MusicXML 选项：\{msg}"
    MusicXmlUnsupported(msg) => "MusicXML 不支持：\{msg}"
    MusicXmlValidationFailed(msg) => "MusicXML 校验失败：\{msg}"
    MusicXmlDurationError(msg) => "MusicXML 时值错误：\{msg}"
    MusicXmlPitchError(msg) => "MusicXML 音高错误：\{msg}"
    MusicXmlMeasureError(msg) => "MusicXML 小节错误：\{msg}"
    MusicXmlSerializationError(msg) => "MusicXML 序列化错误：\{msg}"
  }
}

// ============================================================
// 枚举类型
// ============================================================

///|
/// MusicXML 文档类型：partwise（按声部分组）或 timewise（按时间分组）
pub(all) enum MusicXmlDocumentKind {
  /// 按声部分组的 score-partwise（最常用）
  Partwise
  /// 按时间分组的 score-timewise
  Timewise
}

///|
/// MusicXML 谱号种类
pub(all) enum MusicXmlClefKind {
  Treble
  Bass
  Alto
  Tenor
  Percussion
  /// 无指定谱号
  NoClef
}

///|
/// MusicXML 音符类型（基本时值）
pub(all) enum MusicXmlNoteType {
  WholeT
  HalfT
  QuarterT
  EighthT
  SixteenthT
}

///|
/// MusicXML 变音记号文本
pub(all) enum MusicXmlAccidental {
  FlatFlat
  MFlat
  MNatural
  MSharp
  DoubleMSharp
}

///|
/// MusicXML 方向标记种类
pub(all) enum MusicXmlDirectionKind {
  DynamicsDir
  TempoDir
  WordsDir
  RepeatDir
}

///|
/// MusicXML 演奏记号种类
pub(all) enum MusicXmlNotationKind {
  StaccatoN
  AccentN
  TenutoN
  SlurStartN
  SlurStopN
  TieStartN
  TieStopN
  FermataN
  BreathN
}

// Note:
// ValidationSeverity, ValidationReport, ValidationIssue 等类型
// 已在 validate.mbt 中定义，本模块直接复用。

// ============================================================
// MusicXML 中间结构 — 导出选项
// ============================================================

///|
/// MusicXML 导出选项
pub(all) struct MusicXmlExportOptions {
  /// 每四分音符的分度数（默认 480，即 PPQ）
  divisions : Int
  /// 文档类型
  document_kind : MusicXmlDocumentKind
  /// 是否包含 XML 头部声明
  include_xml_header : Bool
  /// 严格模式：Error/Fatal 阻止导出
  strict : Bool
  /// 声部名称回退值
  part_name_fallback : String
}

// ============================================================
// MusicXML 中间结构 — 核心
// ============================================================

///|
/// MusicXML 乐谱中间结构
pub(all) struct MusicXmlScore {
  title : String
  parts : Array[MusicXmlPart]
  divisions : Int
}

///|
/// MusicXML 声部
pub(all) struct MusicXmlPart {
  id : String
  name : String
  measures : Array[MusicXmlMeasure]
}

///|
/// MusicXML 小节
pub(all) struct MusicXmlMeasure {
  number : Int
  attributes : MusicXmlAttributes?
  notes : Array[MusicXmlNote]
  directions : Array[MusicXmlDirection]
}

///|
/// MusicXML 小节属性（divisions、拍号、谱号）
pub(all) struct MusicXmlAttributes {
  divisions : Int
  time_signature : TimeSignature
  clef : MusicXmlClefKind
}

///|
/// MusicXML 音符
pub(all) struct MusicXmlNote {
  pitch : MusicXmlPitch?
  duration : Int
  note_type : MusicXmlNoteType
  dots : Int
  is_rest : Bool
  is_chord_tone : Bool
  voice : Int
  staff : Int
  notations : Array[MusicXmlNotation]
}

///|
/// MusicXML 音高（step + alter + octave）
pub(all) struct MusicXmlPitch {
  step : String
  alter : Int
  octave : Int
}

///|
/// MusicXML 方向标记
pub(all) struct MusicXmlDirection {
  kind : MusicXmlDirectionKind
  content : String
}

///|
/// MusicXML 演奏记号
pub(all) struct MusicXmlNotation {
  kind : MusicXmlNotationKind
}

///|
/// MusicXML 时间回退（多声部）
pub(all) struct MusicXmlBackup {
  duration : Int
}

///|
/// MusicXML 时间前移（多声部）
pub(all) struct MusicXmlForward {
  duration : Int
}

// ============================================================
// 规则映射函数
// ============================================================

///|
/// PitchClass -> MusicXML step 字母
fn pitch_class_to_step(pc : PitchClass) -> String {
  pc.to_string()
}

///|
/// Accidental -> MusicXML alter 值（DoubleFlat=-2, ..., DoubleSharp=+2）
fn accidental_to_alter(acc : Accidental) -> Int {
  acc.semitone_offset()
}

///|
/// Duration -> 基础 MusicXmlNoteType（剥离附点）
fn duration_to_base_note_type(d : Duration) -> MusicXmlNoteType {
  let base = strip_dots(d)
  match base {
    Whole => WholeT
    Half => HalfT
    Quarter => QuarterT
    Eighth => EighthT
    Sixteenth => SixteenthT
    Dotted(_) => QuarterT
  }
}

///|
/// 剥离 Duration 的所有附点包装，返回基础时值
fn strip_dots(d : Duration) -> Duration {
  match d {
    Dotted(base) => strip_dots(base)
    _ => d
  }
}

///|
/// 计算 Duration 的附点数（Dotted 嵌套深度）
fn count_dots(d : Duration) -> Int {
  match d {
    Dotted(base) => 1 + count_dots(base)
    _ => 0
  }
}

///|
/// MusicXmlNoteType -> MusicXML type 元素文本
fn note_type_to_xml_text(nt : MusicXmlNoteType) -> String {
  match nt {
    WholeT => "whole"
    HalfT => "half"
    QuarterT => "quarter"
    EighthT => "eighth"
    SixteenthT => "16th"
  }
}

///|
/// MusicXmlClefKind -> MusicXML sign 属性
fn clef_to_sign(clef : MusicXmlClefKind) -> String {
  match clef {
    Treble => "G"
    Bass => "F"
    Alto => "C"
    Tenor => "C"
    Percussion => "percussion"
    NoClef => "G"
  }
}

///|
/// MusicXmlClefKind -> MusicXML line 属性
fn clef_to_line(clef : MusicXmlClefKind) -> Int {
  match clef {
    Treble => 2
    Bass => 4
    Alto => 3
    Tenor => 4
    Percussion => 2
    NoClef => 2
  }
}

///|
/// MusicXmlNotationKind -> MusicXML notation XML tag 名称
fn notation_kind_to_tag(kind : MusicXmlNotationKind) -> String {
  match kind {
    StaccatoN => "staccato"
    AccentN => "accent"
    TenutoN => "tenuto"
    SlurStartN => "slur"
    SlurStopN => "slur"
    TieStartN => "tied"
    TieStopN => "tied"
    FermataN => "fermata"
    BreathN => "breath-mark"
  }
}

///|
/// 计算小节的 tick 容量 = numerator * 4 * divisions / denominator
fn measure_cap_ticks(sig : TimeSignature, divisions : Int) -> Int {
  sig.numerator * 4 * divisions / sig.denominator
}

// ============================================================
// XML 安全序列化工具
// ============================================================

///|
/// XML 文本转义：将 & < > " ' 替换为 XML 实体
fn xml_escape(s : String) -> String {
  let mut out = ""
  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i]
    if c == '&' {
      out = out + "&amp;"
    } else if c == '<' {
      out = out + "&lt;"
    } else if c == '>' {
      out = out + "&gt;"
    } else if c == '\"' {
      out = out + "&quot;"
    } else if c == '\'' {
      out = out + "&apos;"
    } else {
      out = out + s[i:i + 1].to_owned()
    }
  }
  out
}

// ============================================================
// 内部转换：Score/Track -> MusicXmlScore
// ============================================================

///|
/// 将 MusicEvent 转为 MusicXmlNote 列表
/// Note -> 1 个 MusicXmlNote, Rest -> 1 个, Chord -> N 个
fn event_to_xml_notes(
  evt : MusicEvent,
  divisions : Int,
  voice : Int,
) -> Array[MusicXmlNote] {
  match evt {
    Note(n) => {
      let p = n.pitch
      let mpitch = MusicXmlPitch::{
        step: pitch_class_to_step(p.class),
        alter: accidental_to_alter(p.accidental),
        octave: p.octave,
      }
      let dur_ticks = n.duration.ticks(divisions)
      let ntype = duration_to_base_note_type(n.duration)
      let dots = count_dots(n.duration)
      [
        MusicXmlNote::{
          pitch: Some(mpitch),
          duration: dur_ticks,
          note_type: ntype,
          dots,
          is_rest: false,
          is_chord_tone: false,
          voice,
          staff: 1,
          notations: [],
        },
      ]
    }
    Rest(r) => {
      let dur_ticks = r.duration.ticks(divisions)
      let ntype = duration_to_base_note_type(r.duration)
      let dots = count_dots(r.duration)
      [
        MusicXmlNote::{
          pitch: None,
          duration: dur_ticks,
          note_type: ntype,
          dots,
          is_rest: true,
          is_chord_tone: false,
          voice,
          staff: 1,
          notations: [],
        },
      ]
    }
    Chord(c) => {
      let notes : Array[MusicXmlNote] = []
      let dur_ticks = c.duration.ticks(divisions)
      let ntype = duration_to_base_note_type(c.duration)
      let dots = count_dots(c.duration)
      for i = 0; i < c.pitches.length(); i = i + 1 {
        let p = c.pitches[i]
        let mpitch = MusicXmlPitch::{
          step: pitch_class_to_step(p.class),
          alter: accidental_to_alter(p.accidental),
          octave: p.octave,
        }
        notes.push(MusicXmlNote::{
          pitch: Some(mpitch),
          duration: dur_ticks,
          note_type: ntype,
          dots,
          is_rest: false,
          is_chord_tone: i > 0,
          voice,
          staff: 1,
          notations: [],
        })
      }
      notes
    }
  }
}

///|
/// 将事件序列按小节分组，返回 MusicXmlMeasure 列表
fn group_events_to_measures(
  events : Array[MusicEvent],
  sig : TimeSignature,
  divisions : Int,
  voice : Int,
) -> Array[MusicXmlMeasure] {
  let cap = measure_cap_ticks(sig, divisions)
  if cap <= 0 {
    return []
  }
  let measures : Array[MusicXmlMeasure] = []
  let mut current_tick = 0
  let mut measure_number = 1
  let mut current_notes : Array[MusicXmlNote] = []

  for i = 0; i < events.length(); i = i + 1 {
    let evt = events[i]
    let evt_ticks = evt.duration().ticks(divisions)

    if current_tick + evt_ticks <= cap || current_notes.length() == 0 {
      // 事件可放入当前小节（或当前小节为空时强制执行）
      let notes = event_to_xml_notes(evt, divisions, voice)
      for n in notes {
        current_notes.push(n)
      }
      current_tick = current_tick + evt_ticks
    } else {
      // 闭合当前小节
      measures.push(
        make_xml_measure(measure_number, current_notes, sig, divisions),
      )
      measure_number = measure_number + 1
      current_notes = []
      current_tick = 0
      // 将事件放入新小节
      let notes = event_to_xml_notes(evt, divisions, voice)
      for n in notes {
        current_notes.push(n)
      }
      current_tick = evt_ticks
    }
  }

  // 闭合最后小节
  if current_notes.length() > 0 {
    measures.push(
      make_xml_measure(measure_number, current_notes, sig, divisions),
    )
  }

  // 确保至少一个空小节
  if measures.length() == 0 {
    measures.push(make_xml_measure(1, [], sig, divisions))
  }

  measures
}

///|
/// 构造 MusicXmlMeasure，第一个小节包含 attributes
fn make_xml_measure(
  number : Int,
  notes : Array[MusicXmlNote],
  sig : TimeSignature,
  divisions : Int,
) -> MusicXmlMeasure {
  let attrs = if number == 1 {
    Some(MusicXmlAttributes::{ divisions, time_signature: sig, clef: Treble })
  } else {
    None
  }
  MusicXmlMeasure::{ number, attributes: attrs, notes, directions: [] }
}

///|
/// 将 Track 转为 MusicXmlPart
fn track_to_xml_part(
  track : Track,
  id : String,
  name : String,
  sig : TimeSignature,
  divisions : Int,
) -> MusicXmlPart {
  let events = track.events
  let measures = group_events_to_measures(events, sig, divisions, 1)
  MusicXmlPart::{ id, name, measures }
}

// ============================================================
// 公开 API — 默认选项
// ============================================================

///|
/// 返回默认导出配置：
/// divisions=480, partwise, 含 XML header, 非严格模式
pub fn default_musicxml_export_options() -> MusicXmlExportOptions {
  MusicXmlExportOptions::{
    divisions: DEFAULT_PPQ,
    document_kind: Partwise,
    include_xml_header: true,
    strict: false,
    part_name_fallback: "Instrument",
  }
}

// ============================================================
// 公开 API — Checked 转换
// ============================================================

///|
/// 将 Score 转为 MusicXmlScore 中间对象。
/// 校验 options.divisions > 0，失败返回 Err。
pub fn score_to_musicxml_checked(
  score : Score,
  options : MusicXmlExportOptions,
) -> Result[MusicXmlScore, MusicXmlError] {
  if options.divisions <= 0 {
    return Err(
      InvalidMusicXmlOptions("divisions must be > 0, got \{options.divisions}"),
    )
  }

  let parts : Array[MusicXmlPart] = []
  let tracks = score.tracks
  for i = 0; i < tracks.length(); i = i + 1 {
    let t = tracks[i]
    let part_id = "P\{i + 1}"
    let part_name = options.part_name_fallback
    let part = track_to_xml_part(
      t,
      part_id,
      part_name,
      score.time_signature,
      options.divisions,
    )
    parts.push(part)
  }

  Ok(MusicXmlScore::{ title: "", parts, divisions: options.divisions })
}

///|
/// 将 ScoreLayout 转为 MusicXmlScore 中间对象。
/// 先转 Score 再转 MusicXmlScore。
pub fn score_layout_to_musicxml_checked(
  layout : ScoreLayout,
  options : MusicXmlExportOptions,
) -> Result[MusicXmlScore, MusicXmlError] {
  let score = score_layout_to_score(layout)
  score_to_musicxml_checked(score, options)
}

// ============================================================
// 公开 API — XML 序列化
// ============================================================

///|
/// 将 MusicXmlScore 中间对象序列化为 MusicXML XML 字符串
pub fn musicxml_to_string_checked(
  doc : MusicXmlScore,
  options : MusicXmlExportOptions,
) -> Result[String, MusicXmlError] {
  if options.divisions <= 0 {
    return Err(
      InvalidMusicXmlOptions("divisions must be > 0, got \{options.divisions}"),
    )
  }

  let mut xml = ""

  // XML header
  if options.include_xml_header {
    xml = xml + "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
    xml = xml +
      "<!DOCTYPE score-partwise PUBLIC \"-//Recordare//DTD MusicXML 4.0 Partwise//EN\" \"http://www.musicxml.org/dtds/partwise.dtd\">\n"
  }

  // root: score-partwise
  // Use version string without DOCTYPE
  // We'll use the version as plain text, not as DTD declaration
  xml = xml + "<score-partwise version=\"4.0\">\n"

  // part-list
  xml = xml + "  <part-list>\n"
  for i = 0; i < doc.parts.length(); i = i + 1 {
    let p = doc.parts[i]
    xml = xml + "    <score-part id=\"\{xml_escape(p.id)}\">\n"
    xml = xml + "      <part-name>\{xml_escape(p.name)}</part-name>\n"
    xml = xml + "    </score-part>\n"
  }
  xml = xml + "  </part-list>\n"

  // parts
  for i = 0; i < doc.parts.length(); i = i + 1 {
    let p = doc.parts[i]
    xml = xml + "  <part id=\"\{xml_escape(p.id)}\">\n"
    for j = 0; j < p.measures.length(); j = j + 1 {
      xml = xml + serialize_xml_measure(p.measures[j], 4)
    }
    xml = xml + "  </part>\n"
  }

  xml = xml + "</score-partwise>\n"
  Ok(xml)
}

///|
/// 序列化单个 MusicXmlMeasure 为 XML 字符串
fn serialize_xml_measure(m : MusicXmlMeasure, indent : Int) -> String {
  let mut s = _indent(indent)
  s = s + "<measure number=\"\{m.number}\">\n"

  // attributes (only in first measure)
  match m.attributes {
    Some(attrs) => s = s + serialize_xml_attributes(attrs, indent + 2)
    None => ()
  }

  // directions
  for i = 0; i < m.directions.length(); i = i + 1 {
    s = s + serialize_xml_direction(m.directions[i], indent + 2)
  }

  // notes
  for i = 0; i < m.notes.length(); i = i + 1 {
    s = s + serialize_xml_note(m.notes[i], indent + 2)
  }

  s = s + _indent(indent) + "</measure>\n"
  s
}

///|
fn serialize_xml_attributes(attrs : MusicXmlAttributes, indent : Int) -> String {
  let mut s = _indent(indent) + "<attributes>\n"
  let i2 = indent + 2
  s = s + _indent(i2) + "<divisions>\{attrs.divisions}</divisions>\n"
  s = s + _indent(i2) + "<time>\n"
  s = s + _indent(i2 + 2) + "<beats>\{attrs.time_signature.numerator}</beats>\n"
  s = s +
    _indent(i2 + 2) +
    "<beat-type>\{attrs.time_signature.denominator}</beat-type>\n"
  s = s + _indent(i2) + "</time>\n"
  match attrs.clef {
    NoClef => ()
    _ => {
      s = s + _indent(i2) + "<clef>\n"
      s = s + _indent(i2 + 2) + "<sign>\{clef_to_sign(attrs.clef)}</sign>\n"
      s = s + _indent(i2 + 2) + "<line>\{clef_to_line(attrs.clef)}</line>\n"
      s = s + _indent(i2) + "</clef>\n"
    }
  }
  s = s + _indent(indent) + "</attributes>\n"
  s
}

///|
fn serialize_xml_note(n : MusicXmlNote, indent : Int) -> String {
  let mut s = _indent(indent) + "<note>\n"
  let i2 = indent + 2

  if n.is_chord_tone && !n.is_rest {
    s = s + _indent(i2) + "<chord/>\n"
  }

  if n.is_rest {
    s = s + _indent(i2) + "<rest/>\n"
  } else {
    match n.pitch {
      Some(p) => {
        s = s + _indent(i2) + "<pitch>\n"
        s = s + _indent(i2 + 2) + "<step>\{xml_escape(p.step)}</step>\n"
        if p.alter != 0 {
          s = s + _indent(i2 + 2) + "<alter>\{p.alter}</alter>\n"
        }
        s = s + _indent(i2 + 2) + "<octave>\{p.octave}</octave>\n"
        s = s + _indent(i2) + "</pitch>\n"
      }
      None => s = s + _indent(i2) + "<rest/>\n"
    }
  }

  s = s + _indent(i2) + "<duration>\{n.duration}</duration>\n"
  s = s + _indent(i2) + "<type>\{note_type_to_xml_text(n.note_type)}</type>\n"

  for d = 0; d < n.dots; d = d + 1 {
    s = s + _indent(i2) + "<dot/>\n"
  }

  // voice
  if n.voice > 1 {
    s = s + _indent(i2) + "<voice>\{n.voice}</voice>\n"
  }

  // staff
  if n.staff > 1 {
    s = s + _indent(i2) + "<staff>\{n.staff}</staff>\n"
  }

  // notations
  if n.notations.length() > 0 {
    s = s + _indent(i2) + "<notations>\n"
    for ni = 0; ni < n.notations.length(); ni = ni + 1 {
      let not = n.notations[ni]
      let tag = notation_kind_to_tag(not.kind)
      match not.kind {
        SlurStartN => s = s + _indent(i2 + 2) + "<slur type=\"start\"/>\n"
        SlurStopN => s = s + _indent(i2 + 2) + "<slur type=\"stop\"/>\n"
        TieStartN => s = s + _indent(i2 + 2) + "<tied type=\"start\"/>\n"
        TieStopN => s = s + _indent(i2 + 2) + "<tied type=\"stop\"/>\n"
        FermataN => s = s + _indent(i2 + 2) + "<fermata/>\n"
        BreathN => s = s + _indent(i2 + 2) + "<breath-mark/>\n"
        StaccatoN | AccentN | TenutoN => {
          s = s + _indent(i2 + 2) + "<articulations>\n"
          s = s + _indent(i2 + 4) + "<\{tag}/>\n"
          s = s + _indent(i2 + 2) + "</articulations>\n"
        }
      }
    }
    s = s + _indent(i2) + "</notations>\n"
  }

  s = s + _indent(indent) + "</note>\n"
  s
}

///|
fn serialize_xml_direction(d : MusicXmlDirection, indent : Int) -> String {
  let mut s = _indent(indent) + "<direction>\n"
  let i2 = indent + 2
  match d.kind {
    TempoDir =>
      s = s + _indent(i2) + "<sound tempo=\"\{xml_escape(d.content)}\"/>\n"
    WordsDir =>
      s = s +
        _indent(i2) +
        "<direction-type><words>\{xml_escape(d.content)}</words></direction-type>\n"
    DynamicsDir =>
      s = s +
        _indent(i2) +
        "<direction-type><dynamics><\{xml_escape(d.content)}/></dynamics></direction-type>\n"
    RepeatDir =>
      s = s +
        _indent(i2) +
        "<direction-type><words>\{xml_escape(d.content)}</words></direction-type>\n"
  }
  s = s + _indent(indent) + "</direction>\n"
  s
}

///|
/// 生成缩进空格
fn _indent(n : Int) -> String {
  let mut s = ""
  for _k = 0; _k < n; _k = _k + 1 {
    s = s + " "
  }
  s
}

// ============================================================
// 公开 API — 一站式导出
// ============================================================

///|
/// 一站式导出：Score -> MusicXML String（Checked）
pub fn score_to_musicxml_string_checked(
  score : Score,
  options : MusicXmlExportOptions,
) -> Result[String, MusicXmlError] {
  match score_to_musicxml_checked(score, options) {
    Ok(doc) => musicxml_to_string_checked(doc, options)
    Err(e) => Err(e)
  }
}

///|
/// 便捷导出 API：Score -> MusicXML String。
/// 失败时 fallback 到最小空 score-partwise 文档。
pub fn score_to_musicxml_string(score : Score) -> String {
  let options = default_musicxml_export_options()
  match score_to_musicxml_string_checked(score, options) {
    Ok(xml) => xml
    Err(_) => {
      // Fallback to a minimal empty score-partwise document
      let fallback = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
        "<!DOCTYPE score-partwise PUBLIC \"-//Recordare//DTD MusicXML 4.0 Partwise//EN\" \"http://www.musicxml.org/dtds/partwise.dtd\">\n" +
        "<score-partwise version=\"4.0\">\n" +
        "  <part-list>\n" +
        "    <score-part id=\"P1\">\n" +
        "      <part-name>Instrument</part-name>\n" +
        "    </score-part>\n" +
        "  </part-list>\n" +
        "  <part id=\"P1\">\n" +
        "    <measure number=\"1\">\n" +
        "      <attributes>\n" +
        "        <divisions>480</divisions>\n" +
        "        <time>\n" +
        "          <beats>4</beats>\n" +
        "          <beat-type>4</beat-type>\n" +
        "        </time>\n" +
        "        <clef>\n" +
        "          <sign>G</sign>\n" +
        "          <line>2</line>\n" +
        "        </clef>\n" +
        "      </attributes>\n" +
        "      <note>\n" +
        "        <rest/>\n" +
        "        <duration>1920</duration>\n" +
        "        <type>whole</type>\n" +
        "      </note>\n" +
        "    </measure>\n" +
        "  </part>\n" +
        "</score-partwise>\n"
      fallback
    }
  }
}

// ============================================================
// 公开 API — 校验
// ============================================================

///|
/// 导出前校验入口。检查 divisions 有效性、Track 数量、事件数量等。
/// 返回结构化 ValidationReport。
/// 使用 musicxml_validation_passed 判断是否允许导出。
pub fn musicxml_validate_export_ready(
  score : Score,
  options : MusicXmlExportOptions,
) -> ValidationReport {
  let mut report = {
    issues: [],
    checked_targets: 1,
    info_count: 0,
    warning_count: 0,
    error_count: 0,
    fatal_count: 0,
  }

  // 检查 divisions
  if options.divisions <= 0 {
    report = _musicxml_add_issue(
      report,
      InvalidPPQ,
      ValidateScoreTarget,
      "divisions must be > 0, got \{options.divisions}",
      Fatal,
    )
  }

  // 检查 track 数量
  if score.tracks.length() == 0 {
    report = _musicxml_add_issue(
      report,
      EmptyPart,
      ValidateScoreTarget,
      "score has no tracks",
      Error,
    )
  }

  // 检查每个 track 是否有事件
  let mut has_events = false
  for i = 0; i < score.tracks.length(); i = i + 1 {
    if score.tracks[i].events.length() > 0 {
      has_events = true
    }
  }
  if !has_events {
    report = _musicxml_add_issue(
      report,
      EmptyVoice,
      ValidateScoreTarget,
      "all tracks are empty",
      Warning,
    )
  }

  // 检查拍号合法性
  if !is_valid_time_signature(
      score.time_signature.numerator,
      score.time_signature.denominator,
    ) {
    report = _musicxml_add_issue(
      report,
      ScoreValidationUnsupported,
      ValidateScoreTarget,
      "invalid time signature: \{score.time_signature.numerator}/\{score.time_signature.denominator}",
      Fatal,
    )
  }

  report
}

///|
/// 根据校验报告和 strict 模式判断是否允许导出
pub fn musicxml_validation_passed(
  report : ValidationReport,
  strict : Bool,
) -> Bool {
  if report.fatal_count > 0 {
    return false
  }
  if strict && report.error_count > 0 {
    return false
  }
  true
}

///|
/// 内部：向 ValidationReport 追加一条 issue
fn _musicxml_add_issue(
  report : ValidationReport,
  code : ValidationCode,
  target_kind : ValidationTargetKind,
  message : String,
  severity : ValidationSeverity,
) -> ValidationReport {
  let loc = {
    target_kind,
    part_index: -1,
    staff_index: -1,
    voice_index: -1,
    measure_index: -1,
    event_index: -1,
    path: "",
  }
  let issue = {
    severity,
    code,
    location: loc,
    message,
    suggestion: "",
    source: { value: "musicxml" },
  }
  let xs = []
  for i = 0; i < report.issues.length(); i = i + 1 {
    xs.push(report.issues[i])
  }
  xs.push(issue)
  let ec = report.error_count +
    (if severity is Error || severity is Fatal { 1 } else { 0 })
  let wc = report.warning_count + (if severity is Warning { 1 } else { 0 })
  let fc = report.fatal_count + (if severity is Fatal { 1 } else { 0 })
  {
    issues: xs,
    checked_targets: report.checked_targets,
    info_count: report.info_count,
    warning_count: wc,
    error_count: ec,
    fatal_count: fc,
  }
}

// ============================================================
// 公开 API — FFI
// ============================================================

///|
/// FFI 封装：String -> String。
/// 输入：JSON 格式的 Score 字符串（与 score_from_json_string 兼容）。
/// 成功返回 {"ok":true,"data":{"xml":"..."}}
/// 失败返回 {"ok":false,"error":"MusicXmlError","message":"..."}
pub fn ffi_score_to_musicxml_json(input : String) -> String {
  let score = match score_from_json_string(input) {
    Ok(s) => s
    Err(e) => return ffi_error("MusicXmlError", e.to_string())
  }
  let options = default_musicxml_export_options()
  match score_to_musicxml_string_checked(score, options) {
    Ok(xml) => {
      // Manually build JSON with escaped XML string
      let escaped_xml = _json_escape_xml(xml)
      "{\"ok\":true,\"data\":{\"xml\":\"" + escaped_xml + "\"}}"
    }
    Err(e) => ffi_error("MusicXmlError", e.to_string())
  }
}

///|
/// 内部：对 XML 字符串做 JSON 转义（仅转义 " \ \n \r \t 等控制字符）
fn _json_escape_xml(s : String) -> String {
  // Use the shared json_escape helper to get a JSON-quoted string,
  // then strip the outer quotes.
  let quoted = json_escape(s)
  // Remove leading and trailing double-quote
  quoted[1:quoted.length() - 1].to_owned()
}
