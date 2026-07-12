// ============================================================
// SimpleScore -> MusicXmlScore conversion
// ============================================================

///|
fn pitch_class_to_step(pc : @pitch.PitchClass) -> String {
  pc.to_string()
}

///|
fn accidental_to_alter(acc : @pitch.Accidental) -> Int {
  acc.semitone_offset()
}

///|
fn duration_to_ticks(d : @time.RhythmDuration, divisions : Int) -> Int {
  match @time.rhythm_duration_to_ticks(d, divisions) {
    Ok(t) => t
    Err(_) => divisions
  }
}

///|
fn count_dots_rhythm(d : @time.RhythmDuration) -> Int {
  d.dots
}

///|
fn duration_to_note_type(d : @time.RhythmDuration) -> MusicXmlNoteType {
  match d.unit {
    @time.DurWhole => WholeT
    @time.DurHalf => HalfT
    @time.DurQuarter => QuarterT
    @time.DurEighth => EighthT
    @time.DurSixteenth => SixteenthT
    @time.ThirtySecond => ThirtySecondT
    @time.SixtyFourth => SixtyFourthT
    @time.OneTwentyEighth => OneTwentyEighthT
  }
}

///|
fn note_type_to_xml(nt : MusicXmlNoteType) -> String {
  match nt {
    WholeT => "whole"
    HalfT => "half"
    QuarterT => "quarter"
    EighthT => "eighth"
    SixteenthT => "16th"
    ThirtySecondT => "32nd"
    SixtyFourthT => "64th"
    OneTwentyEighthT => "128th"
  }
}

///|
fn event_to_xml_notes(
  evt : @score.SimpleEvent,
  divisions : Int,
  voice : Int,
) -> Array[MusicXmlNote] {
  match evt {
    @score.Note(n) => {
      let p = n.pitch
      let mp = MusicXmlPitch::{
        step: pitch_class_to_step(p.pitch_class()),
        alter: accidental_to_alter(p.accidental()),
        octave: p.octave(),
      }
      let dur_ticks = duration_to_ticks(n.duration, divisions)
      let ntype = duration_to_note_type(n.duration)
      let dots = count_dots_rhythm(n.duration)
      [
        MusicXmlNote::{
          pitch: Some(mp),
          duration: dur_ticks,
          note_type: ntype,
          dots,
          is_rest: false,
          is_chord_tone: false,
          voice,
          staff: 1,
        },
      ]
    }
    @score.Rest(r) => {
      let dur_ticks = duration_to_ticks(r.duration, divisions)
      let ntype = duration_to_note_type(r.duration)
      let dots = count_dots_rhythm(r.duration)
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
        },
      ]
    }
    @score.Chord(c) => {
      let notes : Array[MusicXmlNote] = []
      let dur_ticks = duration_to_ticks(c.duration, divisions)
      let ntype = duration_to_note_type(c.duration)
      let dots = count_dots_rhythm(c.duration)
      for i = 0; i < c.pitches.length(); i = i + 1 {
        let p = c.pitches[i]
        let mp = MusicXmlPitch::{
          step: pitch_class_to_step(p.pitch_class()),
          alter: accidental_to_alter(p.accidental()),
          octave: p.octave(),
        }
        notes.push(MusicXmlNote::{
          pitch: Some(mp),
          duration: dur_ticks,
          note_type: ntype,
          dots,
          is_rest: false,
          is_chord_tone: i > 0,
          voice,
          staff: 1,
        })
      }
      notes
    }
  }
}

///|
fn group_events_to_measures(
  events : Array[@score.SimpleEvent],
  sig : @time.TimeSignature,
  divisions : Int,
  voice : Int,
) -> Array[MusicXmlMeasure] {
  let cap = sig.numerator * 4 * divisions / sig.denominator
  if cap <= 0 {
    return []
  }
  let measures : Array[MusicXmlMeasure] = []
  let mut current_tick = 0
  let mut measure_number = 1
  let mut current_notes : Array[MusicXmlNote] = []
  for i = 0; i < events.length(); i = i + 1 {
    let evt = events[i]
    let evt_ticks = evt_duration_ticks(evt, divisions)
    if current_tick + evt_ticks <= cap || current_notes.length() == 0 {
      let notes = event_to_xml_notes(evt, divisions, voice)
      for n in notes {
        current_notes.push(n)
      }
      current_tick = current_tick + evt_ticks
    } else {
      measures.push(
        make_xml_measure(measure_number, current_notes, sig, divisions),
      )
      measure_number = measure_number + 1
      current_notes = []
      current_tick = 0
      let notes = event_to_xml_notes(evt, divisions, voice)
      for n in notes {
        current_notes.push(n)
      }
      current_tick = evt_ticks
    }
  }
  if current_notes.length() > 0 {
    measures.push(
      make_xml_measure(measure_number, current_notes, sig, divisions),
    )
  }
  if measures.length() == 0 {
    measures.push(make_xml_measure(1, [], sig, divisions))
  }
  measures
}

///|
fn evt_duration_ticks(evt : @score.SimpleEvent, divisions : Int) -> Int {
  match evt {
    @score.Note(n) => duration_to_ticks(n.duration, divisions)
    @score.Rest(r) => duration_to_ticks(r.duration, divisions)
    @score.Chord(c) => duration_to_ticks(c.duration, divisions)
  }
}

///|
fn make_xml_measure(
  number : Int,
  notes : Array[MusicXmlNote],
  sig : @time.TimeSignature,
  divisions : Int,
) -> MusicXmlMeasure {
  let attrs = if number == 1 {
    Some(MusicXmlAttributes::{ divisions, time_signature: sig })
  } else {
    None
  }
  MusicXmlMeasure::{ number, attributes: attrs, notes }
}

///|
pub fn simple_score_to_musicxml_checked(
  score : @score.SimpleScore,
  options : MusicXmlExportOptions,
) -> Result[MusicXmlScore, MusicXmlError] {
  if options.divisions <= 0 {
    return Err(InvalidMusicXmlOptions("divisions must be > 0"))
  }
  let parts : Array[MusicXmlPart] = []
  for i = 0; i < score.tracks.length(); i = i + 1 {
    let t = score.tracks[i]
    let events = t.events
    let measures = group_events_to_measures(
      events,
      score.time_signature,
      options.divisions,
      1,
    )
    parts.push(MusicXmlPart::{
      id: "P\{i + 1}",
      name: options.part_name_fallback,
      measures,
    })
  }
  Ok(MusicXmlScore::{ title: "", parts, divisions: options.divisions })
}
