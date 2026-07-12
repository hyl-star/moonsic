// ============================================================
// ValidationError
// ============================================================

///|
pub(all) enum ValidationError {
  InvalidProfile(String)
  InvalidOptions(String)
  InvalidReport(String)
  JsonEncodeError(String)
}

///|
pub fn ValidationError::to_string(self : ValidationError) -> String {
  match self {
    InvalidProfile(msg) => "无效校验档案：\{msg}"
    InvalidOptions(msg) => "无效校验选项：\{msg}"
    InvalidReport(msg) => "无效校验报告：\{msg}"
    JsonEncodeError(msg) => "JSON 编码错误：\{msg}"
  }
}
