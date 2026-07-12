///|
pub(all) enum AdapterError {
  InvalidGenerationRequest(String)
  InvalidGenerationConstraint(String)
  ProviderCapabilityMismatch(String)
  InvalidGenerationPatch(String)
  PatchTargetNotFound(String)
  PatchConflict(String)
  AdapterJsonError(String)
  AdapterScoreError(String)
  AdapterUnsupported(String)
}

///|
pub fn AdapterError::to_string(self : AdapterError) -> String {
  match self {
    InvalidGenerationRequest(msg) => "invalid generation request: \{msg}"
    InvalidGenerationConstraint(msg) => "invalid generation constraint: \{msg}"
    ProviderCapabilityMismatch(msg) => "provider capability mismatch: \{msg}"
    InvalidGenerationPatch(msg) => "invalid generation patch: \{msg}"
    PatchTargetNotFound(msg) => "patch target not found: \{msg}"
    PatchConflict(msg) => "patch conflict: \{msg}"
    AdapterJsonError(msg) => "adapter json error: \{msg}"
    AdapterScoreError(msg) => "adapter score error: \{msg}"
    AdapterUnsupported(msg) => "unsupported adapter feature: \{msg}"
  }
}
