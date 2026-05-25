//
// 闊崇▼绫诲瀷 鈥?IntervalQuality, Interval, interval_between, parse_interval
//

///|
/// 闊崇▼鎬ц川锛氱函銆佸ぇ銆佸皬銆佸銆佸噺
pub(all) enum IntervalQuality {
  Perfect
  Major
  Minor
  Augmented
  Diminished
}

///|
/// 闊崇▼鎬ц川杞瓧绗︿覆
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
/// 闊崇▼锛氭€ц川 + 搴︽暟 + 鍗婇煶鏁?
pub(all) struct Interval {
  quality : IntervalQuality
  number : Int
  semitones : Int
}

// --- 杈呭姪鍑芥暟 ---

///|
/// 鑾峰彇 PitchClass 鐨勬暟瀛楃储寮曪紙C=0..B=6锛?
// class_index lives in pitch_class_rules.mbt.

///|
/// 浠庣储寮曡幏鍙?PitchClass
// class_from_index lives in pitch_class_rules.mbt.

///|
/// 鍒ゆ柇绠€鍗曞害鏁帮紙1..8锛夋槸鍚﹀睘浜庣函闊崇▼绫诲瀷
fn is_perfect_type(simple_number : Int) -> Bool {
  simple_number == 1 ||
  simple_number == 4 ||
  simple_number == 5 ||
  simple_number == 8
}

///|
/// 鑾峰彇绠€鍗曞害鏁扮殑鍩哄噯鍗婇煶鏁帮紙浣滀负绾?澶ч煶绋嬶級
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
/// 鏍规嵁绠€鍗曞害鏁板拰鍗婇煶鏁扮‘瀹氶煶绋嬫€ц川
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
/// 鏍规嵁鎬ц川鍜屽害鏁拌绠楀崐闊虫暟
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

// --- 鍏紑 API ---

///|
/// 璁＄畻涓ら煶涔嬮棿鐨勯煶绋嬶紙浠庤緝浣庨煶鍒拌緝楂橀煶鐨勫崌搴忛煶绋嬶級
pub fn interval_between(a : Pitch, b : Pitch) -> Interval {
  let a_midi = a.to_midi()
  let b_midi = b.to_midi()
  let (low, high) = if a_midi <= b_midi { (a, b) } else { (b, a) }
  let semitones = high.to_midi() - low.to_midi()

  // 璁＄畻鎬荤殑瀛楁瘝璺濈锛堝惈鍏害锛?
  let low_total = low.octave * 7 + class_index(low.class)
  let high_total = high.octave * 7 + class_index(high.class)
  let letter_distance = high_total - low_total
  let number = letter_distance + 1

  // 绠€鍖栦负绠€鍗曢煶绋嬫潵鍒ゆ柇鎬ц川
  let simple_number = if number <= 8 { number } else { (number - 1) % 7 + 1 }
  let octaves = if number <= 8 { 0 } else { (number - 1) / 7 }
  let simple_semitones = semitones - octaves * 12

  let quality = determine_quality(simple_number, simple_semitones)
  { quality, number, semitones }
}

///|
/// 闊崇▼杞綅锛氭€ц川缈昏浆锛堝ぇ鈫斿皬銆佸鈫斿噺銆佺函涓嶅彉锛夛紝搴︽暟=9-鍘熷害鏁帮紝鍗婇煶鏁?12-鍘熷崐闊虫暟
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
/// 浠庢枃鏈В鏋愰煶绋嬨€傛敮鎸?"M3"銆?m7"銆?P5"銆?A4"銆?d5" 绛夋牸寮忋€?
pub fn parse_interval(input : String) -> Result[Interval, TheoryError] {
  if input.length() < 2 {
    return Err(InvalidInterval("expected interval like M3, m7, P5, A4, or d5"))
  }
  let quality = match input[0] {
    'P' => Perfect
    'M' => Major
    'm' => Minor
    'A' => Augmented
    'd' => Diminished
    _ => return Err(InvalidInterval("unknown interval quality in \{input}"))
  }

  // 瑙ｆ瀽鏁板瓧閮ㄥ垎
  let mut number = 0
  let mut i = 1
  while i < input.length() && input[i] >= '0' && input[i] <= '9' {
    number = number * 10 + (input[i].to_int() - '0'.to_int())
    i = i + 1
  }
  if number <= 0 {
    return Err(InvalidInterval("invalid interval number in \{input}"))
  }
  if i < input.length() {
    return Err(InvalidInterval("trailing characters in \{input}"))
  }

  let semitones = compute_semitones(quality, number)
  Ok({ quality, number, semitones })
}
