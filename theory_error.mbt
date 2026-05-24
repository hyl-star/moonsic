//
// 音乐理论错误类型
//

///|
/// 乐理核心模块的统一错误类型
pub(all) enum TheoryError {
  ParseError(String)
  InvalidPitch(String)
  InvalidInterval(String)
  InvalidScale(String)
  InvalidChord(String)
  MidiOutOfRange(Int)
  Unsupported(String)
}

///|
/// 转为可读的错误消息
pub fn TheoryError::to_string(self : TheoryError) -> String {
  match self {
    ParseError(msg) => "解析错误：\{msg}"
    InvalidPitch(msg) => "无效音高：\{msg}"
    InvalidInterval(msg) => "无效音程：\{msg}"
    InvalidScale(msg) => "无效音阶：\{msg}"
    InvalidChord(msg) => "无效和弦：\{msg}"
    MidiOutOfRange(note) => "MIDI 越界：\{note}"
    Unsupported(msg) => "不支持：\{msg}"
  }
}
