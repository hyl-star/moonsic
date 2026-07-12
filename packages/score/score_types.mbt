// ============================================================
// Score 标识与枚举类型
// ============================================================

// --- 标识类型 ---

///|
pub(all) struct ScoreId {
  value : String
}

///|
pub(all) struct PartId {
  value : String
}

///|
pub(all) struct StaffId {
  value : String
}

///|
pub(all) struct VoiceId {
  value : String
}

///|
pub(all) struct EventId {
  value : String
}

///|
pub(all) struct MeasureIndex {
  value : Int
}

///|
pub(all) struct ScorePath {
  part : Int
  staff : Int
  voice : Int
  measure : Int
  event : Int
}

// --- Music types ---

///|
pub(all) struct Tempo {
  bpm : Int
}

///|
pub(all) struct PPQ {
  value : Int
}

///|
pub(all) struct Velocity {
  value : Int
}

///|
pub(all) struct MidiChannel {
  value : Int
}

///|
pub(all) struct MidiProgram {
  value : Int
}

///|
pub(all) struct KeySignature {
  fifths : Int
}

// --- 枚举类型 ---

///|
pub(all) enum Clef {
  Treble
  Bass
  Alto
  Tenor
  Percussion
}

///|
pub(all) enum Barline {
  RegularBarline
  DoubleBarline
  FinalBarline
  RepeatStartBarline
  RepeatEndBarline
  RepeatBothBarline
}

///|
pub(all) enum MeasureRole {
  NormalMeasure
  PickupMeasure
  FinalMeasure
  CadenzaMeasure
  FreeTimeMeasure
}

///|
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
pub(all) enum RepeatJumpKind {
  DC
  DCAlFine
  DCAlCoda
  DS
  DSAlFine
  DSAlCoda
}

///|
pub(all) enum EndingKind {
  FirstEnding
  SecondEnding
  ThirdEnding
  CustomEnding(Int)
  OpenEnding
  ClosedEnding
}

///|
pub(all) enum NotationPlacement {
  Above
  Below
}

///|
pub(all) enum ArticulationKind {
  Staccato
  Accent
  Tenuto
}

///|
pub(all) enum DynamicMark {
  Pianissimo
  Piano
  MezzoPiano
  MezzoForte
  Forte
  Fortissimo
}

///|
pub(all) enum NotationKind {
  Articulation(ArticulationKind)
  SlurStart
  SlurStop
  TieNotationStart
  TieNotationStop
  Dynamic(DynamicMark)
  Fermata
  Breath
  TextAnnotation(String)
}

///|
pub(all) struct Notation {
  kind : NotationKind
  placement : NotationPlacement
}

///|
pub(all) enum LyricSyllableKind {
  Single
  Begin
  Middle
  End
  Melisma
}

///|
pub(all) struct Lyric {
  text : String
  verse : Int
  syllable : LyricSyllableKind
}

///|
pub(all) enum TieKind {
  NoTie
  TieStart
  TieContinue
  TieStop
  TieStartStop
}

///|
pub(all) enum DirectionKind {
  DynamicsDir
  TempoDir
  WordsDir
  RepeatDir
}

///|
pub(all) struct ScoreMetadata {
  copyright : String
  lyricist : String
  arranger : String
  source : String
  tags : Array[String]
}
