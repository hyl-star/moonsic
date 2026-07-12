///|
pub(all) enum TimelineError {
  InvalidBpm(Int)
  InvalidPpq(Int)
  InvalidPitch(String)
  InvalidDuration(String)
  InvalidTimeline(String)
}

///|
pub fn TimelineError::to_string(self : TimelineError) -> String {
  match self {
    InvalidBpm(v) => "invalid BPM: \{v}"
    InvalidPpq(v) => "invalid PPQ: \{v}"
    InvalidPitch(msg) => "invalid pitch: \{msg}"
    InvalidDuration(msg) => "invalid duration: \{msg}"
    InvalidTimeline(msg) => "invalid timeline: \{msg}"
  }
}
