// ============================================================
// v1.5 浣滄洸蹇嵎鍑芥暟 鈥?璁╃畝鍗曟棆寰嬫洿鐭?// ============================================================

// --- 闊抽珮蹇嵎鏋勯€?---

///|
/// 鑷劧闊抽珮蹇嵎鏋勯€狅細c(4) = pitch(C, Natural, 4)
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

// --- 鍗囧彿蹇嵎鏋勯€?---

///|
/// 鍗囧彿闊抽珮锛歝s(4) = pitch(C, Sharp, 4) = C#4
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
// as(octave) 鍥?as 鏄?MoonBit 鍏抽敭瀛楋紝v1.5 涓嶆彁渚涖€傝鐢?pitch(A, Sharp, octave)

// --- 闄嶅彿蹇嵎鏋勯€?---

///|
/// 闄嶅彿闊抽珮锛歞b(4) = pitch(D, Flat, 4) = Db4
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

// --- 鏃跺€煎揩鎹锋瀯閫?---

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

// --- 浜嬩欢蹇嵎鏋勯€?---

///|
/// 蹇嵎闊崇锛歯(c(4), quarter()) = Note(note(c(4), Quarter))
pub fn n(pitch : Pitch, duration : Duration) -> MusicEvent {
  Note(note(pitch, duration))
}

///|
/// 蹇嵎闊崇锛堟寚瀹氬姏搴︼級
pub fn nv(pitch : Pitch, duration : Duration, velocity : Int) -> MusicEvent {
  Note(note_with_velocity(pitch, duration, velocity))
}

///|
/// 蹇嵎浼戞锛歳(half()) = Rest(rest(Half))
pub fn r(duration : Duration) -> MusicEvent {
  Rest(rest(duration))
}

///|
/// 蹇嵎鍜屽鸡锛歝h([c(4), e(4), g(4)], quarter())
pub fn ch(pitches : Array[Pitch], duration : Duration) -> MusicEvent {
  Chord(chord(pitches, duration))
}

///|
/// 澶т笁鍜屽鸡锛歮ajor(c(4), half()) = C E G
pub fn major(root : Pitch, duration : Duration) -> MusicEvent {
  Chord(chord([root, root.transpose(4), root.transpose(7)], duration))
}

///|
/// 灏忎笁鍜屽鸡锛歮inor(a(3), half()) = A C E
pub fn minor(root : Pitch, duration : Duration) -> MusicEvent {
  Chord(chord([root, root.transpose(3), root.transpose(7)], duration))
}

///|
/// 鍑忎笁鍜屽鸡锛歞im(b(3), half()) = B D F
pub fn dim(root : Pitch, duration : Duration) -> MusicEvent {
  chord_quality(root, DiminishedTriad, duration)
}

///|
/// 澧炰笁鍜屽鸡锛歛ug(c(4), half()) = C E G#
pub fn aug(root : Pitch, duration : Duration) -> MusicEvent {
  chord_quality(root, AugmentedTriad, duration)
}

///|
/// 灞炰竷鍜屽鸡锛歞om7(g(3), half()) = G B D F
pub fn dom7(root : Pitch, duration : Duration) -> MusicEvent {
  chord_quality(root, DominantSeventh, duration)
}

///|
/// 澶т竷鍜屽鸡锛歮aj7(c(4), half()) = C E G B
pub fn maj7(root : Pitch, duration : Duration) -> MusicEvent {
  chord_quality(root, MajorSeventh, duration)
}

///|
/// 灏忎竷鍜屽鸡锛歮in7(a(3), half()) = A C E G
pub fn min7(root : Pitch, duration : Duration) -> MusicEvent {
  chord_quality(root, MinorSeventh, duration)
}

// --- 杞ㄩ亾/涔愯氨蹇嵎鏋勯€?---

///|
/// 蹇嵎杞ㄩ亾锛歮elody([...]) = track([...])
pub fn melody(events : Array[MusicEvent]) -> Track {
  track(events)
}

///|
pub fn melody_with_channel(events : Array[MusicEvent], channel : Int) -> Track {
  track_with_channel(events, channel)
}

///|
/// 鍗曡建閬撲箰璋憋紙榛樿 120 BPM, 4/4锛?
pub fn score1(track : Track) -> Score {
  score([track])
}

///|
/// 蹇嵎涔愯氨鏋勯€狅細score_with([lead, harmony], 120, four_four())
pub fn score_with(
  tracks : Array[Track],
  bpm : Int,
  time_signature : TimeSignature,
) -> Score {
  score_with_tempo(tracks, tempo(bpm), time_signature)
}

// --- 鏂囨湰璁拌氨瑙ｆ瀽鍣?(v6) ---

