///|
pub fn generate_chord_progression_checked(
  key : @scale.Key,
  degrees : Array[Int],
  duration : @time.RhythmDuration,
  _config : GenerationConfig,
) -> Result[@score.SimpleTrack, GenerateError] {
  if degrees.length() == 0 {
    return Err(EmptyProgression("degrees must not be empty"))
  }
  let events : Array[@score.SimpleEvent] = []
  for degree in degrees {
    if degree < 1 || degree > 7 {
      return Err(InvalidDegree("degree must be 1-7, got \{degree}"))
    }
    let root = match key.key_degree_checked(degree, 4) {
      Ok(value) => value
      Err(e) => return Err(InvalidDegree(e.to_string()))
    }
    let roman = match degree_to_roman(degree) {
      Some(value) => value
      None => return Err(InvalidDegree("degree must be 1-7, got \{degree}"))
    }
    let quality = @harmony.roman_chord_quality(key.scale_kind(), roman)
    let pitches = @chord.chord_pitches(root, quality)
    match
      @score.simple_chord_checked(
        pitches,
        duration,
        Some(@score.velocity_checked(88).unwrap()),
      ) {
      Ok(event) => events.push(event)
      Err(e) => return Err(GenerationFailed(e.to_string()))
    }
  }
  @score.simple_track_checked(events, None, None).map_err(e => {
    GenerationFailed(e.to_string())
  })
}
