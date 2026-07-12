///|
pub(all) enum GenerateMode {
  MelodyOnly
  ChordsOnly
  BassOnly
  AccompanimentMode
  GameLoopMode
}

///|
pub(all) enum MelodyContour {
  StepwiseUp
  StepwiseDown
  Arch
  InvertedArch
  Wave
  Static
  ChordTone
}

///|
pub(all) enum AccompanimentPattern {
  BlockChord
  ArpeggioUp
  ArpeggioDown
  ArpeggioUpDown
  Alberti
  Pad
  RootBass
  RootFifthBass
  WalkingBass
}

///|
pub(all) enum VoiceLeadingStrategy {
  NoVoiceLeading
  Nearest
  KeepInRange
  Smooth
  ChordToneAnchor
}

///|
pub(all) struct GenerationConfig {
  mode : GenerateMode
  contour : MelodyContour
  range_low : @pitch.Pitch
  range_high : @pitch.Pitch
  seed : Int?
  voice_leading : VoiceLeadingStrategy
  allow_rests : Bool
  max_leap : Int
}

///|
pub(all) struct GenerationContext {
  key : @scale.Key
  progression : Array[Int]
  time_signature : @time.TimeSignature
  tempo : @score.Tempo
  bars : Int
}

///|
pub(all) struct GeneratedPhrase {
  track : @score.SimpleTrack
  start_degree : Int
  end_degree : Int
  total_beats : Double
}

///|
pub fn default_generation_config() -> GenerationConfig {
  {
    mode: MelodyOnly,
    contour: StepwiseUp,
    range_low: @pitch.c(4),
    range_high: @pitch.c(6),
    seed: None,
    voice_leading: KeepInRange,
    allow_rests: false,
    max_leap: 12,
  }
}

///|
fn contour_degrees(contour : MelodyContour) -> Array[Int] {
  match contour {
    StepwiseUp => [1, 2, 3, 4, 5, 6, 7, 8]
    StepwiseDown => [8, 7, 6, 5, 4, 3, 2, 1]
    Arch => [1, 2, 3, 5, 6, 5, 3, 2]
    InvertedArch => [5, 4, 3, 2, 1, 2, 3, 5]
    Wave => [1, 3, 2, 4, 3, 5, 4, 6]
    Static => [1, 1, 1, 1]
    ChordTone => [1, 3, 5, 3, 1]
  }
}

///|
fn degree_to_roman(degree : Int) -> @harmony.RomanNumeral? {
  match degree {
    1 => Some(@harmony.I)
    2 => Some(@harmony.II)
    3 => Some(@harmony.III)
    4 => Some(@harmony.IV)
    5 => Some(@harmony.V)
    6 => Some(@harmony.VI)
    7 => Some(@harmony.VII)
    _ => None
  }
}

///|
fn validate_config(config : GenerationConfig) -> Result[Unit, GenerateError] {
  if config.range_low.to_midi() >= config.range_high.to_midi() {
    return Err(RangeTooSmall("range_low must be below range_high"))
  }
  if config.max_leap < 0 {
    return Err(InvalidGenerationConfig("max_leap must be >= 0"))
  }
  Ok(())
}

///|
fn clamp_to_range(
  pitch : @pitch.Pitch,
  low : @pitch.Pitch,
  high : @pitch.Pitch,
) -> @pitch.Pitch {
  let low_midi = low.to_midi()
  let high_midi = high.to_midi()
  let mut result = pitch
  let mut guard_count = 0
  while result.to_midi() < low_midi && guard_count < 8 {
    match result.transpose_checked(12) {
      Ok(value) => result = value
      Err(_) => return low
    }
    guard_count = guard_count + 1
  }
  while result.to_midi() > high_midi && guard_count < 16 {
    match result.transpose_checked(-12) {
      Ok(value) => result = value
      Err(_) => return high
    }
    guard_count = guard_count + 1
  }
  if result.to_midi() < low_midi {
    low
  } else if result.to_midi() > high_midi {
    high
  } else {
    result
  }
}

///|
fn rhythm_cell_velocity(cell : @rhythm.RhythmCell) -> @score.Velocity {
  let base = (100.0 * cell.accent.velocity_multiplier()).to_int()
  let clamped = if base < 1 { 1 } else if base > 127 { 127 } else { base }
  @score.velocity_checked(clamped).unwrap()
}
