// ============================================================
// ScoreLayout — 专业曲谱布局
// ============================================================

// --- Part / Staff / Voice / Measure ---

///|
pub(all) struct Part {
  id : PartId
  name : String
  abbreviation : String
  staves : Array[Staff]
}

///|
pub(all) struct Staff {
  id : StaffId
  name : String
  clef : Clef
  channel : MidiChannel?
  program : MidiProgram?
  voices : Array[Voice]
}

///|
pub(all) struct Voice {
  id : VoiceId
  name : String
  measures : Array[Measure]
}

///|
pub(all) struct Measure {
  index : MeasureIndex
  role : MeasureRole
  time_signature : @time.TimeSignature?
  key_signature : KeySignature?
  tempo : Tempo?
  events : Array[ScoreEvent]
  barline : Barline?
}

// --- ScoreLayout ---

///|
pub(all) struct ScoreLayout {
  id : ScoreId
  title : String
  composer : String
  ppq : PPQ
  initial_tempo : Tempo
  initial_signature : @time.TimeSignature
  parts : Array[Part]
  sections : Array[Section]
  repeats : Array[RepeatMark]
  endings : Array[EndingBracket]
  codas : Array[CodaMark]
  segnos : Array[SegnoMark]
  metadata : ScoreMetadata
}

// --- Section / Repeat / Ending ---

///|
pub(all) struct Section {
  name : String
  kind : SectionKind
  start_measure : MeasureIndex
  end_measure : MeasureIndex
}

///|
pub(all) struct RepeatMark {
  kind : RepeatKind
  measure : MeasureIndex
  target_measure : MeasureIndex?
  repeat_count : Int
}

///|
pub(all) struct EndingBracket {
  number : Int
  start_measure : MeasureIndex
  end_measure : MeasureIndex
  kind : EndingKind
}

///|
pub(all) struct CodaMark {
  measure : MeasureIndex
}

///|
pub(all) struct SegnoMark {
  measure : MeasureIndex
}

// --- 构造器 ---

///|
pub fn score_id_checked(value : String) -> Result[ScoreId, ScoreError] {
  if value == "" {
    return Err(InvalidId("Score ID 不能为空"))
  }
  Ok({ value, })
}

///|
pub fn part_id_checked(value : String) -> Result[PartId, ScoreError] {
  if value == "" {
    return Err(InvalidId("Part ID 不能为空"))
  }
  Ok({ value, })
}

///|
pub fn staff_id_checked(value : String) -> Result[StaffId, ScoreError] {
  if value == "" {
    return Err(InvalidId("Staff ID 不能为空"))
  }
  Ok({ value, })
}

///|
pub fn voice_id_checked(value : String) -> Result[VoiceId, ScoreError] {
  if value == "" {
    return Err(InvalidId("Voice ID 不能为空"))
  }
  Ok({ value, })
}

///|
pub fn event_id_checked(value : String) -> Result[EventId, ScoreError] {
  if value == "" {
    return Err(InvalidId("Event ID 不能为空"))
  }
  Ok({ value, })
}

///|
pub fn measure_index_checked(value : Int) -> Result[MeasureIndex, ScoreError] {
  if value < 0 {
    return Err(InvalidMeasure("小节索引必须 >= 0，当前：\{value}"))
  }
  Ok({ value, })
}

///|
pub fn score_path_checked(
  part : Int,
  staff : Int,
  voice : Int,
  measure : Int,
  event : Int,
) -> Result[ScorePath, ScoreError] {
  if part < 0 {
    return Err(InvalidScorePath("part 必须 >= 0，当前：\{part}"))
  }
  if staff < 0 {
    return Err(InvalidScorePath("staff 必须 >= 0，当前：\{staff}"))
  }
  if voice < 0 {
    return Err(InvalidScorePath("voice 必须 >= 0，当前：\{voice}"))
  }
  if measure < 0 {
    return Err(InvalidScorePath("measure 必须 >= 0，当前：\{measure}"))
  }
  if event < 0 {
    return Err(InvalidScorePath("event 必须 >= 0，当前：\{event}"))
  }
  Ok({ part, staff, voice, measure, event })
}

