//
// TimeError — v2 time 包独立错误类型
//

///|
/// 节奏与时间模块的统一错误类型
pub(all) enum TimeError {
  InvalidRational(String)
  InvalidTimeSignature(String)
  InvalidDuration(String)
  InvalidTempo(String)
  InvalidPPQ(String)
  InvalidTick(String)
  TimeParseError(String)
  NonIntegralTick(String)
  TimeUnsupported(String)
}

///|
/// 转为可读的错误消息（中文）
pub fn TimeError::to_string(self : TimeError) -> String {
  match self {
    InvalidRational(msg) => "无效有理数：\{msg}"
    InvalidTimeSignature(msg) => "无效拍号：\{msg}"
    InvalidDuration(msg) => "无效时值：\{msg}"
    InvalidTempo(msg) => "无效速度：\{msg}"
    InvalidPPQ(msg) => "无效 PPQ：\{msg}"
    InvalidTick(msg) => "无效 tick：\{msg}"
    TimeParseError(msg) => "解析错误：\{msg}"
    NonIntegralTick(msg) => "非整数 tick：\{msg}"
    TimeUnsupported(msg) => "不支持：\{msg}"
  }
}
