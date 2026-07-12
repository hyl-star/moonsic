// ============================================================
// ScoreEvent — 专业曲谱事件层
// ============================================================

// --- NoteEvent / RestEvent / ChordEvent ---

///|
pub(all) struct NoteEvent {
  id : EventId
  pitch : @pitch.Pitch
  duration : @time.RhythmDuration
  velocity : Velocity?
  tie : TieKind
  notations : Array[Notation]
  lyrics : Array[Lyric]
}

///|
pub(all) struct RestEvent {
  id : EventId
  duration : @time.RhythmDuration
  visible : Bool
}

///|
pub(all) struct ChordEvent {
  id : EventId
  pitches : Array[@pitch.Pitch]
  duration : @time.RhythmDuration
  velocity : Velocity?
  tie : TieKind
  notations : Array[Notation]
  lyrics : Array[Lyric]
}

///|
pub(all) struct DirectionEvent {
  id : EventId
  offset : @time.Rational
  direction : DirectionKind
}

///|
pub(all) struct SpacerEvent {
  id : EventId
  duration : @time.RhythmDuration
}

///|
pub(all) enum ScoreEvent {
  Note(NoteEvent)
  Rest(RestEvent)
  Chord(ChordEvent)
  Direction(DirectionEvent)
  Spacer(SpacerEvent)
}

// --- 构造器 ---

///|
pub fn note_event_checked(
  id : EventId,
  pitch : @pitch.Pitch,
  duration : @time.RhythmDuration,
  velocity : Velocity?,
  tie : TieKind,
  notations : Array[Notation],
  lyrics : Array[Lyric],
) -> Result[ScoreEvent, ScoreError] {
  Ok(Note({ id, pitch, duration, velocity, tie, notations, lyrics }))
}

///|
pub fn rest_event_checked(
  id : EventId,
  duration : @time.RhythmDuration,
  visible : Bool,
) -> Result[ScoreEvent, ScoreError] {
  Ok(Rest({ id, duration, visible }))
}

///|
pub fn chord_event_checked(
  id : EventId,
  pitches : Array[@pitch.Pitch],
  duration : @time.RhythmDuration,
  velocity : Velocity?,
  tie : TieKind,
  notations : Array[Notation],
  lyrics : Array[Lyric],
) -> Result[ScoreEvent, ScoreError] {
  if pitches.length() == 0 {
    return Err(InvalidEvent("ChordEvent 必须至少包含一个音高"))
  }
  Ok(Chord({ id, pitches, duration, velocity, tie, notations, lyrics }))
}

///|
pub fn direction_event_checked(
  id : EventId,
  offset : @time.Rational,
  direction : DirectionKind,
) -> Result[ScoreEvent, ScoreError] {
  Ok(Direction({ id, offset, direction }))
}

///|
pub fn spacer_event_checked(
  id : EventId,
  duration : @time.RhythmDuration,
) -> Result[ScoreEvent, ScoreError] {
  Ok(Spacer({ id, duration }))
}

// --- Notation / Lyric 构造器 ---

///|
pub fn notation_checked(
  kind : NotationKind,
  placement : NotationPlacement,
) -> Result[Notation, ScoreError] {
  Ok({ kind, placement })
}

///|
pub fn lyric_checked(
  text : String,
  verse : Int,
  syllable : LyricSyllableKind,
) -> Result[Lyric, ScoreError] {
  if text == "" {
    return Err(InvalidLyric("歌词文本不能为空"))
  }
  Ok({ text, verse, syllable })
}
