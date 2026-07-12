///|
pub(all) enum IntervalError {
  InvalidInterval(String)
}

///|
pub fn IntervalError::to_string(self : IntervalError) -> String {
  match self {
    InvalidInterval(msg) => "invalid interval: \{msg}"
  }
}
