///|
pub(all) enum StructureError {
  EmptyStructure(String)
  InvalidSection(String)
  InvalidArrangement(String)
  StructureScoreError(String)
  StructureTimeError(String)
  InvalidDegree(String)
}

///|
pub fn StructureError::to_string(self : StructureError) -> String {
  match self {
    EmptyStructure(msg) => "empty structure: \{msg}"
    InvalidSection(msg) => "invalid section: \{msg}"
    InvalidArrangement(msg) => "invalid arrangement: \{msg}"
    StructureScoreError(msg) => "score structure error: \{msg}"
    StructureTimeError(msg) => "time structure error: \{msg}"
    InvalidDegree(msg) => "invalid degree: \{msg}"
  }
}
