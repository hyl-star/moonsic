// ============================================================
// DemoError — demo 流水线统一错误类型
// ============================================================

///|
/// demo 流水线错误：区分请求错误、生成失败、无可交付资产、序列化失败
pub(all) enum DemoError {
  /// 请求不可解析或关键字段非法
  InvalidRequest(String)
  /// 生成阶段无法产出任何 track
  GenerationFailed(String)
  /// 无任何可用资产（所有导出均失败）
  NoUsableAsset(String)
  /// 序列化/导出失败
  SerializationFailed(String)
}

///|
pub fn DemoError::to_string(self : DemoError) -> String {
  match self {
    InvalidRequest(msg) => "invalid request: " + msg
    GenerationFailed(msg) => "generation failed: " + msg
    NoUsableAsset(msg) => "no usable asset: " + msg
    SerializationFailed(msg) => "serialization failed: " + msg
  }
}
