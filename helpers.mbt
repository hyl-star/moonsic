// ============================================================
// v1.5 作曲快捷函数 — 让简单旋律更短
// ============================================================

// --- 音高快捷构造 ---

///|
/// 自然音高快捷构造：c(4) = pitch(C, Natural, 4)
pub fn c(octave : Int) -> Pitch {
  pitch(C, Natural, octave)
}

///|
pub fn d(octave : Int) -> Pitch {
  pitch(D, Natural, octave)
}

///|
pub fn e(octave : Int) -> Pitch {
  pitch(E, Natural, octave)
}

///|
pub fn f(octave : Int) -> Pitch {
  pitch(F, Natural, octave)
}

///|
pub fn g(octave : Int) -> Pitch {
  pitch(G, Natural, octave)
}

///|
pub fn a(octave : Int) -> Pitch {
  pitch(A, Natural, octave)
}

///|
pub fn b(octave : Int) -> Pitch {
  pitch(B, Natural, octave)
}

// --- 升号快捷构造 ---

///|
/// 升号音高：cs(4) = pitch(C, Sharp, 4) = C#4
pub fn cs(octave : Int) -> Pitch {
  pitch(C, Sharp, octave)
}

///|
pub fn ds(octave : Int) -> Pitch {
  pitch(D, Sharp, octave)
}

///|
pub fn fs(octave : Int) -> Pitch {
  pitch(F, Sharp, octave)
}

///|
pub fn gs(octave : Int) -> Pitch {
  pitch(G, Sharp, octave)
}

///|
// as(octave) 因 as 是 MoonBit 关键字，v1.5 不提供。请用 pitch(A, Sharp, octave)

// --- 降号快捷构造 ---

///|
/// 降号音高：db(4) = pitch(D, Flat, 4) = Db4
pub fn db(octave : Int) -> Pitch {
  pitch(D, Flat, octave)
}

///|
pub fn eb(octave : Int) -> Pitch {
  pitch(E, Flat, octave)
}

///|
pub fn gb(octave : Int) -> Pitch {
  pitch(G, Flat, octave)
}

///|
pub fn ab(octave : Int) -> Pitch {
  pitch(A, Flat, octave)
}

///|
pub fn bb(octave : Int) -> Pitch {
  pitch(B, Flat, octave)
}

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

// --- 独立解析 API ---

///|
/// 从文本解析音高。支持 "C4"、"F#3"、"Bb5" 等格式。
/// 返回 Result[Pitch, String]，非法输入时返回 Err。
pub fn parse_pitch(input : String) -> Result[Pitch, String] {
  if input.length() < 2 {
    return Err("Invalid pitch")
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
    _ => return Err("Invalid pitch")
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
    return Err("Invalid pitch")
  }
  if !(input[pos] >= '0' && input[pos] <= '9') {
    return Err("Invalid pitch")
  }
  let (octave, new_pos) = read_octave(input, pos)
  if octave < 0 {
    return Err("Invalid pitch")
  }
  // 不允许有剩余字符
  if new_pos < input.length() {
    return Err("Invalid pitch")
  }
  Ok(pitch(class, acc, octave))
}

///|
/// 内部：从 pos 读取八度数字，返回 (八度值, 新位置)
fn read_octave(input : String, pos : Int) -> (Int, Int) {
  let mut p = pos
  let mut val = 0
  let len = input.length()
  while p < len && input[p] >= '0' && input[p] <= '9' {
    val = val * 10 + (input[p].to_int() - '0'.to_int())
    p = p + 1
  }
  if p == pos {
    return (-1, pos)
  }
  (val, p)
}

///|
/// 从文本解析音级。支持 "C"、"C#"、"Db" 等格式（无八度数字）。
/// 返回的 PitchClass 仅包含音名（字母部分），变音记号不存储在 PitchClass 中。
pub fn parse_pitch_class(input : String) -> Result[PitchClass, String] {
  if input.length() == 0 {
    return Err("Invalid pitch class")
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
    _ => return Err("Invalid pitch class")
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
  Err("Invalid pitch class")
}

// --- FFI JSON 包装 ---

///|
/// FFI 包装：解析音高字符串并返回 JSON 格式的 MIDI 编号。
/// 输入 "C4" → {"ok":true,"value":60}
/// 输入 "X9" → {"ok":false,"error":"Invalid pitch"}
pub fn ffi_parse_pitch_to_midi(input : String) -> String {
  match parse_pitch(input) {
    Ok(p) => "{\"ok\":true,\"value\":" + p.to_midi().to_string() + "}"
    Err(_) => "{\"ok\":false,\"error\":\"Invalid pitch\"}"
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
          "\"" +
          p.class.to_string() +
          p.accidental.to_string() +
          "\""
        if i < c.pitches.length() - 1 {
          notes_str = notes_str + ","
        }
      }
      notes_str = notes_str + "]"
      "{\"ok\":true,\"value\":" + notes_str + "}"
    }
    Err(_) => "{\"ok\":false,\"error\":\"Invalid chord\"}"
  }
}

///|
/// FFI 包装：解析音阶字符串并返回 JSON 格式的音级列表。
/// 输入 "C major" → {"ok":true,"value":["C","D","E","F","G","A","B"]}
pub fn ffi_build_scale(input : String) -> String {
  match parse_scale(input) {
    Ok(s) => {
      let mut notes_str = "["
      for i = 0; i < s.tones.length(); i = i + 1 {
        notes_str = notes_str + "\"" + s.tones[i].to_string() + "\""
        if i < s.tones.length() - 1 {
          notes_str = notes_str + ","
        }
      }
      notes_str = notes_str + "]"
      "{\"ok\":true,\"value\":" + notes_str + "}"
    }
    Err(_) => "{\"ok\":false,\"error\":\"Invalid scale\"}"
  }
}
