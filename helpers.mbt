// ============================================================
// v1.5 作曲快捷函数 — 让简单旋律更短
// ============================================================

// --- 时值快捷构造 ---

///|
pub fn whole() -> Duration {
  Duration::Whole
}

///|
pub fn half() -> Duration {
  Duration::Half
}

///|
pub fn quarter() -> Duration {
  Duration::Quarter
}

///|
pub fn eighth() -> Duration {
  Duration::Eighth
}

///|
pub fn sixteenth() -> Duration {
  Duration::Sixteenth
}

// --- 事件快捷构造 ---

///|
/// 快捷音符：n(c(4), quarter()) = Note(note(c(4), Quarter))
pub fn n(pitch : Pitch, duration : Duration) -> MusicEvent {
  Note(note(pitch, duration))
}

///|
/// 快捷音符（指定力度）
pub fn nv(pitch : Pitch, duration : Duration, velocity : Int) -> MusicEvent {
  Note(note_with_velocity(pitch, duration, velocity))
}

///|
/// 快捷休止：r(half()) = Rest(rest(Half))
pub fn r(duration : Duration) -> MusicEvent {
  Rest(rest(duration))
}

///|
/// 快捷和弦：ch([c(4), e(4), g(4)], quarter())
pub fn ch(pitches : Array[Pitch], duration : Duration) -> MusicEvent {
  Chord(chord(pitches, duration))
}

///|
/// 大三和弦：major(c(4), half()) = C E G
pub fn major(root : Pitch, duration : Duration) -> MusicEvent {
  Chord(chord([root, root.transpose(4), root.transpose(7)], duration))
}

///|
/// 小三和弦：minor(a(3), half()) = A C E
pub fn minor(root : Pitch, duration : Duration) -> MusicEvent {
  Chord(chord([root, root.transpose(3), root.transpose(7)], duration))
}

///|
/// 减三和弦：dim(b(3), half()) = B D F
pub fn dim(root : Pitch, duration : Duration) -> MusicEvent {
  chord_quality(root, DiminishedTriad, duration)
}

///|
/// 增三和弦：aug(c(4), half()) = C E G#
pub fn aug(root : Pitch, duration : Duration) -> MusicEvent {
  chord_quality(root, AugmentedTriad, duration)
}

///|
/// 属七和弦：dom7(g(3), half()) = G B D F
pub fn dom7(root : Pitch, duration : Duration) -> MusicEvent {
  chord_quality(root, DominantSeventh, duration)
}

///|
/// 大七和弦：maj7(c(4), half()) = C E G B
pub fn maj7(root : Pitch, duration : Duration) -> MusicEvent {
  chord_quality(root, MajorSeventh, duration)
}

///|
/// 小七和弦：min7(a(3), half()) = A C E G
pub fn min7(root : Pitch, duration : Duration) -> MusicEvent {
  chord_quality(root, MinorSeventh, duration)
}

// --- 轨道/乐谱快捷构造 ---

///|
/// 快捷轨道：melody([...]) = track([...])
pub fn melody(events : Array[MusicEvent]) -> Track {
  track(events)
}

///|
pub fn melody_with_channel(events : Array[MusicEvent], channel : Int) -> Track {
  track_with_channel(events, channel)
}

///|
/// 单轨道乐谱（默认 120 BPM, 4/4）
pub fn score1(track : Track) -> Score {
  score([track])
}

///|
/// 快捷乐谱构造：score_with([lead, harmony], 120, four_four())
/// 注意：内部调用 tempo(bpm)，bpm 越界时 abort。考虑使用 score_with_tempo + tempo_checked 替代。
pub fn score_with(
  tracks : Array[Track],
  bpm : Int,
  time_signature : TimeSignature,
) -> Score {
  score_with_tempo(tracks, tempo(bpm), time_signature)
}

// --- 文本记谱解析器 (v6) ---

///|
/// 从文本解析旋律。支持：`C4q` `F#4e` `Rq` `[C4 E4 G4]h` `C4q:80` `x4` `#注释`
pub fn melody_str(input : String) -> Track {
  let (events, repeat, _pos) = parse_line(input, 0)
  let all = []
  for _r = 0; _r < repeat; _r = _r + 1 {
    for e in events {
      all.push(e)
    }
  }
  track(all)
}

