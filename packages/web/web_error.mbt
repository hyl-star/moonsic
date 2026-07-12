///|
pub(all) enum WebError {
  InvalidTempo(Int)
  InvalidPpq(Int)
  InvalidMidiNote(String)
  InvalidVelocity(String)
  InvalidChannel(String)
  InvalidEvent(String)
}

///|
pub fn WebError::to_string(self : WebError) -> String {
  match self {
    InvalidTempo(v) => "invalid tempo BPM: \{v}, must be > 0"
    InvalidPpq(v) => "invalid PPQ: \{v}, must be > 0"
    InvalidMidiNote(msg) => "invalid MIDI note: \{msg}"
    InvalidVelocity(msg) => "invalid velocity: \{msg}"
    InvalidChannel(msg) => "invalid channel: \{msg}"
    InvalidEvent(msg) => "invalid event: \{msg}"
  }
}
