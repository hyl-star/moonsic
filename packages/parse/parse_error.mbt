///|
pub(all) enum ParseFacadeError {
  UnsupportedParseKind(String)
  ParseFailed(String)
}

///|
pub fn ParseFacadeError::to_string(self : ParseFacadeError) -> String {
  match self {
    UnsupportedParseKind(kind) => "unsupported parse kind: \{kind}"
    ParseFailed(msg) => "parse failed: \{msg}"
  }
}
