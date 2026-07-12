// ============================================================
// PitchError — v2 pitch 包独立错误类型
// ============================================================

///|
/// Pitch 模块的错误类型（v2 独立于 TheoryError）
pub(all) enum PitchError {
  InvalidPitch(String)
  MidiOutOfRange(Int)
  InvalidFrequency(Double)
}

///|
/// 转为可读的错误消息
pub fn PitchError::to_string(self : PitchError) -> String {
  match self {
    InvalidPitch(msg) => "无效音高：\{msg}"
    MidiOutOfRange(note) => "MIDI 越界：\{note}"
    InvalidFrequency(hz) => "无效频率：\{hz}"
  }
}
