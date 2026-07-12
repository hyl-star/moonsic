///|
pub fn deterministic_mock_generate(
  request : GenerationRequest,
) -> Result[GenerationResponse, AdapterError] {
  let (events, description, message) = match request.task {
    MelodyContinuation => {
      let built = match melody_events() {
        Ok(result) => result
        Err(e) => return Err(e)
      }
      (
        built, "ascending C major melody", "mock generated a deterministic melody",
      )
    }
    ChordProgression => {
      let built = match chord_progression_events() {
        Ok(result) => result
        Err(e) => return Err(e)
      }
      (
        built, "I-IV-V-I chord progression", "mock generated a deterministic chord progression",
      )
    }
    BassLine => {
      let built = match bass_line_events() {
        Ok(result) => result
        Err(e) => return Err(e)
      }
      (built, "root-note bass line", "mock generated a deterministic bass line")
    }
    AccompanimentTask => {
      let built = match accompaniment_events() {
        Ok(result) => result
        Err(e) => return Err(e)
      }
      (
        built, "block chord accompaniment", "mock generated deterministic accompaniment",
      )
    }
    RhythmPatternGen => {
      let built = match rest_events() {
        Ok(result) => result
        Err(e) => return Err(e)
      }
      (
        built, "empty rhythm placeholder", "mock returned a rhythm placeholder track",
      )
    }
    GameLoopTask => {
      let built = match game_loop_events() {
        Ok(result) => result
        Err(e) => return Err(e)
      }
      (built, "one-bar game loop", "mock generated a deterministic game loop")
    }
    Variation => {
      let built = match variation_events() {
        Ok(result) => result
        Err(e) => return Err(e)
      }
      (
        built, "descending variation", "mock generated a deterministic variation",
      )
    }
    Orchestration => {
      let built = match rest_events() {
        Ok(result) => result
        Err(e) => return Err(e)
      }
      (
        built, "empty orchestration placeholder", "mock returned an orchestration placeholder track",
      )
    }
  }
  let track = match @score.simple_track_checked(events, None, None) {
    Ok(result) => result
    Err(e) => return Err(AdapterScoreError(e.to_string()))
  }
  let fragment = {
    tracks: [track],
    start_bar: 0,
    length_bars: request.context.bars,
  }
  let candidate = { fragment, confidence: 1.0, description }
  Ok({ request_id: request.id, candidates: [candidate], patch: None, message })
}

///|
fn melody_events() -> Result[Array[@score.SimpleEvent], AdapterError] {
  let events : Array[@score.SimpleEvent] = []
  for
    pitch in [
      @pitch.c(4),
      @pitch.d(4),
      @pitch.e(4),
      @pitch.f(4),
      @pitch.g(4),
      @pitch.a(4),
      @pitch.b(4),
      @pitch.c(5),
    ] {
    match note_event(pitch, quarter()) {
      Ok(event) => events.push(event)
      Err(e) => return Err(e)
    }
  }
  Ok(events)
}

///|
fn chord_progression_events() -> Result[Array[@score.SimpleEvent], AdapterError] {
  let events : Array[@score.SimpleEvent] = []
  for
    pitches in [
      [@pitch.c(4), @pitch.e(4), @pitch.g(4)],
      [@pitch.f(4), @pitch.a(4), @pitch.c(5)],
      [@pitch.g(4), @pitch.b(4), @pitch.d(5)],
      [@pitch.c(4), @pitch.e(4), @pitch.g(4)],
    ] {
    match chord_event(pitches, whole()) {
      Ok(event) => events.push(event)
      Err(e) => return Err(e)
    }
  }
  Ok(events)
}

///|
fn bass_line_events() -> Result[Array[@score.SimpleEvent], AdapterError] {
  let events : Array[@score.SimpleEvent] = []
  for
    pitch in [
      @pitch.c(3),
      @pitch.c(3),
      @pitch.f(3),
      @pitch.f(3),
      @pitch.g(3),
      @pitch.g(3),
      @pitch.c(3),
      @pitch.c(3),
    ] {
    match note_event(pitch, quarter()) {
      Ok(event) => events.push(event)
      Err(e) => return Err(e)
    }
  }
  Ok(events)
}

