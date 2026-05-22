// v9 和声 — 罗马数字文本解析 + 声部引导

///|
/// 从文本解析和弦进行："I vi IV V"
pub fn roman_progression(
  key : Key,
  text : String,
  duration : Duration,
) -> Track {
  let numerals = parse_roman_text(text)
  progression_with_roman(key, numerals, duration)
}

///|
pub fn progression_with_roman(
  key : Key,
  numerals : Array[RomanNumeral],
  duration : Duration,
) -> Track {
  progression(key.tonic, key.kind, numerals, duration)
}

///|
/// 解析 "I vi IV V" 文本
fn parse_roman_text(text : String) -> Array[RomanNumeral] {
  let numerals = []
  let len = text.length()
  let mut i = 0
  while i < len {
    if text[i] == ' ' {
      i = i + 1
      continue
    }
    if text[i] == 'I' {
      if i + 1 < len && text[i + 1] == 'I' {
        if i + 2 < len && text[i + 2] == 'I' {
          numerals.push(III)
          i = i + 3
        } else {
          numerals.push(II)
          i = i + 2
        }
      } else {
        numerals.push(I)
        i = i + 1
      }
    } else if text[i] == 'V' {
      if i + 2 < len && text[i + 1] == 'I' && text[i + 2] == 'I' {
        numerals.push(VII)
        i = i + 3
      } else if i + 1 < len && text[i + 1] == 'I' {
        numerals.push(VI)
        i = i + 2
      } else {
        numerals.push(V)
        i = i + 1
      }
    } else if text[i] >= 'a' && text[i] <= 'z' {
      // lowercase: ii, iii, vi, vii
      if text[i] == 'i' {
        if i + 1 < len && text[i + 1] == 'i' {
          if i + 2 < len && text[i + 2] == 'i' {
            numerals.push(III)
            i = i + 3
          } else {
            numerals.push(II)
            i = i + 2
          }
        } else {
          numerals.push(I)
          i = i + 1
        }
      } else if text[i] == 'v' {
        if i + 1 < len && text[i + 1] == 'i' {
          numerals.push(VI)
          i = i + 2
        } else if i + 1 < len &&
          text[i + 1] == 'i' &&
          i + 2 < len &&
          text[i + 2] == 'i' {
          numerals.push(VII)
          i = i + 3
        } else {
          numerals.push(V)
          i = i + 1
        }
      }
    } else {
      i = i + 1
    }
  }
  numerals
}

// --- 声部引导 ---

///|
/// 计算两个和弦之间的声部距离（各声部 MIDI 差的绝对值之和）
pub fn chord_distance(a : Chord, b : Chord) -> Int {
  let a_pitches = sort_pitches(a.pitches)
  let b_pitches = sort_pitches(b.pitches)
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
fn sort_pitches(pitches : Array[Pitch]) -> Array[Pitch] {
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
/// 为和弦进行应用声部引导：每个和弦选择距离最近的一个转位
pub fn voice_lead(chords : Track) -> Track {
  let events = []
  let mut prev_pitches : Array[Pitch] = []
  for evt in chords.events {
    match evt {
      Chord(c) => {
        let best = find_closest_inversion(c, prev_pitches)
        events.push(Chord(best))
        prev_pitches = sort_pitches(best.pitches)
      }
      _ => events.push(evt)
    }
  }
  track(events)
}

///|
fn find_closest_inversion(c : Chord, target : Array[Pitch]) -> Chord {
  if target.length() == 0 {
    return c
  }
  let n = c.pitches.length()
  let tmp_chord = {
    pitches: target,
    duration: c.duration,
    velocity: c.velocity,
  }
  let mut best = c
  let mut best_dist = chord_distance(c, tmp_chord) // include root position
  for inv = 1; inv < n; inv = inv + 1 {
    let inverted = c.invert(inv)
    let d = chord_distance(inverted, tmp_chord)
    if d < best_dist {
      best_dist = d
      best = inverted
    }
  }
  best
}
