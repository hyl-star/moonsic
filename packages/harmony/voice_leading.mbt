//
// 声部引导 — chord_distance, sort_pitches, voice_lead_pitches
//

///|
/// 按 MIDI 升序排序音高数组
pub fn sort_pitches(pitches : Array[@pitch.Pitch]) -> Array[@pitch.Pitch] {
  let n = pitches.length()
  if n <= 1 {
    return pitches
  }
  let result = []
  for p in pitches {
    result.push(p)
  }
  for i = 1; i < n; i = i + 1 {
    let key = result[i]
    let mut j = i - 1
    while j >= 0 && result[j].to_midi() > key.to_midi() {
      result[j + 1] = result[j]
      j = j - 1
    }
    result[j + 1] = key
  }
  result
}

///|
/// 计算两个音高数组之间的声部距离（各声部 MIDI 差的绝对值之和）
pub fn chord_distance_pitches(
  a : Array[@pitch.Pitch],
  b : Array[@pitch.Pitch],
) -> Int {
  let a_pitches = sort_pitches(a)
  let b_pitches = sort_pitches(b)
  let mut dist = 0
  let n = if a_pitches.length() < b_pitches.length() {
    a_pitches.length()
  } else {
    b_pitches.length()
  }
  for i = 0; i < n; i = i + 1 {
    let diff = a_pitches[i].to_midi() - b_pitches[i].to_midi()
    let abs_diff = if diff < 0 { -diff } else { diff }
    dist = dist + abs_diff
  }
  let extra = if a_pitches.length() > b_pitches.length() {
    a_pitches.length() - b_pitches.length()
  } else {
    b_pitches.length() - a_pitches.length()
  }
  dist + extra * 12
}

///|
/// 为和弦进行应用声部引导：每个和弦选择距离最近的一个转位。
/// 返回新的 Array[Array[Pitch]]，保持最大程度的声部平滑。
pub fn voice_lead_pitches(
  chords : Array[Array[@pitch.Pitch]],
) -> Result[Array[Array[@pitch.Pitch]], HarmonyError] {
  if chords.length() == 0 {
    return Err(EmptyProgression("chord progression is empty"))
  }
  let result = []
  let mut prev_pitches : Array[@pitch.Pitch] = []
  for i = 0; i < chords.length(); i = i + 1 {
    let best = find_closest_inversion_pitches(chords[i], prev_pitches)
    result.push(best)
    prev_pitches = sort_pitches(best)
  }
  Ok(result)
}

///|
fn find_closest_inversion_pitches(
  pitches : Array[@pitch.Pitch],
  target : Array[@pitch.Pitch],
) -> Array[@pitch.Pitch] {
  if target.length() == 0 {
    return pitches
  }
  let n = pitches.length()
  let mut best = pitches
  let mut best_dist = chord_distance_pitches(pitches, target)
  for inv = 1; inv < n; inv = inv + 1 {
    match @chord.chord_invert(pitches, inv) {
      Ok(inverted) => {
        let d = chord_distance_pitches(inverted, target)
        if d < best_dist {
          best_dist = d
          best = inverted
        }
      }
      Err(_) => continue
    }
  }
  best
}
