//
// 音阶结构 — Scale struct, build_scale, parse_scale
//

///|
/// 音阶：根音 + 类型 + 音级列表（不含八度和变音记号）
pub(all) struct Scale {
  root : PitchClass
  scale_type : ScaleKind
  tones : Array[PitchClass]
}

// --- 辅助函数 ---

///|
/// 检查字符串从 pos 开始是否匹配 target
fn match_at(s : String, pos : Int, target : String) -> Bool {
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

// --- 公开 API ---

///|
/// 构造音阶：根据根音和音阶类型计算音级列表
pub fn build_scale(root : PitchClass, scale_type : ScaleKind) -> Scale {
  let intervals = scale_type.intervals()
  let root_idx = class_index(root)
  let tones = []
  for i = 0; i < intervals.length(); i = i + 1 {
    let letter_idx = (root_idx + i) % 7
    tones.push(class_from_index(letter_idx))
  }
  { root, scale_type, tones }
}

///|
/// 从文本解析音阶。支持 "C major"、"A minor"、"D dorian" 等格式。
pub fn parse_scale(input : String) -> Result[Scale, String] {
  if input.length() == 0 {
    return Err("空的音阶字符串")
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

  // 跳过可选的变音记号（Scale.root 是 PitchClass，不记录变音记号）
  if pos < input.length() && (input[pos] == '#' || input[pos] == 'b') {
    pos = pos + 1
  }

  // 跳过空格
  if pos < input.length() && input[pos] == ' ' {
    pos = pos + 1
  }

  // 解析音阶类型
  let scale_type = if match_at(input, pos, "major pentatonic") {
    MajorPentatonic
  } else if match_at(input, pos, "minor pentatonic") {
    MinorPentatonic
  } else if match_at(input, pos, "harmonic minor") {
    HarmonicMinor
  } else if match_at(input, pos, "melodic minor") {
    MelodicMinor
  } else if match_at(input, pos, "natural minor") {
    NaturalMinor
  } else if match_at(input, pos, "major") {
    Major
  } else if match_at(input, pos, "minor") {
    NaturalMinor
  } else if match_at(input, pos, "dorian") {
    Dorian
  } else if match_at(input, pos, "phrygian") {
    Phrygian
  } else if match_at(input, pos, "lydian") {
    Lydian
  } else if match_at(input, pos, "mixolydian") {
    Mixolydian
  } else if match_at(input, pos, "locrian") {
    Locrian
  } else if match_at(input, pos, "chromatic") {
    Chromatic
  } else {
    return Err("未知音阶类型：\{input}")
  }

  let scale = build_scale(root_class, scale_type)
  Ok(scale)
}
