// ============================================================
// v3 闊充箰鐞嗚 鈥?闊崇▼銆侀煶闃躲€佸拰寮﹀搧璐ㄣ€佸拰寮﹁繘琛?// ============================================================

// --- 闊崇▼ ---

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

// --- 闊抽樁 ---

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

// --- 闊崇骇 ---

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

// --- 鍜屽鸡鍝佽川 ---

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
/// 鍜屽鸡鍝佽川鐨勫崐闊抽棿闅旀ā寮?
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
/// 閫氳繃鍜屽鸡鍝佽川鏋勫缓鍜屽鸡
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

// --- 缃楅┈鏁板瓧 ---

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
/// 鑾峰彇缃楅┈鏁板瓧鍦ㄦ寚瀹氳皟涓殑鏍归煶
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
/// 鍒ゆ柇缃楅┈鏁板瓧鍦ㄦ寚瀹氳皟涓槸澶т笁鍜屽鸡
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
/// 鍒ゆ柇缃楅┈鏁板瓧鍦ㄦ寚瀹氳皟涓槸鍑忎笁鍜屽鸡
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
/// 鍜屽鸡杩涜锛氭牴鎹皟寮忚嚜鍔ㄩ€夋嫨澶т笁/灏忎笁/鍑忎笁鍜屽鸡
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

// --- 鍜屽鸡鏂囨湰瑙ｆ瀽 ---

///|
/// 浠庢枃鏈В鏋愬拰寮︺€傛敮鎸?"C"銆?Cm"銆?Cmaj7"銆?Dm7"銆?G7"銆?F#dim" 绛夋牸寮忋€?
pub fn parse_chord(input : String) -> Result[Chord, TheoryError] {
  if input.length() == 0 {
    return Err(InvalidChord("empty chord string"))
  }

  // 瑙ｆ瀽鏍归煶瀛楁瘝
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

  // 瑙ｆ瀽鍙€夌殑鍙橀煶璁板彿
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

  // 瑙ｆ瀽鍜屽鸡鍝佽川鍚庣紑
  let (quality, end_pos) = parse_chord_quality(input, pos)
  if end_pos != input.length() {
    return Err(
      InvalidChord(
        "trailing chord suffix: \{input[end_pos:input.length()].to_owned()}",
      ),
    )
  }

  // 鏋勫缓鍜屽鸡锛堜娇鐢ㄥ叓搴?4 鍜岄粯璁ゅ洓鍒嗛煶绗︽椂鍊硷紝姝ｇ‘鎷煎啓锛?
  let root = pitch(root_class, accidental, 4)
  let root_midi = root.to_midi()
  let semitone_intervals = quality.intervals()
  let letter_offsets = chord_letter_steps(quality)
  let root_cls = class_index(root_class)
  let pitches = []
  for i = 0; i < semitone_intervals.length(); i = i + 1 {
    let target_midi = root_midi + semitone_intervals[i]
    let expected_class = class_from_index((root_cls + letter_offsets[i]) % 7)
    // 鎵惧埌浣?expected_class 鏈€鎺ヨ繎 target_midi 鐨勫叓搴?
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
/// 鍜屽鸡鍝佽川瀵瑰簲鐨勫瓧姣嶆杩涳紙鍦ㄥ瓧姣嶇┖闂翠腑鐨勫亸绉伙級
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
/// 瑙ｆ瀽鍜屽鸡鍝佽川鍚庣紑锛堝唴閮ㄥ嚱鏁帮級
fn parse_chord_quality(input : String, pos : Int) -> (ChordQuality, Int) {
  if pos >= input.length() {
    return (MajorTriad, pos)
  }
  // 浼樺厛鍖归厤杈冮暱鐨勬ā寮?
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
/// 妫€鏌ュ瓧绗︿覆浠?pos 寮€濮嬫槸鍚﹀尮閰?target
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
/// 杩斿洖鍜屽鸡鍖呭惈鐨勯煶绾у垪琛紙鍘婚噸锛屾寜鍜屽鸡鍐呴『搴忥級
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
/// PitchClass 鐩哥瓑姣旇緝锛圥itchClass 鏈?derive Eq锛?
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
