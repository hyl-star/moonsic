///|
fn validate_score_context(context : ScoreContext) -> Result[Unit, AdapterError] {
  if context.bars <= 0 {
    return Err(InvalidGenerationRequest("bars must be > 0"))
  }
  if context.track_count < 0 {
    return Err(InvalidGenerationRequest("track_count must be >= 0"))
  }
  if context.ppq <= 0 {
    return Err(InvalidGenerationRequest("ppq must be > 0"))
  }
  if context.tempo.bpm <= 0 {
    return Err(InvalidGenerationRequest("tempo bpm must be > 0"))
  }
  if !@time.is_valid_time_signature(
      context.time_signature.numerator,
      context.time_signature.denominator,
    ) {
    return Err(InvalidGenerationRequest("invalid time signature"))
  }
  Ok(())
}

///|
fn validate_constraints(
  constraints : Array[GenerationConstraint],
) -> Result[Unit, AdapterError] {
  let mut min_bars : Int? = None
  let mut max_bars : Int? = None
  for constraint in constraints {
    match constraint {
      MinBars(value) => {
        if value <= 0 {
          return Err(InvalidGenerationConstraint("MinBars must be > 0"))
        }
        min_bars = Some(value)
      }
      MaxBars(value) => {
        if value <= 0 {
          return Err(InvalidGenerationConstraint("MaxBars must be > 0"))
        }
        max_bars = Some(value)
      }
      AllowedScaleDegrees(degrees) => {
        if degrees.length() == 0 {
          return Err(
            InvalidGenerationConstraint("AllowedScaleDegrees cannot be empty"),
          )
        }
        for degree in degrees {
          if degree <= 0 {
            return Err(
              InvalidGenerationConstraint("scale degree must be positive"),
            )
          }
        }
      }
      AllowedPitchRange(low, high) =>
        if low > high {
          return Err(InvalidGenerationConstraint("pitch range low > high"))
        }
      MaxLeap(value) =>
        if value < 0 {
          return Err(InvalidGenerationConstraint("MaxLeap must be >= 0"))
        }
      TargetDensity(value) =>
        if value < 0.0 || value > 1.0 {
          return Err(
            InvalidGenerationConstraint("TargetDensity must be between 0 and 1"),
          )
        }
      RequiredStyle(_) | MustFitTimeSignature | MustLoop => ()
    }
  }
  match (min_bars, max_bars) {
    (Some(minimum), Some(maximum)) =>
      if minimum > maximum {
        return Err(InvalidGenerationConstraint("MinBars exceeds MaxBars"))
      }
    _ => ()
  }
  Ok(())
}

///|
pub fn generation_request_checked(
  id : String,
  task : GenerationTaskKind,
  context : ScoreContext,
  style_tags : Array[GenerationStyleTag],
  constraints : Array[GenerationConstraint],
  deterministic : GenerationDeterminism,
  seed : Int?,
) -> Result[GenerationRequest, AdapterError] {
  if id.length() == 0 {
    return Err(InvalidGenerationRequest("id cannot be empty"))
  }
  match validate_score_context(context) {
    Ok(_) => ()
    Err(e) => return Err(e)
  }
  match validate_constraints(constraints) {
    Ok(_) => ()
    Err(e) => return Err(e)
  }
  Ok({ id, task, context, style_tags, constraints, deterministic, seed })
}

///|
pub fn generation_request_default_checked(
  task : GenerationTaskKind,
  context : ScoreContext,
  constraints : Array[GenerationConstraint],
) -> Result[GenerationRequest, AdapterError] {
  generation_request_checked(
    "req_0000",
    task,
    context,
    [],
    constraints,
    Deterministic,
    None,
  )
}

///|
pub fn generation_provider_info(
  name : String,
  kind : ExternalGeneratorKind,
  capabilities : Array[GenerationCapability],
) -> GenerationProviderInfo {
  { name, kind, capabilities, determinism: kind_default_determinism(kind) }
}

///|
pub fn validate_generation_request(
  request : GenerationRequest,
  provider : GenerationProviderInfo,
) -> Result[Unit, AdapterError] {
  let required = task_to_required_capability(request.task)
  let mut found = false
  for capability in provider.capabilities {
    if capability_eq(capability, required) {
      found = true
      break
    }
  }
  if !found {
    return Err(
      ProviderCapabilityMismatch(
        "provider \{provider.name} lacks \{capability_to_tag(required)}",
      ),
    )
  }
  match validate_score_context(request.context) {
    Ok(_) => validate_constraints(request.constraints)
    Err(e) => Err(e)
  }
}

///|
pub fn score_context_from_simple_score_checked(
  score : @score.SimpleScore,
  ppq : Int,
) -> Result[ScoreContext, AdapterError] {
  if ppq <= 0 {
    return Err(InvalidGenerationRequest("ppq must be > 0"))
  }
  let mut max_beats = 0.0
  for track in score.tracks {
    let mut beats = 0.0
    for event in track.events {
      match simple_event_beats_checked(event) {
        Ok(value) => beats = beats + value
        Err(e) => return Err(e)
      }
    }
    if beats > max_beats {
      max_beats = beats
    }
  }
  let measure_beats = score.time_signature.measure_beats()
  let mut bars = 1
  if measure_beats > 0.0 && max_beats > 0.0 {
    bars = (max_beats / measure_beats).to_int()
    if max_beats > bars.to_double() * measure_beats {
      bars = bars + 1
    }
    if bars <= 0 {
      bars = 1
    }
  }
  let track_count = score.tracks.length()
  Ok({
    score_summary: "SimpleScore with \{track_count} tracks, \{bars} bars",
    key_hint: None,
    time_signature: score.time_signature,
    tempo: score.tempo,
    bars,
    track_count,
    ppq,
  })
}

///|
fn simple_event_beats_checked(
  event : @score.SimpleEvent,
) -> Result[Double, AdapterError] {
  let duration = match event {
    @score.Note(note) => note.duration
    @score.Rest(rest) => rest.duration
    @score.Chord(chord) => chord.duration
  }
  match @time.rhythm_duration_to_fraction_checked(duration) {
    Ok(frac) => Ok(@time.rational_to_double(frac))
    Err(e) => Err(AdapterScoreError(e.to_string()))
  }
}
