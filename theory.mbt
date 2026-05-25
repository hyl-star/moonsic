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
/// Legacy scale-degree helper. Prefer `degree_checked` when invalid input must be reported.
pub fn degree(root : Pitch, kind : ScaleKind, deg : Int) -> Pitch {
  match degree_checked(root, kind, deg) {
    Ok(p) => p
    Err(e) => abort(e.to_string())
  }
}

///|
pub fn degree_checked(
  root : Pitch,
  kind : ScaleKind,
  deg : Int,
) -> Result[Pitch, TheoryError] {
  if deg <= 0 {
    return Err(InvalidInterval("scale degree must be > 0, got \{deg}"))
  }
  let intervals = kind.intervals()
  let octave_offset = (deg - 1) / intervals.length()
  let index = (deg - 1) % intervals.length()
  let base_midi = root.to_midi()
  midi_to_pitch_checked(base_midi + intervals[index] + octave_offset * 12)
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
/// 从文本解析和弦。支持 "C"、"Cm"、"Cmaj7"、"Dm7"、"G7"、"F#dim"、"C+"、"CM7"、
/// "F#maj7"、"Bdim7"、"Cmin7" 等格式。
pub fn parse_chord(input : String) -> Result[Chord, TheoryError] {
  if input.length() == 0 {
    return Err(InvalidChord("empty chord string"))
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
    _ => return Err(InvalidChord("invalid chord root: \{input}"))
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
  let (quality, end_pos) = parse_chord_quality_internal(input, pos)
  if end_pos != input.length() {
    return Err(
      InvalidChord(
        "trailing chord suffix: \{input[end_pos:input.length()].to_owned()}",
      ),
    )
  }

  // 构建和弦（使用八度 4 和默认四分音符时值，正确拼写）
  let root = pitch(root_class, accidental, 4)
  let root_midi = root.to_midi()
  let semitone_intervals = quality.intervals()
  let letter_offsets = chord_quality_letter_steps(quality)
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
pub fn chord_quality_letter_steps(quality : ChordQuality) -> Array[Int] {
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
/// 从文本解析和弦品质后缀。支持 "maj7"、"M7"、"dim7"、"o7"、"m7b5"、"min7"、
/// "m7"、"dim"、"o"、"aug"、"+"、"min"、"m"、"7"、"sus2"、"sus4" 等。
/// 返回 `Ok(ChordQuality)` 或 `Err(InvalidChord)`。
pub fn parse_chord_quality_checked(
  input : String,
) -> Result[ChordQuality, TheoryError] {
  if input.length() == 0 {
    return Ok(MajorTriad)
  }
  let (quality, end_pos) = parse_chord_quality_internal(input, 0)
  if end_pos != input.length() {
    return Err(
      InvalidChord(
        "trailing chord suffix: \{input[end_pos:input.length()].to_owned()}",
      ),
    )
  }
  Ok(quality)
}

///|
/// 内部：解析和弦品质后缀，按最长优先匹配
/// 返回 (ChordQuality, 消费到的位置)
fn parse_chord_quality_internal(
  input : String,
  pos : Int,
) -> (ChordQuality, Int) {
  if pos >= input.length() {
    return (MajorTriad, pos)
  }
  // 4-char 模式（最长优先）
  if match_chord_str(input, pos, "maj7") {
    (MajorSeventh, pos + 4)
  } else if match_chord_str(input, pos, "dim7") {
    (Diminished7, pos + 4)
  } else if match_chord_str(input, pos, "m7b5") {
    (HalfDiminished7, pos + 4)
  } else if match_chord_str(input, pos, "min7") {
    (MinorSeventh, pos + 4)
  } else if match_chord_str(input, pos, "sus2") {
    (Suspended2, pos + 4)
  } else if match_chord_str(input, pos, "sus4") {
    (Suspended4, pos + 4)
  } else if match_chord_str(input, pos, "dim") {
    // 3-char
    (DiminishedTriad, pos + 3)
  } else if match_chord_str(input, pos, "aug") {
    (AugmentedTriad, pos + 3)
  } else if match_chord_str(input, pos, "min") {
    (MinorTriad, pos + 3)
  } else if match_chord_str(input, pos, "m7") {
    // 2-char
    (MinorSeventh, pos + 2)
  } else if match_chord_str(input, pos, "M7") {
    (MajorSeventh, pos + 2)
  } else if match_chord_str(input, pos, "o7") {
    (Diminished7, pos + 2)
  } else if match_chord_str(input, pos, "o") {
    // 1-char（必须在 "o7" 之后）
    (DiminishedTriad, pos + 1)
  } else if input[pos] == '+' {
    (AugmentedTriad, pos + 1)
  } else if match_chord_str(input, pos, "m") {
    (MinorTriad, pos + 1)
  } else if match_chord_str(input, pos, "7") {
    (DominantSeventh, pos + 1)
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
/// 从文本解析音阶品质。支持 "major"、"ionian"、"minor"、"natural minor"、
/// "aeolian"、"major pentatonic"、"minor pentatonic"、"harmonic minor"、
/// "melodic minor"、"dorian"、"phrygian"、"lydian"、"mixolydian"、
/// "locrian"、"chromatic" 等。
/// 返回 `Ok(ScaleKind)` 或 `Err(InvalidScale)`。
pub fn parse_scale_kind_checked(
  input : String,
) -> Result[ScaleKind, TheoryError] {
  let trimmed = input.trim().to_owned()
  if trimmed.length() == 0 {
    return Err(InvalidScale("empty scale kind"))
  }
  let (kind, end_pos) = match parse_scale_kind_internal(trimmed, 0) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let remaining = trimmed[end_pos:trimmed.length()].trim()
  if remaining.length() > 0 {
    return Err(
      InvalidScale("trailing scale kind suffix: \{remaining.to_owned()}"),
    )
  }
  Ok(kind)
}

///|
/// 内部：从位置 p 解析音阶品质名称，返回 (ScaleKind, 新位置)
fn parse_scale_kind_internal(
  input : String,
  pos : Int,
) -> Result[(ScaleKind, Int), TheoryError] {
  if match_chord_str(input, pos, "major pentatonic") {
    Ok((MajorPentatonic, pos + "major pentatonic".length()))
  } else if match_chord_str(input, pos, "minor pentatonic") {
    Ok((MinorPentatonic, pos + "minor pentatonic".length()))
  } else if match_chord_str(input, pos, "harmonic minor") {
    Ok((HarmonicMinor, pos + "harmonic minor".length()))
  } else if match_chord_str(input, pos, "melodic minor") {
    Ok((MelodicMinor, pos + "melodic minor".length()))
  } else if match_chord_str(input, pos, "natural minor") {
    Ok((NaturalMinor, pos + "natural minor".length()))
  } else if match_chord_str(input, pos, "major") {
    Ok((Major, pos + "major".length()))
  } else if match_chord_str(input, pos, "ionian") {
    Ok((Major, pos + "ionian".length()))
  } else if match_chord_str(input, pos, "minor") {
    Ok((NaturalMinor, pos + "minor".length()))
  } else if match_chord_str(input, pos, "aeolian") {
    Ok((NaturalMinor, pos + "aeolian".length()))
  } else if match_chord_str(input, pos, "dorian") {
    Ok((Dorian, pos + "dorian".length()))
  } else if match_chord_str(input, pos, "phrygian") {
    Ok((Phrygian, pos + "phrygian".length()))
  } else if match_chord_str(input, pos, "lydian") {
    Ok((Lydian, pos + "lydian".length()))
  } else if match_chord_str(input, pos, "mixolydian") {
    Ok((Mixolydian, pos + "mixolydian".length()))
  } else if match_chord_str(input, pos, "locrian") {
    Ok((Locrian, pos + "locrian".length()))
  } else if match_chord_str(input, pos, "chromatic") {
    Ok((Chromatic, pos + "chromatic".length()))
  } else {
    Err(InvalidScale("unknown scale type: \{input}"))
  }
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
