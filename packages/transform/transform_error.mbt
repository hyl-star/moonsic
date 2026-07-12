///|
pub(all) enum TransformError {
  InvalidStretchFactor(Double)
  InvalidTranspose(String)
  InvalidVelocity(Int)
  TransformScoreError(String)
  TransformTimeError(String)
}

///|
pub fn TransformError::to_string(self : TransformError) -> String {
  match self {
    InvalidStretchFactor(value) => "invalid stretch factor: \{value}"
    InvalidTranspose(msg) => "invalid transpose: \{msg}"
    InvalidVelocity(value) => "invalid velocity: \{value}"
    TransformScoreError(msg) => "score transform error: \{msg}"
    TransformTimeError(msg) => "time transform error: \{msg}"
  }
}
