// ============================================================
// 核心音乐模型
// ============================================================

// --- 常量 ---

///|
/// 默认 PPQ（每四分音符的 tick 数）
pub const DEFAULT_PPQ : Int = 480

///|
/// 默认力度
pub const DEFAULT_VELOCITY : Int = 100

///|
/// 力度范围：0-127
pub const MIN_VELOCITY : Int = 0
pub const MAX_VELOCITY : Int = 127

///|
/// MIDI 音符范围：0-127
pub const MIN_MIDI_NOTE : Int = 0
pub const MAX_MIDI_NOTE : Int = 127

///|
/// MIDI 通道范围：0-15
pub const MIN_CHANNEL : Int = 0
pub const MAX_CHANNEL : Int = 15

///|
/// A4 的 MIDI 编号和频率
pub const A4_MIDI : Int = 69
pub const A4_FREQ : Double = 440.0

// --- 音高类 PitchClass ---

///|
/// 自然音名，不含变音记号
pub(all) enum PitchClass {
  C
  D
  E
  F
  G
  A
  B
}

///|
/// 获取自然音名的基准半音偏移（C=0, D=2, ..., B=11）
pub fn PitchClass::base_semitone(self : PitchClass) -> Int {
  match self {
    C => 0
    D => 2
    E => 4
    F => 5
    G => 7
    A => 9
    B => 11
  }
}

///|
/// 转为字符串表示
pub fn PitchClass::to_string(self : PitchClass) -> String {
  match self {
    C => "C"
    D => "D"
    E => "E"
    F => "F"
    G => "G"
    A => "A"
    B => "B"
  }
}

// --- 变音记号 Accidental ---

///|
/// 变音记号：升、降、还原
pub(all) enum Accidental {
  Natural
  Sharp
  Flat
}

///|
/// 获取变音记号的半音偏移量（升=+1，降=-1，还原=0）
pub fn Accidental::semitone_offset(self : Accidental) -> Int {
  match self {
    Natural => 0
    Sharp => 1
    Flat => -1
  }
}

///|
/// 转为字符串表示（还原="", 升="#", 降="b"）
pub fn Accidental::to_string(self : Accidental) -> String {
  match self {
    Natural => ""
    Sharp => "#"
    Flat => "b"
  }
}
