// ============================================================
// v2 音乐理论 — 音程、音阶、和弦进行
// ============================================================

// --- 音程 ---

///|
/// 音程半音数常量
pub const UNISON : Int = 0
pub const MINOR_SECOND : Int = 1
pub const MAJOR_SECOND : Int = 2
pub const MINOR_THIRD : Int = 3
pub const MAJOR_THIRD : Int = 4
pub const PERFECT_FOURTH : Int = 5
pub const TRITONE : Int = 6
pub const PERFECT_FIFTH : Int = 7
pub const MINOR_SIXTH : Int = 8
pub const MAJOR_SIXTH : Int = 9
pub const MINOR_SEVENTH : Int = 10
pub const MAJOR_SEVENTH : Int = 11
pub const OCTAVE : Int = 12

// --- 音阶 ---

///|
/// 音阶种类
pub(all) enum ScaleKind {
  Major
  NaturalMinor
  MajorPentatonic
  MinorPentatonic
}

///|
/// 获取音阶的半音模式
pub fn ScaleKind::intervals(self : ScaleKind) -> Array[Int] {
  match self {
    Major => [0, 2, 4, 5, 7, 9, 11]
    NaturalMinor => [0, 2, 3, 5, 7, 8, 10]
    MajorPentatonic => [0, 2, 4, 7, 9]
    MinorPentatonic => [0, 3, 5, 7, 10]
  }
}

///|
/// 从根音生成音阶，跨指定八度数
pub fn scale(root : Pitch, kind : ScaleKind, octave_count : Int) -> Array[Pitch] {
  let intervals = kind.intervals()
  let base_midi = root.to_midi()
  let pitches = []
  for o = 0; o < octave_count; o = o + 1 {
    for i in intervals {
      let midi = base_midi + i + o * 12
      if midi <= MAX_MIDI_NOTE {
        pitches.push(midi_to_pitch(midi))
      }
    }
  }
  pitches
}

// --- 音级 ---

///|
/// 获取音阶中指定音级的音高（1-based，1=主音）
pub fn degree(root : Pitch, kind : ScaleKind, deg : Int) -> Pitch {
  let intervals = kind.intervals()
  let octave_offset = (deg - 1) / intervals.length()
  let index = (deg - 1) % intervals.length()
  let base_midi = root.to_midi()
  midi_to_pitch(base_midi + intervals[index] + octave_offset * 12)
}

// --- 罗马数字和弦 ---

///|
/// 罗马数字和弦类型
pub(all) enum RomanNumeral {
  I
  II
  III
  IV
  V
  VI
  VII
}

///|
/// 获取罗马数字在指定大调中的根音
fn roman_root(root : Pitch, rn : RomanNumeral) -> Pitch {
  let deg = match rn {
    I => 1
    II => 2
    III => 3
    IV => 4
    V => 5
    VI => 6
    VII => 7
  }
  degree(root, Major, deg)
}

///|
/// 判断罗马数字在大调中是大三还是小三和弦
fn is_major_triad(rn : RomanNumeral) -> Bool {
  match rn {
    I | IV | V => true
    _ => false // II, III, VI, VII → 小三和弦
  }
}

///|
/// 和弦进行：从罗马数字生成和弦事件序列
pub fn progression(
  root : Pitch,
  _kind : ScaleKind,
  rns : Array[RomanNumeral],
  dur : Duration,
) -> Track {
  let events = []
  for rn in rns {
    let chord_root = roman_root(root, rn)
    let chord_evt = if is_major_triad(rn) {
      major(chord_root, dur)
    } else {
      minor(chord_root, dur)
    }
    events.push(chord_evt)
  }
  track(events)
}
