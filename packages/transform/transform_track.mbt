///|
pub fn simple_track_concat(
  left : @score.SimpleTrack,
  right : @score.SimpleTrack,
) -> @score.SimpleTrack {
  let events : Array[@score.SimpleEvent] = []
  for event in left.events {
    events.push(event)
  }
  for event in right.events {
    events.push(event)
  }
  rebuild_track(left, events)
}

///|
pub fn simple_track_reverse(track : @score.SimpleTrack) -> @score.SimpleTrack {
  let events : Array[@score.SimpleEvent] = []
  let count = track.events.length()
  for i = 0; i < count; i = i + 1 {
    events.push(track.events[count - 1 - i])
  }
  rebuild_track(track, events)
}

///|
pub fn simple_track_stretch_checked(
  track : @score.SimpleTrack,
  factor : Double,
) -> Result[@score.SimpleTrack, TransformError] {
  if factor <= 0.0 {
    return Err(InvalidStretchFactor(factor))
  }
  let events : Array[@score.SimpleEvent] = []
  for event in track.events {
    match simple_event_stretch_checked(event, factor) {
      Ok(result) => events.push(result)
      Err(e) => return Err(e)
    }
  }
  Ok(rebuild_track(track, events))
}

///|
pub fn simple_track_transpose_checked(
  track : @score.SimpleTrack,
  semitones : Int,
) -> Result[@score.SimpleTrack, TransformError] {
  let events : Array[@score.SimpleEvent] = []
  for event in track.events {
    match simple_event_transpose_checked(event, semitones) {
      Ok(result) => events.push(result)
      Err(e) => return Err(e)
    }
  }
  Ok(rebuild_track(track, events))
}

///|
pub fn simple_track_up_octave_checked(
  track : @score.SimpleTrack,
) -> Result[@score.SimpleTrack, TransformError] {
  simple_track_transpose_checked(track, 12)
}

///|
pub fn simple_track_down_octave_checked(
  track : @score.SimpleTrack,
) -> Result[@score.SimpleTrack, TransformError] {
  simple_track_transpose_checked(track, -12)
}

///|
pub fn simple_track_map_velocity_checked(
  track : @score.SimpleTrack,
  mapper : (Int) -> Int,
) -> Result[@score.SimpleTrack, TransformError] {
  let events : Array[@score.SimpleEvent] = []
  for event in track.events {
    match simple_event_map_velocity_checked(event, mapper) {
      Ok(result) => events.push(result)
      Err(e) => return Err(e)
    }
  }
  Ok(rebuild_track(track, events))
}

///|
fn rebuild_track(
  template : @score.SimpleTrack,
  events : Array[@score.SimpleEvent],
) -> @score.SimpleTrack {
  {
    events,
    channel: template.channel,
    program: template.program,
    volume: template.volume,
    pan: template.pan,
    mute: template.mute,
  }
}

///|
fn simple_event_stretch_checked(
  event : @score.SimpleEvent,
  factor : Double,
) -> Result[@score.SimpleEvent, TransformError] {
  match event {
    @score.Note(note) => {
      let duration = match stretch_duration_checked(note.duration, factor) {
        Ok(result) => result
        Err(e) => return Err(e)
      }
      match
        @score.simple_note_checked(note.pitch, duration, Some(note.velocity)) {
        Ok(result) => Ok(result)
        Err(e) => Err(TransformScoreError(e.to_string()))
      }
    }
    @score.Rest(rest) => {
      let duration = match stretch_duration_checked(rest.duration, factor) {
        Ok(result) => result
        Err(e) => return Err(e)
      }
      match @score.simple_rest_checked(duration) {
        Ok(result) => Ok(result)
        Err(e) => Err(TransformScoreError(e.to_string()))
      }
    }
    @score.Chord(chord) => {
      let duration = match stretch_duration_checked(chord.duration, factor) {
        Ok(result) => result
        Err(e) => return Err(e)
      }
      match
        @score.simple_chord_checked(
          chord.pitches,
          duration,
          Some(chord.velocity),
        ) {
        Ok(result) => Ok(result)
        Err(e) => Err(TransformScoreError(e.to_string()))
      }
    }
  }
}

