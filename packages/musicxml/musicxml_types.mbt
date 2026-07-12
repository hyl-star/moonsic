// ============================================================
// MusicXML type definitions
// ============================================================

///|
pub(all) enum MusicXmlNoteType {
  WholeT
  HalfT
  QuarterT
  EighthT
  SixteenthT
  ThirtySecondT
  SixtyFourthT
  OneTwentyEighthT
}

///|
pub(all) struct MusicXmlPitch {
  step : String
  alter : Int
  octave : Int
}

///|
pub(all) struct MusicXmlNote {
  pitch : MusicXmlPitch?
  duration : Int
  note_type : MusicXmlNoteType
  dots : Int
  is_rest : Bool
  is_chord_tone : Bool
  voice : Int
  staff : Int
}

///|
pub(all) struct MusicXmlAttributes {
  divisions : Int
  time_signature : @time.TimeSignature
}

///|
pub(all) struct MusicXmlMeasure {
  number : Int
  attributes : MusicXmlAttributes?
  notes : Array[MusicXmlNote]
}

///|
pub(all) struct MusicXmlPart {
  id : String
  name : String
  measures : Array[MusicXmlMeasure]
}

///|
pub(all) struct MusicXmlScore {
  title : String
  parts : Array[MusicXmlPart]
  divisions : Int
}

///|
pub(all) struct MusicXmlExportOptions {
  divisions : Int
  include_xml_header : Bool
  include_doctype : Bool
  part_name_fallback : String
}

///|
pub fn default_musicxml_export_options() -> MusicXmlExportOptions {
  {
    divisions: 480,
    include_xml_header: true,
    include_doctype: true,
    part_name_fallback: "Instrument",
  }
}