///|
/// 从完整乐谱文本解析 Score。支持 `tempo N`、`time N/D` 指令。
pub fn score_str(input : String) -> Score {
  let mut bpm = 120
  let mut ts = four_four()
  let all_events = []
  let len = input.length()
  let mut pos = 0
  while pos < len {
    pos = skip_blank(pos, input, len)
    if pos >= len {
      break
    }
    if match_prefix(pos, input, "tempo ") {
      pos = pos + 6
      let (v, p) = read_int(pos, input, len)
      bpm = v
      pos = p
    } else if match_prefix(pos, input, "time ") {
      pos = pos + 5
      let (num, p1) = read_int(pos, input, len)
      pos = p1
      if pos < len && input[pos] == '/' {
        pos = pos + 1
      }
      let (den, p2) = read_int(pos, input, len)
      pos = p2
      ts = time_signature(num, den)
    } else if input[pos] == '#' {
      while pos < len && input[pos] != '\n' {
        pos = pos + 1
      }
    } else if input[pos] == '\n' {
      pos = pos + 1
    } else {
      let (evts, rep, p) = parse_line(input, pos)
      pos = p
      for _r = 0; _r < rep; _r = _r + 1 {
        for e in evts {
          all_events.push(e)
        }
      }
    }
  }
  score_with_tempo([track(all_events)], tempo(bpm), ts)
}

// --- 内部解析函数 ---

///|
fn parse_line(input : String, pos : Int) -> (Array[MusicEvent], Int, Int) {
  let events = []
  let mut p = pos
  let len = input.length()
  let mut repeat = 1
  while p < len && input[p] != '\n' && input[p] != '#' {
    p = skip_blank(p, input, len)
    if p >= len || input[p] == '\n' || input[p] == '#' {
      break
    }
    if input[p] == '[' {
      p = p + 1
      let pitches = []
      while p < len && input[p] != ']' {
        p = skip_blank(p, input, len)
        if p < len && input[p] >= 'A' && input[p] <= 'G' {
          let (pitch_val, p2) = parse_pitch_at(input, p)
          pitches.push(pitch_val)
          p = p2
        } else {
          p = p + 1
        }
      }
      if p < len {
        p = p + 1
      }
      let (dur, p2) = parse_dur(input, p)
      p = p2
      let vel = parse_vel(input, p, 100)
      p = vel.1
      events.push(Chord(chord_with_velocity(pitches, dur, vel.0)))
    } else if input[p] == 'R' {
      p = p + 1
      let (dur, p2) = parse_dur(input, p)
      p = p2
      events.push(Rest(rest(dur)))
    } else if input[p] == 'x' {
      p = p + 1
      let (n, p2) = read_int(p, input, len)
      repeat = n
      p = p2
      break
    } else if input[p] >= 'A' && input[p] <= 'G' {
      let (pitch_val, p2) = parse_pitch_at(input, p)
      p = p2
      let (dur, p3) = parse_dur(input, p)
      p = p3
      let vel = parse_vel(input, p, 100)
      p = vel.1
      events.push(Note(note_with_velocity(pitch_val, dur, vel.0)))
    } else {
      p = p + 1
    }
  }
  while p < len && input[p] != '\n' {
    p = p + 1
  }
  if p < len {
    p = p + 1
  }
  (events, repeat, p)
}

///|
/// 内部解析：从位置 p 解析音高，返回 (Pitch, 新位置)
fn parse_pitch_at(input : String, p : Int) -> (Pitch, Int) {
  let class = match input[p] {
    'C' => C
    'D' => D
    'E' => E
    'F' => F
    'G' => G
    'A' => A
    'B' => B
    _ => C
  }
  let mut j = p + 1
  let mut acc = Natural
  if j < input.length() && (input[j] == '#' || input[j] == 'b') {
    acc = if input[j] == '#' { Sharp } else { Flat }
    j = j + 1
  }
  let octave = if j < input.length() {
    input[j].to_int() - '0'.to_int()
  } else {
    4
  }
  (pitch(class, acc, octave), j + 1)
}

