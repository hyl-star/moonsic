//
// HarmonyError — v2 harmony 包独立错误类型
//

///|
/// Harmony 模块的错误类型（v2 独立于 TheoryError）
pub(all) enum HarmonyError {
  InvalidRoman(String)
  InvalidProgression(String)
  InvalidVoiceLeading(String)
  EmptyProgression(String)
}

///|
/// 转为可读的错误消息
pub fn HarmonyError::to_string(self : HarmonyError) -> String {
  match self {
    InvalidRoman(msg) => "无效罗马数字：\{msg}"
    InvalidProgression(msg) => "无效和声进行：\{msg}"
    InvalidVoiceLeading(msg) => "无效声部引导：\{msg}"
    EmptyProgression(msg) => "空进行：\{msg}"
  }
}
