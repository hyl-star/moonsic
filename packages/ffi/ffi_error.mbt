///|
pub(all) enum FfiError {
  InvalidFfiJson(String)
  MissingFfiField(String)
  InvalidFfiField(String)
  FfiGenerateError(String)
  FfiExportError(String)
}

///|
pub fn FfiError::to_string(self : FfiError) -> String {
  match self {
    InvalidFfiJson(msg) => "invalid ffi json: \{msg}"
    MissingFfiField(msg) => "missing ffi field: \{msg}"
    InvalidFfiField(msg) => "invalid ffi field: \{msg}"
    FfiGenerateError(msg) => "ffi generate error: \{msg}"
    FfiExportError(msg) => "ffi export error: \{msg}"
  }
}
