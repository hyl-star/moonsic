//
// 和弦文本解析
//

///|
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
    (DiminishedTriad, pos + 3)
  } else if match_chord_str(input, pos, "aug") {
    (AugmentedTriad, pos + 3)
  } else if match_chord_str(input, pos, "min") {
    (MinorTriad, pos + 3)
  } else if match_chord_str(input, pos, "m7") {
    (MinorSeventh, pos + 2)
  } else if match_chord_str(input, pos, "M7") {
    (MajorSeventh, pos + 2)
  } else if match_chord_str(input, pos, "o7") {
    (Diminished7, pos + 2)
  } else if match_chord_str(input, pos, "o") {
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
/// 从文本解析和弦品质后缀。支持 "maj7"、"M7"、"dim7"、"o7"、"m7b5"、"min7"、
/// "m7"、"dim"、"o"、"aug"、"+"、"min"、"m"、"7"、"sus2"、"sus4" 等。
pub fn parse_chord_quality_checked(
  input : String,
) -> Result[ChordQuality, ChordError] {
  if input.length() == 0 {
    return Ok(MajorTriad)
  }
  let (quality, end_pos) = parse_chord_quality_internal(input, 0)
  if end_pos != input.length() {
    return Err(
      InvalidChordQuality(
        "trailing chord suffix: \{input[end_pos:input.length()].to_owned()}",
      ),
    )
  }
  Ok(quality)
}

///|
/// 从文本解析和弦，返回正确拼写的音高数组。
/// 支持 "C"、"Cm"、"Cmaj7"、"Dm7"、"G7"、"F#dim"、"C+"、"CM7"、
/// "F#maj7"、"Bdim7"、"Cmin7" 等格式。
pub fn parse_chord(input : String) -> Result[Array[@pitch.Pitch], ChordError] {
  if input.length() == 0 {
    return Err(EmptyChord("empty chord string"))
  }

  // 解析根音字母
  let root_class = match input[0] {
    'C' => @pitch.C
    'D' => @pitch.D
    'E' => @pitch.E
    'F' => @pitch.F
    'G' => @pitch.G
    'A' => @pitch.A
    'B' => @pitch.B
    _ => return Err(InvalidChord("invalid chord root: \{input}"))
  }
  let mut pos = 1

  // 解析可选的变音记号
  let mut accidental = @pitch.Natural
  if pos < input.length() {
    if input[pos] == '#' {
      accidental = @pitch.Sharp
      pos = pos + 1
    } else if input[pos] == 'b' {
      accidental = @pitch.Flat
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

  let root = @pitch.pitch(root_class, accidental, 4)
  Ok(chord_pitches(root, quality))
}
