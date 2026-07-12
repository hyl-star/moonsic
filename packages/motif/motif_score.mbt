///|
pub fn motif_to_track_checked(
  motif : Motif,
  key : @scale.Key,
  start_octave : Int,
) -> Result[@score.SimpleTrack, MotifError] {
  if motif.events.length() == 0 {
    return Err(EmptyMotif("motif events cannot be empty"))
  }
  let events : Array[@score.SimpleEvent] = []
  for event in motif.events {
    if event.cell.is_rest {
      match @score.simple_rest_checked(event.cell.duration) {
        Ok(rest) => events.push(rest)
        Err(e) => return Err(MotifScoreError(e.to_string()))
      }
    } else {
      let pitch = match key.key_degree_checked(event.degree, start_octave) {
        Ok(result) => result
        Err(e) => return Err(InvalidMotif(e.to_string()))
      }
      let velocity_value = motif_velocity(event.cell)
      let velocity = match @score.velocity_checked(velocity_value) {
        Ok(result) => result
        Err(e) => return Err(MotifScoreError(e.to_string()))
      }
      match
        @score.simple_note_checked(pitch, event.cell.duration, Some(velocity)) {
        Ok(note) => events.push(note)
        Err(e) => return Err(MotifScoreError(e.to_string()))
      }
    }
  }
  match @score.simple_track_checked(events, None, None) {
    Ok(result) => Ok(result)
    Err(e) => Err(MotifScoreError(e.to_string()))
  }
}

///|
pub fn motif_to_track_with_tonic_checked(
  motif : Motif,
  tonic : @pitch.Pitch,
  kind : @scale.ScaleKind,
  start_octave : Int,
) -> Result[@score.SimpleTrack, MotifError] {
  motif_to_track_checked(motif, @scale.key(tonic, kind), start_octave)
}

///|
fn motif_velocity(cell : @rhythm.RhythmCell) -> Int {
  let raw = (100.0 * cell.accent.velocity_multiplier()).to_int()
  if raw < 1 {
    1
  } else if raw > 127 {
    127
  } else {
    raw
  }
}
