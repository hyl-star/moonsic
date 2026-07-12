///|
pub fn generate_bass_checked(
  context : GenerationContext,
  pattern : AccompanimentPattern,
  config : GenerationConfig,
) -> Result[@score.SimpleTrack, GenerateError] {
  match validate_config(config) {
    Ok(_) => ()
    Err(e) => return Err(e)
  }
  if context.progression.length() == 0 {
    return Err(EmptyProgression("context.progression must not be empty"))
  }
  let events : Array[@score.SimpleEvent] = []
  for degree in context.progression {
    if degree < 1 || degree > 7 {
      return Err(InvalidDegree("degree must be 1-7, got \{degree}"))
    }
    match pattern {
      RootBass => {
        let root = match bass_degree_pitch(context.key, degree, config) {
          Ok(result) => result
          Err(e) => return Err(e)
        }
        match
          push_note(
            events,
            root,
            @time.rhythm_duration(@time.DurQuarter, 0, None),
            92,
          ) {
          Ok(_) => ()
          Err(e) => return Err(e)
        }
      }
      RootFifthBass => {
        let root = match bass_degree_pitch(context.key, degree, config) {
          Ok(result) => result
          Err(e) => return Err(e)
        }
        let fifth = match
          bass_degree_pitch(context.key, normalize_degree(degree + 4), config) {
          Ok(result) => result
          Err(e) => return Err(e)
        }
        match
          push_note(
            events,
            root,
            @time.rhythm_duration(@time.DurEighth, 0, None),
            92,
          ) {
          Ok(_) => ()
          Err(e) => return Err(e)
        }
        match
          push_note(
            events,
            fifth,
            @time.rhythm_duration(@time.DurEighth, 0, None),
            86,
          ) {
          Ok(_) => ()
          Err(e) => return Err(e)
        }
      }
      WalkingBass =>
        for offset in [0, 1, 2, 3] {
          let pitch = match
            bass_degree_pitch(
              context.key,
              normalize_degree(degree + offset),
              config,
            ) {
            Ok(result) => result
            Err(e) => return Err(e)
          }
          match
            push_note(
              events,
              pitch,
              @time.rhythm_duration(@time.DurEighth, 0, None),
              88,
            ) {
            Ok(_) => ()
            Err(e) => return Err(e)
          }
        }
      _ =>
        return Err(
          GenerationFailed(
            "bass pattern required: RootBass, RootFifthBass, or WalkingBass",
          ),
        )
    }
  }
  match @score.simple_track_checked(events, None, None) {
    Ok(result) => Ok(result)
    Err(e) => Err(GenerationFailed(e.to_string()))
  }
}

///|
fn bass_degree_pitch(
  key : @scale.Key,
  degree : Int,
  config : GenerationConfig,
) -> Result[@pitch.Pitch, GenerateError] {
  let octave = config.range_low.octave()
  let raw = match key.key_degree_checked(degree, octave) {
    Ok(result) => result
    Err(e) => return Err(InvalidDegree(e.to_string()))
  }
  Ok(clamp_to_range(raw, config.range_low, config.range_high))
}

///|
fn normalize_degree(degree : Int) -> Int {
  let mut result = degree
  while result > 7 {
    result = result - 7
  }
  while result <= 0 {
    result = result + 7
  }
  result
}

///|
fn push_note(
  events : Array[@score.SimpleEvent],
  pitch : @pitch.Pitch,
  duration : @time.RhythmDuration,
  velocity_value : Int,
) -> Result[Unit, GenerateError] {
  let velocity = match @score.velocity_checked(velocity_value) {
    Ok(result) => result
    Err(e) => return Err(GenerationFailed(e.to_string()))
  }
  match @score.simple_note_checked(pitch, duration, Some(velocity)) {
    Ok(event) => {
      events.push(event)
      Ok(())
    }
    Err(e) => Err(GenerationFailed(e.to_string()))
  }
}