///|
fn simple_event_transpose_checked(
  event : @score.SimpleEvent,
  semitones : Int,
) -> Result[@score.SimpleEvent, TransformError] {
  match event {
    @score.Note(note) => {
      let pitch = match note.pitch.transpose_checked(semitones) {
        Ok(result) => result
        Err(e) => return Err(InvalidTranspose(e.to_string()))
      }
      match
        @score.simple_note_checked(pitch, note.duration, Some(note.velocity)) {
        Ok(result) => Ok(result)
        Err(e) => Err(TransformScoreError(e.to_string()))
      }
    }
    @score.Rest(_) => Ok(event)
    @score.Chord(chord) => {
      let pitches : Array[@pitch.Pitch] = []
      for pitch in chord.pitches {
        match pitch.transpose_checked(semitones) {
          Ok(result) => pitches.push(result)
          Err(e) => return Err(InvalidTranspose(e.to_string()))
        }
      }
      match
        @score.simple_chord_checked(
          pitches,
          chord.duration,
          Some(chord.velocity),
        ) {
        Ok(result) => Ok(result)
        Err(e) => Err(TransformScoreError(e.to_string()))
      }
    }
  }
}

///|
fn simple_event_map_velocity_checked(
  event : @score.SimpleEvent,
  mapper : (Int) -> Int,
) -> Result[@score.SimpleEvent, TransformError] {
  match event {
    @score.Note(note) => {
      let velocity = match
        checked_mapped_velocity(note.velocity.value, mapper) {
        Ok(result) => result
        Err(e) => return Err(e)
      }
      match
        @score.simple_note_checked(note.pitch, note.duration, Some(velocity)) {
        Ok(result) => Ok(result)
        Err(e) => Err(TransformScoreError(e.to_string()))
      }
    }
    @score.Rest(_) => Ok(event)
    @score.Chord(chord) => {
      let velocity = match
        checked_mapped_velocity(chord.velocity.value, mapper) {
        Ok(result) => result
        Err(e) => return Err(e)
      }
      match
        @score.simple_chord_checked(
          chord.pitches,
          chord.duration,
          Some(velocity),
        ) {
        Ok(result) => Ok(result)
        Err(e) => Err(TransformScoreError(e.to_string()))
      }
    }
  }
}

///|
fn checked_mapped_velocity(
  value : Int,
  mapper : (Int) -> Int,
) -> Result[@score.Velocity, TransformError] {
  let mapped = mapper(value)
  if mapped < 0 || mapped > 127 {
    return Err(InvalidVelocity(mapped))
  }
  match @score.velocity_checked(mapped) {
    Ok(result) => Ok(result)
    Err(e) => Err(TransformScoreError(e.to_string()))
  }
}

///|
fn stretch_duration_checked(
  duration : @time.RhythmDuration,
  factor : Double,
) -> Result[@time.RhythmDuration, TransformError] {
  let fraction = match @time.rhythm_duration_to_fraction_checked(duration) {
    Ok(result) => result
    Err(e) => return Err(TransformTimeError(e.to_string()))
  }
  let beats = @time.rational_to_double(fraction) * factor
  Ok(duration_from_beats(beats))
}

///|
fn duration_from_beats(beats : Double) -> @time.RhythmDuration {
  if beats >= 3.75 {
    @time.rhythm_duration(@time.DurWhole, 0, None)
  } else if beats >= 2.75 {
    @time.rhythm_duration(@time.DurHalf, 1, None)
  } else if beats >= 1.75 {
    @time.rhythm_duration(@time.DurHalf, 0, None)
  } else if beats >= 1.25 {
    @time.rhythm_duration(@time.DurQuarter, 1, None)
  } else if beats >= 0.75 {
    @time.rhythm_duration(@time.DurQuarter, 0, None)
  } else if beats >= 0.375 {
    @time.rhythm_duration(@time.DurEighth, 0, None)
  } else {
    @time.rhythm_duration(@time.DurSixteenth, 0, None)
  }
}
