// ============================================================
// v3 音乐理论 — 音程、音阶、和弦品质、和弦进行
// ============================================================

// --- 音程 ---

///|
pub const UNISON : Int = 0

///|
pub const MINOR_SECOND : Int = 1

///|
pub const MAJOR_SECOND : Int = 2

///|
pub const MINOR_THIRD : Int = 3

///|
pub const MAJOR_THIRD : Int = 4

///|
pub const PERFECT_FOURTH : Int = 5

///|
pub const TRITONE : Int = 6

///|
pub const PERFECT_FIFTH : Int = 7

///|
pub const MINOR_SIXTH : Int = 8

///|
pub const MAJOR_SIXTH : Int = 9

///|
pub const MINOR_SEVENTH : Int = 10

///|
pub const MAJOR_SEVENTH : Int = 11

///|
pub const OCTAVE : Int = 12

// --- 音阶 ---

///|
pub fn scale(
  root : Pitch,
  kind : ScaleKind,
  octave_count : Int,
) -> Array[Pitch] {
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
pub fn degree(root : Pitch, kind : ScaleKind, deg : Int) -> Pitch {
  let intervals = kind.intervals()
  let octave_offset = (deg - 1) / intervals.length()
  let index = (deg - 1) % intervals.length()
  let base_midi = root.to_midi()
  midi_to_pitch(base_midi + intervals[index] + octave_offset * 12)
}

// --- 和弦品质 ---

///|
pub(all) enum ChordQuality {
  MajorTriad
  MinorTriad
  DiminishedTriad
  AugmentedTriad
  DominantSeventh
  MajorSeventh
  MinorSeventh
}

///|
/// 和弦品质的半音间隔模式
pub fn ChordQuality::intervals(self : ChordQuality) -> Array[Int] {
  match self {
    MajorTriad => [0, 4, 7]
    MinorTriad => [0, 3, 7]
    DiminishedTriad => [0, 3, 6]
    AugmentedTriad => [0, 4, 8]
    DominantSeventh => [0, 4, 7, 10]
    MajorSeventh => [0, 4, 7, 11]
    MinorSeventh => [0, 3, 7, 10]
  }
}

///|
/// 通过和弦品质构建和弦
pub fn chord_quality(
  root : Pitch,
  quality : ChordQuality,
  duration : Duration,
) -> MusicEvent {
  let intervals = quality.intervals()
  let pitches = []
  for i in intervals {
    pitches.push(root.transpose(i))
  }
  Chord(chord(pitches, duration))
}

// --- 罗马数字 ---

///|
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
/// 获取罗马数字在指定调中的根音
fn roman_root(root : Pitch, kind : ScaleKind, rn : RomanNumeral) -> Pitch {
  let deg = match rn {
    I => 1
    II => 2
    III => 3
    IV => 4
    V => 5
    VI => 6
    VII => 7
  }
  degree(root, kind, deg)
}

///|
/// 判断罗马数字在指定调中是大三和弦
fn is_major_in_key(kind : ScaleKind, rn : RomanNumeral) -> Bool {
  match kind {
    Major =>
      match rn {
        I | IV | V => true
        _ => false
      }
    NaturalMinor =>
      match rn {
        III | VI | VII => true
        _ => false
      }
    _ =>
      match rn {
        I | IV | V => true
        _ => false
      }
  }
}

///|
/// 判断罗马数字在指定调中是减三和弦
fn is_dim_in_key(kind : ScaleKind, rn : RomanNumeral) -> Bool {
  match kind {
    Major =>
      match rn {
        VII => true
        _ => false
      }
    NaturalMinor =>
      match rn {
        II => true
        _ => false
      }
    _ => false
  }
}

///|
/// 和弦进行：根据调式自动选择大三/小三/减三和弦
pub fn progression(
  root : Pitch,
  kind : ScaleKind,
  rns : Array[RomanNumeral],
  dur : Duration,
) -> Track {
  let events = []
  for rn in rns {
    let chord_root = roman_root(root, kind, rn)
    let chord_evt = if is_dim_in_key(kind, rn) {
      chord_quality(chord_root, DiminishedTriad, dur)
    } else if is_major_in_key(kind, rn) {
      major(chord_root, dur)
    } else {
      minor(chord_root, dur)
    }
    events.push(chord_evt)
  }
  track(events)
}
