///|
pub const DRUM_CHANNEL : Int = 9

///|
pub const KICK : Int = 36

///|
pub const SNARE : Int = 38

///|
pub const CLOSED_HAT : Int = 42

///|
pub const OPEN_HAT : Int = 46

///|
pub const CLAP : Int = 39

///|
pub fn drum_note_checked(
  midi_note : Int,
  duration : @time.RhythmDuration,
  velocity_value : Int,
) -> Result[@score.SimpleEvent, DrumError] {
  if midi_note < @pitch.MIN_MIDI_NOTE || midi_note > @pitch.MAX_MIDI_NOTE {
    return Err(InvalidDrumNote(midi_note))
  }
  let velocity = match @score.velocity_checked(velocity_value) {
    Ok(result) => result
    Err(_) => return Err(InvalidDrumVelocity(velocity_value))
  }
  let pitch = match @pitch.midi_to_pitch_checked(midi_note) {
    Ok(result) => result
    Err(_) => return Err(InvalidDrumNote(midi_note))
  }
  match @score.simple_note_checked(pitch, duration, Some(velocity)) {
    Ok(result) => Ok(result)
    Err(e) => Err(DrumScoreError(e.to_string()))
  }
}

///|
pub fn kick_checked(
  duration : @time.RhythmDuration,
) -> Result[@score.SimpleEvent, DrumError] {
  drum_note_checked(KICK, duration, 100)
}

///|
pub fn snare_checked(
  duration : @time.RhythmDuration,
) -> Result[@score.SimpleEvent, DrumError] {
  drum_note_checked(SNARE, duration, 86)
}

///|
pub fn closed_hat_checked(
  duration : @time.RhythmDuration,
) -> Result[@score.SimpleEvent, DrumError] {
  drum_note_checked(CLOSED_HAT, duration, 64)
}

///|
pub fn clap_checked(
  duration : @time.RhythmDuration,
) -> Result[@score.SimpleEvent, DrumError] {
  drum_note_checked(CLAP, duration, 88)
}

///|
pub fn basic_beat_checked(bars : Int) -> Result[@score.SimpleScore, DrumError] {
  if bars <= 0 {
    return Err(InvalidDrumBars(bars))
  }
  let kick_events : Array[@score.SimpleEvent] = []
  let snare_events : Array[@score.SimpleEvent] = []
  let hat_events : Array[@score.SimpleEvent] = []
  for bar = 0; bar < bars; bar = bar + 1 {
    for beat = 0; beat < 4; beat = beat + 1 {
      match closed_hat_checked(eighth()) {
        Ok(event) => hat_events.push(event)
        Err(e) => return Err(e)
      }
      match closed_hat_checked(eighth()) {
        Ok(event) => hat_events.push(event)
        Err(e) => return Err(e)
      }
      if beat == 0 || beat == 2 {
        match kick_checked(quarter()) {
          Ok(event) => kick_events.push(event)
          Err(e) => return Err(e)
        }
        match rest(quarter()) {
          Ok(event) => snare_events.push(event)
          Err(e) => return Err(e)
        }
      } else {
        match rest(quarter()) {
          Ok(event) => kick_events.push(event)
          Err(e) => return Err(e)
        }
        match snare_checked(quarter()) {
          Ok(event) => snare_events.push(event)
          Err(e) => return Err(e)
        }
      }
    }
  }
  let channel = match @score.midi_channel_checked(DRUM_CHANNEL) {
    Ok(result) => result
    Err(e) => return Err(DrumScoreError(e.to_string()))
  }
  let kick_track = match
    @score.simple_track_checked(kick_events, Some(channel), None) {
    Ok(result) => result
    Err(e) => return Err(DrumScoreError(e.to_string()))
  }
  let snare_track = match
    @score.simple_track_checked(snare_events, Some(channel), None) {
    Ok(result) => result
    Err(e) => return Err(DrumScoreError(e.to_string()))
  }
  let hat_track = match
    @score.simple_track_checked(hat_events, Some(channel), None) {
    Ok(result) => result
    Err(e) => return Err(DrumScoreError(e.to_string()))
  }
  match
    @score.simple_score_checked(
      [kick_track, snare_track, hat_track],
      @score.tempo_checked(120).unwrap(),
      @time.time_signature(4, 4),
    ) {
    Ok(result) => Ok(result)
    Err(e) => Err(DrumScoreError(e.to_string()))
  }
}

///|
fn rest(
  duration : @time.RhythmDuration,
) -> Result[@score.SimpleEvent, DrumError] {
  match @score.simple_rest_checked(duration) {
    Ok(result) => Ok(result)
    Err(e) => Err(DrumScoreError(e.to_string()))
  }
}

///|
fn quarter() -> @time.RhythmDuration {
  @time.rhythm_duration(@time.DurQuarter, 0, None)
}

///|
fn eighth() -> @time.RhythmDuration {
  @time.rhythm_duration(@time.DurEighth, 0, None)
}
