//
// ChordError — v2 chord 包独立错误类型
//

///|
/// Chord 模块的错误类型（v2 独立于 TheoryError）
pub(all) enum ChordError {
  InvalidChord(String)
  InvalidChordQuality(String)
  InvalidInversion(String)
  EmptyChord(String)
}

///|
/// 转为可读的错误消息
pub fn ChordError::to_string(self : ChordError) -> String {
  match self {
    InvalidChord(msg) => "无效和弦：\{msg}"
    InvalidChordQuality(msg) => "无效和弦品质：\{msg}"
    InvalidInversion(msg) => "无效转位：\{msg}"
    EmptyChord(msg) => "空和弦：\{msg}"
  }
}
