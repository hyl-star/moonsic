///|
pub fn generate_phrase_checked(
  context : GenerationContext,
  config : GenerationConfig,
) -> Result[GeneratedPhrase, GenerateError] {
  let track = match config.mode {
    MelodyOnly => {
      let rhythm = @rhythm.rhythm_template(@rhythm.FourQuarters)
      match generate_melody_checked(context.key, rhythm, config) {
        Ok(value) => value
        Err(e) => return Err(e)
      }
    }
    ChordsOnly => {
      if context.progression.length() == 0 {
        return Err(EmptyProgression("context.progression must not be empty"))
      }
      match
        generate_chord_progression_checked(
          context.key,
          context.progression,
          @time.rhythm_duration(@time.DurQuarter, 0, None),
          config,
        ) {
        Ok(value) => value
        Err(e) => return Err(e)
      }
    }
    _ => return Err(UnsupportedGenerateMode("mode not implemented in v2 MVP"))
  }
  let degrees = contour_degrees(config.contour)
  Ok({
    track,
    start_degree: degrees[0],
    end_degree: degrees[degrees.length() - 1],
    total_beats: simple_track_total_beats(track),
  })
}

///|
pub fn generated_phrase_to_score_checked(
  phrase : GeneratedPhrase,
  tempo : @score.Tempo,
  signature : @time.TimeSignature,
) -> Result[@score.SimpleScore, GenerateError] {
  match @score.simple_score_checked([phrase.track], tempo, signature) {
    Ok(value) => Ok(value)
    Err(e) => Err(GenerationFailed(e.to_string()))
  }
}

///|
fn simple_track_total_beats(track : @score.SimpleTrack) -> Double {
  let mut total = 0.0
  for event in track.events {
    let duration = match event {
      @score.Note(note) => note.duration
      @score.Rest(rest) => rest.duration
      @score.Chord(chord) => chord.duration
    }
    total = total +
      @time.rational_to_double(@time.rhythm_duration_to_fraction(duration))
  }
  total
}