///|
fn accompaniment_events() -> Result[Array[@score.SimpleEvent], AdapterError] {
  let events : Array[@score.SimpleEvent] = []
  for
    pitches in [
      [@pitch.c(4), @pitch.e(4), @pitch.g(4)],
      [@pitch.f(4), @pitch.a(4), @pitch.c(5)],
      [@pitch.g(4), @pitch.b(4), @pitch.d(5)],
      [@pitch.c(4), @pitch.e(4), @pitch.g(4)],
    ] {
    match chord_event(pitches, half()) {
      Ok(event) => events.push(event)
      Err(e) => return Err(e)
    }
  }
  Ok(events)
}

///|
fn game_loop_events() -> Result[Array[@score.SimpleEvent], AdapterError] {
  let events : Array[@score.SimpleEvent] = []
  for
    pitch in [
      @pitch.c(4),
      @pitch.e(4),
      @pitch.g(4),
      @pitch.c(5),
      @pitch.g(4),
      @pitch.e(4),
      @pitch.c(4),
      @pitch.g(3),
    ] {
    match note_event(pitch, eighth()) {
      Ok(event) => events.push(event)
      Err(e) => return Err(e)
    }
  }
  Ok(events)
}

///|
fn variation_events() -> Result[Array[@score.SimpleEvent], AdapterError] {
  let events : Array[@score.SimpleEvent] = []
  for pitch in [@pitch.e(4), @pitch.d(4), @pitch.c(4), @pitch.d(4)] {
    match note_event(pitch, quarter()) {
      Ok(event) => events.push(event)
      Err(e) => return Err(e)
    }
  }
  Ok(events)
}

///|
fn rest_events() -> Result[Array[@score.SimpleEvent], AdapterError] {
  match rest_event(whole()) {
    Ok(event) => Ok([event])
    Err(e) => Err(e)
  }
}

///|
fn note_event(
  pitch : @pitch.Pitch,
  duration : @time.RhythmDuration,
) -> Result[@score.SimpleEvent, AdapterError] {
  let velocity = match @score.velocity_checked(100) {
    Ok(result) => result
    Err(e) => return Err(AdapterScoreError(e.to_string()))
  }
  match @score.simple_note_checked(pitch, duration, Some(velocity)) {
    Ok(result) => Ok(result)
    Err(e) => Err(AdapterScoreError(e.to_string()))
  }
}

///|
fn chord_event(
  pitches : Array[@pitch.Pitch],
  duration : @time.RhythmDuration,
) -> Result[@score.SimpleEvent, AdapterError] {
  let velocity = match @score.velocity_checked(92) {
    Ok(result) => result
    Err(e) => return Err(AdapterScoreError(e.to_string()))
  }
  match @score.simple_chord_checked(pitches, duration, Some(velocity)) {
    Ok(result) => Ok(result)
    Err(e) => Err(AdapterScoreError(e.to_string()))
  }
}

///|
fn rest_event(
  duration : @time.RhythmDuration,
) -> Result[@score.SimpleEvent, AdapterError] {
  match @score.simple_rest_checked(duration) {
    Ok(result) => Ok(result)
    Err(e) => Err(AdapterScoreError(e.to_string()))
  }
}

///|
fn whole() -> @time.RhythmDuration {
  @time.rhythm_duration(@time.DurWhole, 0, None)
}

///|
fn half() -> @time.RhythmDuration {
  @time.rhythm_duration(@time.DurHalf, 0, None)
}

///|
fn quarter() -> @time.RhythmDuration {
  @time.rhythm_duration(@time.DurQuarter, 0, None)
}

///|
fn eighth() -> @time.RhythmDuration {
  @time.rhythm_duration(@time.DurEighth, 0, None)
}
