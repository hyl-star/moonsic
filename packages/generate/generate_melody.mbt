///|
pub fn generate_melody_checked(
  key : @scale.Key,
  rhythm : @rhythm.RhythmPattern,
  config : GenerationConfig,
) -> Result[@score.SimpleTrack, GenerateError] {
  match validate_config(config) {
    Ok(_) => ()
    Err(e) => return Err(e)
  }
  if rhythm.cells.length() == 0 {
    return Err(EmptyRhythmPattern("rhythm cells must not be empty"))
  }
  let degrees = contour_degrees(config.contour)
  let events : Array[@score.SimpleEvent] = []
  let base_octave = config.range_low.octave()
  for i = 0; i < rhythm.cells.length(); i = i + 1 {
    let cell = rhythm.cells[i]
    if cell.is_rest && config.allow_rests {
      match @score.simple_rest_checked(cell.duration) {
        Ok(event) => events.push(event)
        Err(e) => return Err(GenerationFailed(e.to_string()))
      }
    } else {
      let degree = degrees[i % degrees.length()]
      let raw_pitch = match key.key_degree_checked(degree, base_octave) {
        Ok(value) => value
        Err(e) => return Err(InvalidDegree(e.to_string()))
      }
      let pitch = match config.voice_leading {
        NoVoiceLeading => raw_pitch
        _ => clamp_to_range(raw_pitch, config.range_low, config.range_high)
      }
      match
        @score.simple_note_checked(
          pitch,
          cell.duration,
          Some(rhythm_cell_velocity(cell)),
        ) {
        Ok(event) => events.push(event)
        Err(e) => return Err(GenerationFailed(e.to_string()))
      }
    }
  }
  @score.simple_track_checked(events, None, None).map_err(e => {
    GenerationFailed(e.to_string())
  })
}
