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
  HalfDiminished7
  Diminished7
  Suspended2
  Suspended4
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
    HalfDiminished7 => [0, 3, 6, 10]
    Diminished7 => [0, 3, 6, 9]
    Suspended2 => [0, 2, 7]
    Suspended4 => [0, 5, 7]
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

// --- 和弦文本解析 ---

///|
/// 从文本解析和弦。支持 "C"、"Cm"、"Cmaj7"、"Dm7"、"G7"、"F#dim" 等格式。
pub fn parse_chord(input : String) -> Result[Chord, String] {
  if input.length() == 0 {
    return Err("空的和弦字符串")
  }

  // 解析根音字母
  let root_class = match input[0] {
    'C' => C
    'D' => D
    'E' => E
    'F' => F
    'G' => G
    'A' => A
    'B' => B
    _ => return Err("无效根音：\{input}")
  }
  let mut pos = 1

  // 解析可选的变音记号
  let mut accidental = Natural
  if pos < input.length() {
    if input[pos] == '#' {
      accidental = Sharp
      pos = pos + 1
    } else if input[pos] == 'b' {
      accidental = Flat
      pos = pos + 1
    }
  }

  // 解析和弦品质后缀
  let (quality, _end_pos) = parse_chord_quality(input, pos)

  // 构建和弦（使用八度 4 和默认四分音符时值，正确拼写）
  let root = pitch(root_class, accidental, 4)
  let root_midi = root.to_midi()
  let semitone_intervals = quality.intervals()
  let letter_offsets = chord_letter_steps(quality)
  let root_cls = class_index(root_class)
  let pitches = []
  for i = 0; i < semitone_intervals.length(); i = i + 1 {
    let target_midi = root_midi + semitone_intervals[i]
    let expected_class = class_from_index((root_cls + letter_offsets[i]) % 7)
    // 找到使 expected_class 最接近 target_midi 的八度
    let target_octave = target_midi / 12 - 1
    let natural = (target_octave + 1) * 12 + expected_class.base_semitone()
    let mut diff = target_midi - natural
    let mut octave = target_octave
    if diff > 6 {
      octave = target_octave + 1
      diff = target_midi - ((octave + 1) * 12 + expected_class.base_semitone())
    } else if diff < -6 {
      octave = target_octave - 1
      diff = target_midi - ((octave + 1) * 12 + expected_class.base_semitone())
    } else {
      // diff is within -6..6, use current octave
    }
    let acc = match diff {
      -2 => DoubleFlat
      -1 => Flat
      0 => Natural
      1 => Sharp
      2 => DoubleSharp
      _ => Natural
    }
    pitches.push(pitch(expected_class, acc, octave))
  }
  Ok(chord(pitches, Quarter))
}

///|
/// 和弦品质对应的字母步进（在字母空间中的偏移）
fn chord_letter_steps(quality : ChordQuality) -> Array[Int] {
  match quality {
    MajorTriad => [0, 2, 4]
    MinorTriad => [0, 2, 4]
    DiminishedTriad => [0, 2, 4]
    AugmentedTriad => [0, 2, 4]
    DominantSeventh => [0, 2, 4, 6]
    MajorSeventh => [0, 2, 4, 6]
    MinorSeventh => [0, 2, 4, 6]
    HalfDiminished7 => [0, 2, 4, 6]
    Diminished7 => [0, 2, 4, 6]
    Suspended2 => [0, 1, 4]
    Suspended4 => [0, 3, 4]
  }
}

///|
/// 解析和弦品质后缀（内部函数）
fn parse_chord_quality(input : String, pos : Int) -> (ChordQuality, Int) {
  if pos >= input.length() {
    return (MajorTriad, pos)
  }
  // 优先匹配较长的模式
  if match_chord_str(input, pos, "maj7") {
    (MajorSeventh, pos + 4)
  } else if match_chord_str(input, pos, "dim7") {
    (Diminished7, pos + 4)
  } else if match_chord_str(input, pos, "m7b5") {
    (HalfDiminished7, pos + 4)
  } else if match_chord_str(input, pos, "m7") {
    (MinorSeventh, pos + 2)
  } else if match_chord_str(input, pos, "dim") {
    (DiminishedTriad, pos + 3)
  } else if match_chord_str(input, pos, "aug") {
    (AugmentedTriad, pos + 3)
  } else if match_chord_str(input, pos, "m") {
    (MinorTriad, pos + 1)
  } else if match_chord_str(input, pos, "7") {
    (DominantSeventh, pos + 1)
  } else if match_chord_str(input, pos, "sus2") {
    (Suspended2, pos + 4)
  } else if match_chord_str(input, pos, "sus4") {
    (Suspended4, pos + 4)
  } else {
    (MajorTriad, pos)
  }
}

///|
/// 检查字符串从 pos 开始是否匹配 target
fn match_chord_str(s : String, pos : Int, target : String) -> Bool {
  let len = target.length()
  if pos + len > s.length() {
    return false
  }
  let mut i = 0
  while i < len {
    if s[pos + i] != target[i] {
      return false
    }
    i = i + 1
  }
  true
}

///|
/// 返回和弦包含的音级列表（去重，按和弦内顺序）
pub fn chord_tones(chord : Chord) -> Array[PitchClass] {
  let classes = []
  for p in chord.pitches {
    let pc = p.class
    let mut found = false
    let mut i = 0
    while i < classes.length() && found == false {
      if pitch_class_eq(classes[i], pc) {
        found = true
      }
      i = i + 1
    }
    if found == false {
      classes.push(pc)
    }
  }
  classes
}

///|
/// PitchClass 相等比较（PitchClass 未 derive Eq）
fn pitch_class_eq(a : PitchClass, b : PitchClass) -> Bool {
  match a {
    C =>
      match b {
        C => true
        _ => false
      }
    D =>
      match b {
        D => true
        _ => false
      }
    E =>
      match b {
        E => true
        _ => false
      }
    F =>
      match b {
        F => true
        _ => false
      }
    G =>
      match b {
        G => true
        _ => false
      }
    A =>
      match b {
        A => true
        _ => false
      }
    B =>
      match b {
        B => true
        _ => false
      }
  }
}
