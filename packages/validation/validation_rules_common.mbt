// ============================================================
// 共享校验规则 — 严重级别映射 + 辅助函数
// ============================================================

///|
pub fn default_severity(code : ValidationCode) -> ValidationSeverity {
  match code {
    EmptyScore
    | EmptyPart
    | EmptyStaff
    | EmptyVoice
    | MeasureOverflow
    | InvalidPPQ
    | InvalidTempo
    | InvalidChannel
    | InvalidProgram
    | InvalidSectionRange
    | InvalidRepeatCount
    | InvalidEndingNumber => Error
    MeasureUnderfilled | VoiceAlignmentMismatch | MeasureIndexOutOfOrder =>
      Warning
    InvalidVelocity | EmptyChordPitches => Error
  }
}

///|
pub fn severity_label(s : ValidationSeverity) -> String {
  match s {
    Info => "Info"
    Warning => "Warning"
    Error => "Error"
    Fatal => "Fatal"
  }
}

///|
pub fn code_label(c : ValidationCode) -> String {
  match c {
    EmptyScore => "EmptyScore"
    EmptyPart => "EmptyPart"
    EmptyStaff => "EmptyStaff"
    EmptyVoice => "EmptyVoice"
    MeasureOverflow => "MeasureOverflow"
    MeasureUnderfilled => "MeasureUnderfilled"
    VoiceAlignmentMismatch => "VoiceAlignmentMismatch"
    MeasureIndexOutOfOrder => "MeasureIndexOutOfOrder"
    InvalidPPQ => "InvalidPPQ"
    InvalidTempo => "InvalidTempo"
    InvalidChannel => "InvalidChannel"
    InvalidProgram => "InvalidProgram"
    InvalidSectionRange => "InvalidSectionRange"
    InvalidRepeatCount => "InvalidRepeatCount"
    InvalidEndingNumber => "InvalidEndingNumber"
    InvalidVelocity => "InvalidVelocity"
    EmptyChordPitches => "EmptyChordPitches"
  }
}

///|
fn make_issue(
  code : ValidationCode,
  path : String,
  message : String,
) -> ValidationIssue {
  { severity: default_severity(code), code, path, message }
}

///|
fn get_measure_beats(
  m : @score.Measure,
  default_sig : @time.TimeSignature,
) -> Double {
  match m.time_signature {
    Some(s) => s.measure_beats()
    None => default_sig.measure_beats()
  }
}
