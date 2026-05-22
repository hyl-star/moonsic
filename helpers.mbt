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
  Whole
}

///|
pub fn half() -> Duration {
  Half
}

///|
pub fn quarter() -> Duration {
  Quarter
}

///|
pub fn eighth() -> Duration {
  Eighth
}

///|
pub fn sixteenth() -> Duration {
  Sixteenth
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

// --- 文本旋律解析 ---

///|
/// 从紧凑文本格式解析旋律：`melody_str("C4q D4q E4q G4q | A4h")`
/// 格式：音名[变音][八度]时值[.]  休止：`r` + 时值   `|` 忽略
pub fn melody_str(input : String) -> Track {
  let events = []
  let len = input.length()
  let mut i = 0
  while i < len {
    let ch = input[i]
    if ch == ' ' || ch == '|' || ch == '\n' {
      i = i + 1
      continue
    }
    if ch == 'r' {
      // 休止：r + 时值码
      i = i + 1
      if i >= len {
        break
      }
      let (dur, advance) = parse_dur(input, i)
      events.push(Rest(rest(dur)))
      i = advance
    } else if ch >= 'A' && ch <= 'G' {
      // 音名
      let class = match ch {
        'C' => C
        'D' => D
        'E' => E
        'F' => F
        'G' => G
        'A' => A
        'B' => B
        _ => C
      }
      i = i + 1
      // 可选变音记号
      let mut acc = Natural
      if i < len && (input[i] == '#' || input[i] == 'b') {
        acc = if input[i] == '#' { Sharp } else { Flat }
        i = i + 1
      }
      // 八度数字
      if i >= len {
        break
      }
      let octave = input[i].to_int() - '0'.to_int()
      i = i + 1
      // 时值码
      let (dur, advance) = parse_dur(input, i)
      let p = pitch(class, acc, octave)
      events.push(Note(note(p, dur)))
      i = advance
    } else {
      i = i + 1
    }
  }
  track(events)
}

///|
/// 解析时值码：w=whole, h=half, q=quarter, e=eighth, s=sixteenth，可选 `.` 附点
fn parse_dur(input : String, i : Int) -> (Duration, Int) {
  if i >= input.length() {
    return (Quarter, i)
  }
  let base = match input[i] {
    'w' => Whole
    'h' => Half
    'q' => Quarter
    'e' => Eighth
    's' => Sixteenth
    _ => Quarter
  }
  let next = i + 1
  if next < input.length() && input[next] == '.' {
    (dotted(base), next + 1)
  } else {
    (base, next)
  }
}
