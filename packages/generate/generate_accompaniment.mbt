///|
pub fn generate_accompaniment_checked(
  context : GenerationContext,
  pattern : AccompanimentPattern,
  config : GenerationConfig,
) -> Result[@score.SimpleTrack, GenerateError] {
  match pattern {
    RootBass | RootFifthBass | WalkingBass =>
      generate_bass_checked(context, pattern, config)
    BlockChord | Pad =>
      generate_chord_progression_checked(
        context.key,
        context.progression,
        @time.rhythm_duration(@time.DurQuarter, 0, None),
        config,
      )
    ArpeggioUp | ArpeggioDown | ArpeggioUpDown | Alberti =>
      generate_arpeggio_checked(context, pattern, config)
  }
}

///|
fn generate_arpeggio_checked(
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
    let pitches = match chord_pitches_for_degree(context.key, degree) {
      Ok(result) => result
      Err(e) => return Err(e)
    }
    let order = arpeggio_order(pattern, pitches.length())
    for index in order {
      let pitch = clamp_to_range(
        pitches[index],
        config.range_low,
        config.range_high,
      )
      match
        push_note(
          events,
          pitch,
          @time.rhythm_duration(@time.DurEighth, 0, None),
          84,
        ) {
        Ok(_) => ()
        Err(e) => return Err(e)
      }
    }
  }
  match @score.simple_track_checked(events, None, None) {
    Ok(result) => Ok(result)
    Err(e) => Err(GenerationFailed(e.to_string()))
  }
}

///|
fn chord_pitches_for_degree(
  key : @scale.Key,
  degree : Int,
) -> Result[Array[@pitch.Pitch], GenerateError] {
  let root = match key.key_degree_checked(degree, 4) {
    Ok(result) => result
    Err(e) => return Err(InvalidDegree(e.to_string()))
  }
  let roman = match degree_to_roman(degree) {
    Some(result) => result
    None => return Err(InvalidDegree("degree must be 1-7, got \{degree}"))
  }
  let quality = @harmony.roman_chord_quality(key.scale_kind(), roman)
  Ok(@chord.chord_pitches(root, quality))
}

///|
fn arpeggio_order(
  pattern : AccompanimentPattern,
  pitch_count : Int,
) -> Array[Int] {
  if pitch_count <= 0 {
    return []
  }
  match pattern {
    ArpeggioDown => reverse_index_order(pitch_count)
    ArpeggioUpDown => {
      let order = index_order(pitch_count)
      if pitch_count > 2 {
        for i = pitch_count - 2; i > 0; i = i - 1 {
          order.push(i)
        }
      }
      order
    }
    Alberti =>
      if pitch_count >= 3 {
        [0, 2, 1, 2]
      } else {
        index_order(pitch_count)
      }
    _ => index_order(pitch_count)
  }
}

///|
fn index_order(count : Int) -> Array[Int] {
  let order : Array[Int] = []
  for i = 0; i < count; i = i + 1 {
    order.push(i)
  }
  order
}

///|
fn reverse_index_order(count : Int) -> Array[Int] {
  let order : Array[Int] = []
  for i = count - 1; i >= 0; i = i - 1 {
    order.push(i)
  }
  order
}
