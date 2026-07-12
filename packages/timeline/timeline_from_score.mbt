///|
pub fn simple_track_to_note_events_checked(
  track : @score.SimpleTrack,
  fallback_channel : Int,
) -> Result[Array[NoteEvent], TimelineError] {
  let channel = match track.channel {
    Some(value) => value.value
    None => fallback_channel
  }
  let events : Array[NoteEvent] = []
  let mut cursor = 0.0
  for event in track.events {
    match event {
      @score.Note(note) => {
        let duration = match duration_beats_checked(note.duration) {
          Ok(value) => value
          Err(e) => return Err(e)
        }
        if !track.mute {
          let midi_note = match pitch_to_midi_checked(note.pitch) {
            Ok(value) => value
            Err(e) => return Err(e)
          }
          events.push({
            start: cursor,
            duration,
            midi_note,
            velocity: note.velocity.value,
            channel,
          })
        }
        cursor = cursor + duration
      }
      @score.Rest(rest) => {
        let duration = match duration_beats_checked(rest.duration) {
          Ok(value) => value
          Err(e) => return Err(e)
        }
        cursor = cursor + duration
      }
      @score.Chord(chord) => {
        let duration = match duration_beats_checked(chord.duration) {
          Ok(value) => value
          Err(e) => return Err(e)
        }
        if !track.mute {
          for pitch in chord.pitches {
            let midi_note = match pitch_to_midi_checked(pitch) {
              Ok(value) => value
              Err(e) => return Err(e)
            }
            events.push({
              start: cursor,
              duration,
              midi_note,
              velocity: chord.velocity.value,
              channel,
            })
          }
        }
        cursor = cursor + duration
      }
    }
  }
  Ok(sort_note_events(events))
}

///|
pub fn simple_score_to_note_events_checked(
  score : @score.SimpleScore,
) -> Result[Array[NoteEvent], TimelineError] {
  let all : Array[NoteEvent] = []
  for i = 0; i < score.tracks.length(); i = i + 1 {
    let events = match
      simple_track_to_note_events_checked(score.tracks[i], i % 16) {
      Ok(value) => value
      Err(e) => return Err(e)
    }
    for event in events {
      all.push(event)
    }
  }
  Ok(sort_note_events(all))
}

///|
pub fn score_layout_to_note_events_checked(
  layout : @score.ScoreLayout,
) -> Result[Array[NoteEvent], TimelineError] {
  let all : Array[NoteEvent] = []
  let mut fallback_channel = 0
  for part in layout.parts {
    for staff in part.staves {
      let channel = match staff.channel {
        Some(value) => value.value
        None => {
          let value = fallback_channel % 16
          fallback_channel = fallback_channel + 1
          value
        }
      }
      for voice in staff.voices {
        let events = match voice_to_note_events_checked(voice, channel) {
          Ok(value) => value
          Err(e) => return Err(e)
        }
        for event in events {
          all.push(event)
        }
      }
    }
  }
  Ok(sort_note_events(all))
}

///|
fn voice_to_note_events_checked(
  voice : @score.Voice,
  channel : Int,
) -> Result[Array[NoteEvent], TimelineError] {
  let events : Array[NoteEvent] = []
  let mut cursor = 0.0
  for measure in voice.measures {
    for event in measure.events {
      match event {
        @score.Note(note) => {
          let duration = match duration_beats_checked(note.duration) {
            Ok(value) => value
            Err(e) => return Err(e)
          }
          let velocity = match note.velocity {
            Some(value) => value.value
            None => 100
          }
          let midi_note = match pitch_to_midi_checked(note.pitch) {
            Ok(value) => value
            Err(e) => return Err(e)
          }
          events.push({ start: cursor, duration, midi_note, velocity, channel })
          cursor = cursor + duration
        }
        @score.Rest(rest) => {
          let duration = match duration_beats_checked(rest.duration) {
            Ok(value) => value
            Err(e) => return Err(e)
          }
          cursor = cursor + duration
        }
        @score.Chord(chord) => {
          let duration = match duration_beats_checked(chord.duration) {
            Ok(value) => value
            Err(e) => return Err(e)
          }
          let velocity = match chord.velocity {
            Some(value) => value.value
            None => 100
          }
          for pitch in chord.pitches {
            let midi_note = match pitch_to_midi_checked(pitch) {
              Ok(value) => value
              Err(e) => return Err(e)
            }
            events.push({
              start: cursor,
              duration,
              midi_note,
              velocity,
              channel,
            })
          }
          cursor = cursor + duration
        }
        @score.Spacer(spacer) => {
          let duration = match duration_beats_checked(spacer.duration) {
            Ok(value) => value
            Err(e) => return Err(e)
          }
          cursor = cursor + duration
        }
        @score.Direction(_) => ()
      }
    }
  }
  Ok(sort_note_events(events))
}

///|
fn duration_beats_checked(
  duration : @time.RhythmDuration,
) -> Result[Double, TimelineError] {
  match @time.rhythm_duration_to_fraction_checked(duration) {
    Ok(value) => Ok(@time.rational_to_double(value))
    Err(e) => Err(InvalidDuration(e.to_string()))
  }
}

///|
fn pitch_to_midi_checked(pitch : @pitch.Pitch) -> Result[Int, TimelineError] {
  match pitch.to_midi_checked() {
    Ok(value) => Ok(value)
    Err(e) => Err(InvalidPitch(e.to_string()))
  }
}