///|
/// 浠庢枃鏈В鏋愭棆寰嬨€傛敮鎸侊細`C4q` `F#4e` `Rq` `[C4 E4 G4]h` `C4q:80` `x4` `#娉ㄩ噴`
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
/// 浠庡畬鏁翠箰璋辨枃鏈В鏋?Score銆傛敮鎸?`tempo N`銆乣time N/D` 鎸囦护銆?
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

// --- 鍐呴儴瑙ｆ瀽鍑芥暟 ---

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
/// 鍐呴儴瑙ｆ瀽锛氫粠浣嶇疆 p 瑙ｆ瀽闊抽珮锛岃繑鍥?(Pitch, 鏂颁綅缃?
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

// --- 鐙珛瑙ｆ瀽 API ---

///|
/// 浠庢枃鏈В鏋愰煶楂樸€傛敮鎸?"C4"銆?F#3"銆?Bb5" 绛夋牸寮忋€?/// 杩斿洖 Result[Pitch, String]锛岄潪娉曡緭鍏ユ椂杩斿洖 Err銆?
pub fn parse_pitch(input : String) -> Result[Pitch, TheoryError] {
  if input.length() < 2 {
    return Err(InvalidPitch("expected pitch like C4, F#3, or Bb5"))
  }
  // 瑙ｆ瀽闊冲悕
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
  // 瑙ｆ瀽鍙€夊彉闊宠鍙?
  let mut acc = Natural
  if pos < input.length() && (input[pos] == '#' || input[pos] == 'b') {
    acc = if input[pos] == '#' { Sharp } else { Flat }
    pos = pos + 1
  }
  // 瑙ｆ瀽鍏害鏁板瓧锛堟敮鎸佸浣嶆暟瀛楋級
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
  // 涓嶅厑璁告湁鍓╀綑瀛楃
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
/// 鍐呴儴锛氫粠 pos 璇诲彇鍏害鏁板瓧锛岃繑鍥?(鍏害鍊? 鏂颁綅缃?
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
/// 浠庢枃鏈В鏋愰煶绾с€傛敮鎸?"C"銆?C#"銆?Db" 绛夋牸寮忥紙鏃犲叓搴︽暟瀛楋級銆?/// 杩斿洖鐨?PitchClass 浠呭寘鍚煶鍚嶏紙瀛楁瘝閮ㄥ垎锛夛紝鍙橀煶璁板彿涓嶅瓨鍌ㄥ湪 PitchClass 涓€?
pub fn parse_pitch_class(input : String) -> Result[PitchClass, TheoryError] {
  if input.length() == 0 {
    return Err(InvalidPitch("empty pitch class"))
  }
  // 瑙ｆ瀽闊冲悕
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
  // 浠呴煶鍚嶏細鍚堟硶
  if len == 1 {
    return Ok(pc)
  }
  // 闊冲悕 + 涓€涓彉闊宠鍙凤細鍚堟硶
  if len == 2 && (input[1] == '#' || input[1] == 'b') {
    return Ok(pc)
  }
  // 鍚叓搴︽暟瀛楁垨鍏朵粬瀛楃锛氫笉鍚堟硶
  Err(InvalidPitch("invalid pitch class syntax: \{input}"))
}

// --- FFI JSON 鍖呰 ---

///|
/// FFI 鍖呰锛氳В鏋愰煶楂樺瓧绗︿覆骞惰繑鍥?JSON 鏍煎紡鐨?MIDI 缂栧彿銆?/// 杈撳叆 "C4" 鈫?{"ok":true,"value":60}
/// 杈撳叆 "X9" 鈫?{"ok":false,"error":"Invalid pitch"}
pub fn ffi_parse_pitch_to_midi(input : String) -> String {
  match parse_pitch(input) {
    Ok(p) => ffi_ok_value(p.to_midi().to_string())
    Err(e) => ffi_error("InvalidPitch", e.to_string())
  }
}

///|
/// FFI 鍖呰锛氳В鏋愬拰寮﹀瓧绗︿覆骞惰繑鍥?JSON 鏍煎紡鐨勯煶绾у垪琛ㄣ€?/// 杈撳叆 "Cm7" 鈫?{"ok":true,"value":["C","Eb","G","Bb"]}
pub fn ffi_parse_chord_tones(input : String) -> String {
  match parse_chord(input) {
    Ok(c) => {
      // 浣跨敤 pitch 鐨?class+accidental 浠ヤ繚鐣欏彉闊宠鍙凤紙濡?"Eb" 鑰岄潪 "E"锛?
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
/// FFI 鍖呰锛氳В鏋愰煶闃跺瓧绗︿覆骞惰繑鍥?JSON 鏍煎紡鐨勯煶绾у垪琛ㄣ€?/// 杈撳叆 "C major" 鈫?{"ok":true,"value":["C","D","E","F","G","A","B"]}
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
