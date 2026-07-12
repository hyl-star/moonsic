//
// RhythmError — v2 rhythm 包独立错误类型
//

///|
pub(all) enum RhythmError {
  EmptyRhythmPattern(String)
  InvalidRhythmCell(String)
  InvalidPatternLength(String)
  InvalidRepeatCount(String)
  PatternDoesNotFit(String)
  RhythmParseError(String)
  RhythmUnsupported(String)
}

///|
pub fn RhythmError::to_string(self : RhythmError) -> String {
  match self {
    EmptyRhythmPattern(msg) => "空节奏模板：\{msg}"
    InvalidRhythmCell(msg) => "无效节奏单元：\{msg}"
    InvalidPatternLength(msg) => "无效模式长度：\{msg}"
    InvalidRepeatCount(msg) => "无效重复次数：\{msg}"
    PatternDoesNotFit(msg) => "模式不适配：\{msg}"
    RhythmParseError(msg) => "节奏解析错误：\{msg}"
    RhythmUnsupported(msg) => "不支持：\{msg}"
  }
}
