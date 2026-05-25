//
// 音高/音级文本解析
//

///|
/// 从文本解析音高。支持 "C4"、"F#3"、"Bb5" 等格式。
/// 返回 Result[Pitch, String]，非法输入时返回 Err。
pub fn parse_pitch(input : String) -> Result[Pitch, TheoryError] {
  if input.length() < 2 {
    return Err(InvalidPitch("expected pitch like C4, F#3, or Bb5"))
  }
  // 解析音名
  let class = match input[0] {
    'C' => C
    'D' => D
    'E' => E
    'F' => F
    'G' => G
    'A' => A
    'B' => B
    _ => return Err(InvalidPitch("unknown pitch class in \{input}"))
  }
  let mut pos = 1
  // 解析可选变音记号
  let mut acc = Natural
  if pos < input.length() && (input[pos] == '#' || input[pos] == 'b') {
    acc = if input[pos] == '#' { Sharp } else { Flat }
    pos = pos + 1
  }
  // 解析八度数字（支持多位数字）
  if pos >= input.length() {
    return Err(InvalidPitch("missing octave in \{input}"))
  }
  if !((input[pos] >= '0' && input[pos] <= '9') ||
    (
      input[pos] == '-' &&
      pos + 1 < input.length() &&
      input[pos + 1] >= '0' &&
      input[pos + 1] <= '9'
    )) {
    return Err(InvalidPitch("octave must be numeric in \{input}"))
  }
  let (octave, new_pos) = read_octave(input, pos)
  if octave < -1 {
    return Err(InvalidPitch("invalid octave in \{input}"))
  }
  // 不允许有剩余字符
  if new_pos < input.length() {
    return Err(InvalidPitch("trailing characters in \{input}"))
  }
  let parsed = pitch(class, acc, octave)
  if parsed.to_midi() < MIN_MIDI_NOTE {
    Err(MidiOutOfRange(parsed.to_midi()))
  } else {
    Ok(parsed)
  }
}

///|
/// 内部：从 pos 读取八度数字，返回 (八度值, 新位置)
fn read_octave(input : String, pos : Int) -> (Int, Int) {
  let mut p = pos
  let mut sign = 1
  if p < input.length() && input[p] == '-' {
    sign = -1
    p = p + 1
  }
  let digit_start = p
  let mut val = 0
  let len = input.length()
  while p < len && input[p] >= '0' && input[p] <= '9' {
    val = val * 10 + (input[p].to_int() - '0'.to_int())
    p = p + 1
  }
  if p == digit_start {
    return (-1, pos)
  }
  (sign * val, p)
}

///|
/// 从文本解析音级。支持 "C"、"C#"、"Db" 等格式（无八度数字）。
/// 返回的 PitchClass 仅包含音名（字母部分），变音记号不存储在 PitchClass 中。
pub fn parse_pitch_class(input : String) -> Result[PitchClass, TheoryError] {
  if input.length() == 0 {
    return Err(InvalidPitch("empty pitch class"))
  }
  // 解析音名
  let pc = match input[0] {
    'C' => C
    'D' => D
    'E' => E
    'F' => F
    'G' => G
    'A' => A
    'B' => B
    _ => return Err(InvalidPitch("unknown pitch class in \{input}"))
  }
  let len = input.length()
  // 仅音名：合法
  if len == 1 {
    return Ok(pc)
  }
  // 音名 + 一个变音记号：合法
  if len == 2 && (input[1] == '#' || input[1] == 'b') {
    return Ok(pc)
  }
  // 含八度数字或其他字符：不合法
  Err(InvalidPitch("invalid pitch class syntax: \{input}"))
}
