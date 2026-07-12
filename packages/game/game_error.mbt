///|
pub(all) enum GameMusicError {
  InvalidProjectId(String)
  DuplicateCueId(String)
  MissingCue(String)
  InvalidCue(String)
  EmptyCue(String)
  EmptySegment(String)
  InvalidSegmentDuration(String)
  InvalidLoopRegion(String)
  InvalidTransitionRule(String)
  MissingTransitionTarget(String)
  InvalidParameter(String)
  UnsupportedGameFeature(String)
  TimelineConversionFailed(String)
  ValidationFailed(String)
  SerializationFailed(String)
}

///|
pub fn GameMusicError::to_string(self : GameMusicError) -> String {
  match self {
    InvalidProjectId(msg) => "invalid project id: " + msg
    DuplicateCueId(msg) => "duplicate cue id: " + msg
    MissingCue(msg) => "missing cue: " + msg
    InvalidCue(msg) => "invalid cue: " + msg
    EmptyCue(msg) => "empty cue: " + msg
    EmptySegment(msg) => "empty segment: " + msg
    InvalidSegmentDuration(msg) => "invalid segment duration: " + msg
    InvalidLoopRegion(msg) => "invalid loop region: " + msg
    InvalidTransitionRule(msg) => "invalid transition rule: " + msg
    MissingTransitionTarget(msg) => "missing transition target: " + msg
    InvalidParameter(msg) => "invalid parameter: " + msg
    UnsupportedGameFeature(msg) => "unsupported game feature: " + msg
    TimelineConversionFailed(msg) => "timeline conversion failed: " + msg
    ValidationFailed(msg) => "validation failed: " + msg
    SerializationFailed(msg) => "serialization failed: " + msg
  }
}
