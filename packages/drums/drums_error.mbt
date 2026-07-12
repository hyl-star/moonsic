///|
pub(all) enum DrumError {
  InvalidDrumNote(Int)
  InvalidDrumVelocity(Int)
  InvalidDrumBars(Int)
  DrumScoreError(String)
}

///|
pub fn DrumError::to_string(self : DrumError) -> String {
  match self {
    InvalidDrumNote(value) => "invalid drum note: \{value}"
    InvalidDrumVelocity(value) => "invalid drum velocity: \{value}"
    InvalidDrumBars(value) => "invalid drum bars: \{value}"
    DrumScoreError(msg) => "drum score error: \{msg}"
  }
}
