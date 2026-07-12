///|
pub(all) enum MotifError {
  EmptyMotif(String)
  InvalidMotif(String)
  InvalidTransform(String)
  InvalidRepeatCount(String)
  MotifScoreError(String)
  MotifTimeError(String)
}

///|
pub fn MotifError::to_string(self : MotifError) -> String {
  match self {
    EmptyMotif(msg) => "empty motif: \{msg}"
    InvalidMotif(msg) => "invalid motif: \{msg}"
    InvalidTransform(msg) => "invalid motif transform: \{msg}"
    InvalidRepeatCount(msg) => "invalid repeat count: \{msg}"
    MotifScoreError(msg) => "motif score error: \{msg}"
    MotifTimeError(msg) => "motif time error: \{msg}"
  }
}