///|
fn parse_dur(input : String, p : Int) -> (Duration, Int) {
  if p >= input.length() {
    return (Duration::Quarter, p)
  }
  let base = match input[p] {
    'w' => Duration::Whole
    'h' => Duration::Half
    'q' => Duration::Quarter
    'e' => Duration::Eighth
    's' => Duration::Sixteenth
    _ => Duration::Quarter
  }
  let n = p + 1
  if n < input.length() && input[n] == '.' {
    (dotted(base), n + 1)
  } else {
    (base, n)
  }
}

///|
fn parse_vel(input : String, p : Int, default : Int) -> (Int, Int) {
  if p < input.length() && input[p] == ':' {
    let (v, p2) = read_int(p + 1, input, input.length())
    (v, p2)
  } else {
    (default, p)
  }
}

///|
fn read_int(p : Int, input : String, len : Int) -> (Int, Int) {
  let mut j = p
  let mut val = 0
  while j < len && input[j] >= '0' && input[j] <= '9' {
    val = val * 10 + (input[j].to_int() - '0'.to_int())
    j = j + 1
  }
  (val, j)
}

///|
fn skip_blank(p : Int, input : String, len : Int) -> Int {
  let mut j = p
  while j < len && (input[j] == ' ' || input[j] == '|' || input[j] == '\t') {
    j = j + 1
  }
  j
}

///|
fn match_prefix(p : Int, input : String, prefix : String) -> Bool {
  let pl = prefix.length()
  if p + pl > input.length() {
    return false
  }
  let mut j = 0
  while j < pl && input[p + j] == prefix[j] {
    j = j + 1
  }
  j == pl
}

// --- FFI JSON 包装 ---

///|
/// FFI 包装：解析音高字符串并返回 JSON 格式的 MIDI 编号。
/// 输入 "C4" → {"ok":true,"value":60}
/// 输入 "X9" → {"ok":false,"error":"Invalid pitch"}
pub fn ffi_parse_pitch_to_midi(input : String) -> String {
  match parse_pitch(input) {
    Ok(p) => ffi_ok_value(p.to_midi().to_string())
    Err(e) => ffi_error("InvalidPitch", e.to_string())
  }
}

///|
/// FFI 包装：解析和弦字符串并返回 JSON 格式的音级列表。
/// 输入 "Cm7" → {"ok":true,"value":["C","Eb","G","Bb"]}
pub fn ffi_parse_chord_tones(input : String) -> String {
  match parse_chord(input) {
    Ok(c) => {
      // 使用 pitch 的 class+accidental 以保留变音记号（如 "Eb" 而非 "E"）
      let mut notes_str = "["
      for i = 0; i < c.pitches.length(); i = i + 1 {
        let p = c.pitches[i]
        notes_str = notes_str +
          json_escape(p.class.to_string() + p.accidental.to_string())
        if i < c.pitches.length() - 1 {
          notes_str = notes_str + ","
        }
      }
      notes_str = notes_str + "]"
      ffi_ok_value(notes_str)
    }
    Err(e) => ffi_error("InvalidChord", e.to_string())
  }
}

///|
/// FFI 包装：解析音阶字符串并返回 JSON 格式的音级列表。
/// 输入 "C major" → {"ok":true,"value":["C","D","E","F","G","A","B"]}
pub fn ffi_build_scale(input : String) -> String {
  match parse_scale(input) {
    Ok(s) => {
      let mut notes_str = "["
      for i = 0; i < s.spelled_tones.length(); i = i + 1 {
        let p = s.spelled_tones[i]
        notes_str = notes_str +
          json_escape(p.class.to_string() + p.accidental.to_string())
        if i < s.spelled_tones.length() - 1 {
          notes_str = notes_str + ","
        }
      }
      notes_str = notes_str + "]"
      ffi_ok_value(notes_str)
    }
    Err(e) => ffi_error("InvalidScale", e.to_string())
  }
}
