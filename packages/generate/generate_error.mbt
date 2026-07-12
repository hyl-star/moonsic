///|
pub(all) enum GenerateError {
  InvalidGenerationConfig(String)
  EmptyRhythmPattern(String)
  EmptyProgression(String)
  UnsupportedGenerateMode(String)
  InvalidDegree(String)
  RangeTooSmall(String)
  GenerationFailed(String)
}

///|
pub fn GenerateError::to_string(self : GenerateError) -> String {
  match self {
    InvalidGenerationConfig(msg) => "invalid generation config: \{msg}"
    EmptyRhythmPattern(msg) => "empty rhythm pattern: \{msg}"
    EmptyProgression(msg) => "empty progression: \{msg}"
    UnsupportedGenerateMode(msg) => "unsupported generate mode: \{msg}"
    InvalidDegree(msg) => "invalid degree: \{msg}"
    RangeTooSmall(msg) => "range too small: \{msg}"
    GenerationFailed(msg) => "generation failed: \{msg}"
  }
}
