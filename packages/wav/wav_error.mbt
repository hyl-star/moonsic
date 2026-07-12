///|
pub(all) enum WavError {
  InvalidSampleRate(Int)
  InvalidGain(Double)
  InvalidDuration(Double)
}

///|
pub fn WavError::to_string(self : WavError) -> String {
  match self {
    InvalidSampleRate(v) => "invalid sample rate: \{v}"
    InvalidGain(v) => "invalid gain: \{v}"
    InvalidDuration(v) => "invalid duration: \{v}"
  }
}
