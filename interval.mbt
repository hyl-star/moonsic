//
// 音程类型 — IntervalQuality, Interval, interval_between, parse_interval
//

///|
/// 音程性质：纯、大、小、增、减
pub(all) enum IntervalQuality {
  Perfect
  Major
  Minor
  Augmented
  Diminished
}

///|
/// 音程性质转字符串
pub fn IntervalQuality::to_string(self : IntervalQuality) -> String {
  match self {
    Perfect => "P"
    Major => "M"
    Minor => "m"
    Augmented => "A"
    Diminished => "d"
  }
}

///|
/// 音程：性质 + 度数 + 半音数
pub(all) struct Interval {
  quality : IntervalQuality
  number : Int
  semitones : Int
}

// --- 辅助函数 ---

///|
/// 获取 PitchClass 的数字索引（C=0..B=6）
fn class_index(pc : PitchClass) -> Int {
  match pc {
    C => 0
    D => 1
    E => 2
    F => 3
    G => 4
    A => 5
    B => 6
  }
}

///|
/// 从索引获取 PitchClass
fn class_from_index(idx : Int) -> PitchClass {
  let m = idx % 7
  match m {
    0 => C
    1 => D
    2 => E
    3 => F
    4 => G
    5 => A
    6 => B
    _ => C
  }
}

///|
/// 判断简单度数（1..8）是否属于纯音程类型
fn is_perfect_type(simple_number : Int) -> Bool {
  simple_number == 1 ||
  simple_number == 4 ||
  simple_number == 5 ||
  simple_number == 8
}

///|
/// 获取简单度数的基准半音数（作为纯/大音程）
fn base_semitones_for_number(simple_number : Int) -> Int {
  match simple_number {
    1 => 0
    2 => 2
    3 => 4
    4 => 5
    5 => 7
    6 => 9
    7 => 11
    8 => 12
    _ => 0
  }
}

///|
/// 根据简单度数和半音数确定音程性质
fn determine_quality(
  simple_number : Int,
  simple_semitones : Int,
) -> IntervalQuality {
  let base = base_semitones_for_number(simple_number)
  let diff = simple_semitones - base
  if is_perfect_type(simple_number) {
    if diff == 0 {
      Perfect
    } else if diff > 0 {
      Augmented
    } else {
      Diminished
    }
  } else if diff == 0 {
    Major
  } else if diff == -1 {
    Minor
  } else if diff == 1 {
    Augmented
  } else {
    Diminished
  }
}

///|
/// 根据性质和度数计算半音数
fn compute_semitones(quality : IntervalQuality, number : Int) -> Int {
  let octaves = (number - 1) / 7
  let simple_number = if number <= 7 { number } else { (number - 1) % 7 + 1 }
  let base = base_semitones_for_number(simple_number)
  let simple_semitones = if is_perfect_type(simple_number) {
    match quality {
      Perfect => base
      Augmented => base + 1
      Diminished => base - 1
      _ => base
    }
  } else {
    match quality {
      Major => base
      Minor => base - 1
      Augmented => base + 1
      Diminished => base - 2
      _ => base
    }
  }
  simple_semitones + octaves * 12
}

// --- 公开 API ---

///|
/// 计算两音之间的音程（从较低音到较高音的升序音程）
pub fn interval_between(a : Pitch, b : Pitch) -> Interval {
  let a_midi = a.to_midi()
  let b_midi = b.to_midi()
  let (low, high) = if a_midi <= b_midi { (a, b) } else { (b, a) }
  let semitones = high.to_midi() - low.to_midi()

  // 计算总的字母距离（含八度）
  let low_total = low.octave * 7 + class_index(low.class)
  let high_total = high.octave * 7 + class_index(high.class)
  let letter_distance = high_total - low_total
  let number = letter_distance + 1

  // 简化为简单音程来判断性质
  let simple_number = if number <= 8 { number } else { (number - 1) % 7 + 1 }
  let octaves = if number <= 8 { 0 } else { (number - 1) / 7 }
  let simple_semitones = semitones - octaves * 12

  let quality = determine_quality(simple_number, simple_semitones)
  { quality, number, semitones }
}

///|
/// 音程转位：性质翻转（大↔小、增↔减、纯不变），度数=9-原度数，半音数=12-原半音数
pub fn invert_interval(interval : Interval) -> Interval {
  let new_number = 9 - interval.number
  let new_semitones = 12 - interval.semitones
  let new_quality = match interval.quality {
    Perfect => Perfect
    Major => Minor
    Minor => Major
    Augmented => Diminished
    Diminished => Augmented
  }
  { quality: new_quality, number: new_number, semitones: new_semitones }
}

///|
/// 从文本解析音程。支持 "M3"、"m7"、"P5"、"A4"、"d5" 等格式。
pub fn parse_interval(input : String) -> Result[Interval, String] {
  if input.length() < 2 {
    return Err("无效的音程字符串：\{input}")
  }
  let quality = match input[0] {
    'P' => Perfect
    'M' => Major
    'm' => Minor
    'A' => Augmented
    'd' => Diminished
    _ => return Err("未知音程性质：\{input[0]}")
  }

  // 解析数字部分
  let mut number = 0
  let mut i = 1
  while i < input.length() && input[i] >= '0' && input[i] <= '9' {
    number = number * 10 + (input[i].to_int() - '0'.to_int())
    i = i + 1
  }
  if number <= 0 {
    return Err("无效音程度数：\{input}")
  }

  let semitones = compute_semitones(quality, number)
  Ok({ quality, number, semitones })
}
