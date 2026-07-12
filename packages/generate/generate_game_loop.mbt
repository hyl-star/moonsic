///|
pub fn generate_game_loop_checked(
  context : GenerationContext,
  bars : Int,
  config : GenerationConfig,
) -> Result[@score.SimpleScore, GenerateError] {
  if bars <= 0 {
    return Err(InvalidGenerationConfig("bars must be > 0"))
  }
  let rhythm = match loop_quarter_rhythm_checked(bars, context.time_signature) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let melody = match generate_melody_checked(context.key, rhythm, config) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  let chords = match
    generate_accompaniment_checked(context, BlockChord, config) {
    Ok(result) => result
    Err(e) => return Err(e)
  }
  match
    @score.simple_score_checked(
      [melody, chords],
      context.tempo,
      context.time_signature,
    ) {
    Ok(result) => Ok(result)
    Err(e) => Err(GenerationFailed(e.to_string()))
  }
}

///|
fn loop_quarter_rhythm_checked(
  bars : Int,
  signature : @time.TimeSignature,
) -> Result[@rhythm.RhythmPattern, GenerateError] {
  let beats_per_bar = signature.measure_beats().to_int()
  let cell_count = bars * beats_per_bar
  if cell_count <= 0 {
    return Err(EmptyRhythmPattern("loop rhythm has no cells"))
  }
  let cells : Array[@rhythm.RhythmCell] = []
  for i = 0; i < cell_count; i = i + 1 {
    let accent = if i % beats_per_bar == 0 {
      @rhythm.Strong
    } else {
      @rhythm.NoAccent
    }
    cells.push(
      @rhythm.rhythm_cell(
        @time.rhythm_duration(@time.DurQuarter, 0, None),
        false,
        accent,
        false,
      ),
    )
  }
  match @rhythm.rhythm_pattern_checked(cells) {
    Ok(result) => Ok(result)
    Err(e) => Err(EmptyRhythmPattern(e.to_string()))
  }
}
