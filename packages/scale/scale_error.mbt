//
// ScaleError — v2 scale/key 包独立错误类型
//

///|
/// Scale/Key 模块的错误类型（v2 独立于 TheoryError）
pub(all) enum ScaleError {
  InvalidScale(String)
  InvalidDegree(String)
}

///|
/// 转为可读的错误消息
pub fn ScaleError::to_string(self : ScaleError) -> String {
  match self {
    InvalidScale(msg) => "无效音阶：\{msg}"
    InvalidDegree(msg) => "无效音级：\{msg}"
  }
}