///|
pub fn score_metadata_checked(
  copyright : String,
  lyricist : String,
  arranger : String,
  source : String,
  tags : Array[String],
) -> Result[ScoreMetadata, ScoreError] {
  Ok({ copyright, lyricist, arranger, source, tags })
}

///|
pub fn part_checked(
  id : PartId,
  name : String,
  abbreviation : String,
  staves : Array[Staff],
) -> Result[Part, ScoreError] {
  if name == "" {
    return Err(InvalidPart("Part 名称不能为空"))
  }
  Ok({ id, name, abbreviation, staves })
}

///|
pub fn staff_checked(
  id : StaffId,
  name : String,
  clef : Clef,
  channel : MidiChannel?,
  program : MidiProgram?,
  voices : Array[Voice],
) -> Result[Staff, ScoreError] {
  if name == "" {
    return Err(InvalidStaff("Staff 名称不能为空"))
  }
  Ok({ id, name, clef, channel, program, voices })
}

///|
pub fn voice_checked(
  id : VoiceId,
  name : String,
  measures : Array[Measure],
) -> Result[Voice, ScoreError] {
  if name == "" {
    return Err(InvalidVoice("Voice 名称不能为空"))
  }
  Ok({ id, name, measures })
}

///|
pub fn measure_checked(
  index : MeasureIndex,
  role : MeasureRole,
  time_signature : @time.TimeSignature?,
  key_signature : KeySignature?,
  tempo : Tempo?,
  events : Array[ScoreEvent],
  barline : Barline?,
) -> Result[Measure, ScoreError] {
  Ok({ index, role, time_signature, key_signature, tempo, events, barline })
}

///|
pub fn score_layout_checked(
  id : ScoreId,
  title : String,
  composer : String,
  ppq : PPQ,
  initial_tempo : Tempo,
  initial_signature : @time.TimeSignature,
  parts : Array[Part],
  sections : Array[Section],
  repeats : Array[RepeatMark],
  endings : Array[EndingBracket],
  codas : Array[CodaMark],
  segnos : Array[SegnoMark],
  metadata : ScoreMetadata,
) -> Result[ScoreLayout, ScoreError] {
  Ok({
    id,
    title,
    composer,
    ppq,
    initial_tempo,
    initial_signature,
    parts,
    sections,
    repeats,
    endings,
    codas,
    segnos,
    metadata,
  })
}

///|
pub fn section_checked(
  name : String,
  kind : SectionKind,
  start_measure : MeasureIndex,
  end_measure : MeasureIndex,
) -> Result[Section, ScoreError] {
  if name == "" {
    return Err(InvalidSection("Section 名称不能为空"))
  }
  if end_measure.value < start_measure.value {
    return Err(InvalidSection("end_measure 必须 >= start_measure"))
  }
  Ok({ name, kind, start_measure, end_measure })
}

///|
pub fn repeat_mark_checked(
  kind : RepeatKind,
  measure : MeasureIndex,
  target_measure : MeasureIndex?,
  repeat_count : Int,
) -> Result[RepeatMark, ScoreError] {
  if repeat_count < 1 {
    return Err(
      InvalidRepeat("repeat_count 必须 >= 1，当前：\{repeat_count}"),
    )
  }
  Ok({ kind, measure, target_measure, repeat_count })
}

///|
pub fn ending_bracket_checked(
  number : Int,
  start_measure : MeasureIndex,
  end_measure : MeasureIndex,
  kind : EndingKind,
) -> Result[EndingBracket, ScoreError] {
  if number < 1 {
    return Err(InvalidEnding("ending number 必须 >= 1，当前：\{number}"))
  }
  Ok({ number, start_measure, end_measure, kind })
}
