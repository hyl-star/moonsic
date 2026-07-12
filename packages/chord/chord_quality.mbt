//
// 和弦品质 — ChordQuality enum, intervals, letter steps, pitch generation
//

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
/// 生成和弦音高数组（按字母正确拼写）
pub fn chord_pitches(
  root : @pitch.Pitch,
  quality : ChordQuality,
) -> Array[@pitch.Pitch] {
  let root_midi = root.to_midi()
  let semitone_intervals = quality.intervals()
  let letter_offsets = chord_quality_letter_steps(quality)
  let root_cls = @pitch.class_index(root.pitch_class())
  let pitches = []
  for i = 0; i < semitone_intervals.length(); i = i + 1 {
    let target_midi = root_midi + semitone_intervals[i]
    let expected_class = @pitch.class_from_index(
      (root_cls + letter_offsets[i]) % 7,
    )
    // 找到使 expected_class 最接近 target_midi 的八度
    let target_octave = target_midi / 12 - 1
    let natural_midi = (target_octave + 1) * 12 + expected_class.base_semitone()
    let mut diff = target_midi - natural_midi
    let mut octave = target_octave
    if diff > 6 {
      octave = target_octave + 1
      diff = target_midi - ((octave + 1) * 12 + expected_class.base_semitone())
    } else if diff < -6 {
      octave = target_octave - 1
      diff = target_midi - ((octave + 1) * 12 + expected_class.base_semitone())
    }
    let acc = match diff {
      -2 => @pitch.DoubleFlat
      -1 => @pitch.Flat
      0 => @pitch.Natural
      1 => @pitch.Sharp
      2 => @pitch.DoubleSharp
      _ => @pitch.Natural
    }
    pitches.push(@pitch.pitch(expected_class, acc, octave))
  }
  pitches
}

///|
/// 和弦品质对应的音级列表（去重）
pub fn chord_pitch_classes(
  root : @pitch.Pitch,
  quality : ChordQuality,
) -> Array[@pitch.PitchClass] {
  let pitches = chord_pitches(root, quality)
  let classes = []
  for p in pitches {
    let pc = p.pitch_class()
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
/// 和弦转位：将最低音升高八度，重复 times 次
pub fn chord_invert(
  pitches : Array[@pitch.Pitch],
  times : Int,
) -> Result[Array[@pitch.Pitch], ChordError] {
  if times < 0 {
    return Err(InvalidInversion("inversion count must be >= 0, got \{times}"))
  }
  if pitches.length() <= 1 {
    return Ok(pitches)
  }
  let n = times % pitches.length()
  let new_pitches = []
  for i = 0; i < pitches.length(); i = i + 1 {
    let src_idx = i + n
    let p = if src_idx >= pitches.length() {
      pitches[src_idx - pitches.length()].transpose(12)
    } else {
      pitches[src_idx]
    }
    new_pitches.push(p)
  }
  Ok(new_pitches)
}

///|
/// PitchClass 相等比较
fn pitch_class_eq(a : @pitch.PitchClass, b : @pitch.PitchClass) -> Bool {
  match a {
    @pitch.C =>
      match b {
        @pitch.C => true
        _ => false
      }
    @pitch.D =>
      match b {
        @pitch.D => true
        _ => false
      }
    @pitch.E =>
      match b {
        @pitch.E => true
        _ => false
      }
    @pitch.F =>
      match b {
        @pitch.F => true
        _ => false
      }
    @pitch.G =>
      match b {
        @pitch.G => true
        _ => false
      }
    @pitch.A =>
      match b {
        @pitch.A => true
        _ => false
      }
    @pitch.B =>
      match b {
        @pitch.B => true
        _ => false
      }
  }
}
