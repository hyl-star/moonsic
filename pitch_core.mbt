//
// 音高核心类型：PitchClass、Accidental、Pitch 及基本运算
//

// --- 常量 ---

///|
/// MIDI 音符范围：0-127
pub const MIN_MIDI_NOTE : Int = 0

///|
pub const MAX_MIDI_NOTE : Int = 127

///|
/// A4 的 MIDI 编号和频率
pub const A4_MIDI : Int = 69

///|
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
/// 变音记号：重降、降、还原、升、重升
pub(all) enum Accidental {
  DoubleFlat
  Flat
  Natural
  Sharp
  DoubleSharp
}

///|
/// 获取变音记号的半音偏移量（重降=-2，降=-1，还原=0，升=+1，重升=+2）
pub fn Accidental::semitone_offset(self : Accidental) -> Int {
  match self {
    DoubleFlat => -2
    Flat => -1
    Natural => 0
    Sharp => 1
    DoubleSharp => 2
  }
}

///|
/// 转为字符串表示（重降="bb", 降="b", 还原="", 升="#", 重升="x"）
pub fn Accidental::to_string(self : Accidental) -> String {
  match self {
    DoubleFlat => "bb"
    Flat => "b"
    Natural => ""
    Sharp => "#"
    DoubleSharp => "x"
  }
}

// --- 音高 Pitch ---

///|
/// 音高 = 音名 + 变音记号 + 八度
pub(all) struct Pitch {
  class : PitchClass
  accidental : Accidental
  octave : Int
}

///|
/// 创建音高
pub fn pitch(
  class : PitchClass,
  accidental : Accidental,
  octave : Int,
) -> Pitch {
  { class, accidental, octave }
}

///|
/// 创建自然音高（无变音记号）
pub fn natural(class : PitchClass, octave : Int) -> Pitch {
  { class, accidental: Natural, octave }
}

///|
/// v1.5 推荐名，等价于 natural()
pub fn natural_pitch(class : PitchClass, octave : Int) -> Pitch {
  { class, accidental: Natural, octave }
}

///|
/// 音高转为 MIDI 音符编号
/// 公式：(octave+1)*12 + base_semitone + accidental_offset
pub fn Pitch::to_midi(self : Pitch) -> Int {
  (self.octave + 1) * 12 +
  self.class.base_semitone() +
  self.accidental.semitone_offset()
}

///|
/// 判断该音高是否在有效 MIDI 范围内（0-127）
pub fn Pitch::is_valid_midi(self : Pitch) -> Bool {
  let midi = self.to_midi()
  midi >= 0 && midi <= 127
}

///|
/// 移调：按半音数移动，使用升号拼写
pub fn Pitch::transpose(self : Pitch, semitones : Int) -> Pitch {
  let midi = self.to_midi() + semitones
  midi_to_pitch(midi)
}

///|
/// 转为字符串，如 "C4", "C#4", "Db4"
pub fn Pitch::to_string(self : Pitch) -> String {
  "\{self.class.to_string()}\{self.accidental.to_string()}\{self.octave}"
}

///|
/// 从 MIDI 编号转为 Pitch（升号拼写）
pub fn midi_to_pitch(midi : Int) -> Pitch {
  let octave = midi / 12 - 1
  let semitone = midi % 12
  let (class, accidental) = match semitone {
    0 => (C, Natural)
    1 => (C, Sharp)
    2 => (D, Natural)
    3 => (D, Sharp)
    4 => (E, Natural)
    5 => (F, Natural)
    6 => (F, Sharp)
    7 => (G, Natural)
    8 => (G, Sharp)
    9 => (A, Natural)
    10 => (A, Sharp)
    11 => (B, Natural)
    _ => (C, Natural)
  }
  { class, accidental, octave }
}

// --- 音高比较 ---

///|
/// 比较两个音高是否拼写完全相同（字母、变音记号、八度均相同）。
/// C#4 与 Db4 虽然等音（MIDI 相同），但拼写不同，返回 false。
pub fn pitch_equal(a : Pitch, b : Pitch) -> Bool {
  let class_eq = match a.class {
    C =>
      match b.class {
        C => true
        _ => false
      }
    D =>
      match b.class {
        D => true
        _ => false
      }
    E =>
      match b.class {
        E => true
        _ => false
      }
    F =>
      match b.class {
        F => true
        _ => false
      }
    G =>
      match b.class {
        G => true
        _ => false
      }
    A =>
      match b.class {
        A => true
        _ => false
      }
    B =>
      match b.class {
        B => true
        _ => false
      }
  }
  let acc_eq = match a.accidental {
    DoubleFlat =>
      match b.accidental {
        DoubleFlat => true
        _ => false
      }
    Flat =>
      match b.accidental {
        Flat => true
        _ => false
      }
    Natural =>
      match b.accidental {
        Natural => true
        _ => false
      }
    Sharp =>
      match b.accidental {
        Sharp => true
        _ => false
      }
    DoubleSharp =>
      match b.accidental {
        DoubleSharp => true
        _ => false
      }
  }
  class_eq && acc_eq && a.octave == b.octave
}

///|
/// 比较两个音高是否等音（MIDI 编号相同，忽略拼写差异）。
/// 例如 C#4 和 Db4 等音，返回 true。
pub fn enharmonic_equal(a : Pitch, b : Pitch) -> Bool {
  a.to_midi() == b.to_midi()
}

///|
/// 按 MIDI 编号比较音高，返回 -1（a<b）、0（相等）、1（a>b）。
pub fn pitch_compare(a : Pitch, b : Pitch) -> Int {
  let a_midi = a.to_midi()
  let b_midi = b.to_midi()
  if a_midi < b_midi {
    -1
  } else if a_midi > b_midi {
    1
  } else {
    0
  }
}

///|
/// 按数值比较 MIDI 编号，返回 -1、0 或 1。
pub fn midi_note_compare(a : Int, b : Int) -> Int {
  if a < b {
    -1
  } else if a > b {
    1
  } else {
    0
  }
}
