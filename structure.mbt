// ============================================================
// v3 歌曲结构 — Section + arrange + 编曲工具
// ============================================================

// --- Section ---

///|
pub(all) struct Section {
  name : String
  tracks : Array[Track]
}

///|
pub fn section(name : String, tracks : Array[Track]) -> Section {
  { name, tracks }
}

///| 前奏
pub fn intro(tracks : Array[Track]) -> Section {
  section("intro", tracks)
}

///| 主歌
pub fn verse(tracks : Array[Track]) -> Section {
  section("verse", tracks)
}

///| 副歌
pub fn chorus(tracks : Array[Track]) -> Section {
  section("chorus", tracks)
}

///| 桥段
pub fn bridge(tracks : Array[Track]) -> Section {
  section("bridge", tracks)
}

///| 尾奏
pub fn outro(tracks : Array[Track]) -> Section {
  section("outro", tracks)
}

///| Section 的时长 = 最长轨道
pub fn Section::duration_beats(self : Section) -> Double {
  let mut max_b = 0.0
  for t in self.tracks {
    let b = t.duration_beats()
    if b > max_b { max_b = b }
  }
  max_b
}

// --- Track 工具 ---

///| 用休止填充轨道到目标拍数
pub fn Track::pad_to(self : Track, target_beats : Double) -> Track {
  let current = self.duration_beats()
  if current >= target_beats { return self }
  let mut gap = target_beats - current
  let events = []
  for e in self.events { events.push(e) }
  // 用休止填充
  while gap > 0.0 {
    if gap >= 4.0 {
      events.push(r(whole())); gap = gap - 4.0
    } else if gap >= 2.0 {
      events.push(r(half())); gap = gap - 2.0
    } else if gap >= 1.0 {
      events.push(r(quarter())); gap = gap - 1.0
    } else if gap >= 0.5 {
      events.push(r(eighth())); gap = gap - 0.5
    } else {
      events.push(r(sixteenth())); gap = gap - 0.25
    }
  }
  { events, channel: self.channel, program: self.program }
}

///| 将多条 track 打包为 Score
pub fn layer(tracks : Array[Track]) -> Score {
  score(tracks)
}

///| 将多条 track 打包为 Section
pub fn section_layer(name : String, tracks : Array[Track]) -> Section {
  section(name, tracks)
}

// --- 编曲：拼接 Section ---

///| 将多个 Section 编排为完整 Score（对齐轨道数、填充休止）
pub fn arrange(
  sections : Array[Section],
  bpm : Int,
  ts : TimeSignature,
) -> Score {
  let mut max_tracks = 0
  for s in sections {
    let n = s.tracks.length()
    if n > max_tracks { max_tracks = n }
  }
  let result_tracks = []
  for i = 0; i < max_tracks; i = i + 1 {
    result_tracks.push(empty_track())
  }
  for s in sections {
    let dur = s.duration_beats()
    for i = 0; i < max_tracks; i = i + 1 {
      let t = if i < s.tracks.length() { s.tracks[i] } else { empty_track() }
      let padded = t.pad_to(dur)
      result_tracks[i] = result_tracks[i].concat(padded)
    }
  }
  score_with_tempo(result_tracks, tempo(bpm), ts)
}

// --- 低音 + 旋律 ---

///| 从和弦进行生成根音低音线
pub fn bass_roots(chords : Track, dur : Duration) -> Track {
  let events = []
  for evt in chords.events {
    match evt {
      Chord(c) => {
        let root = c.pitches[0]
        events.push(n(root, dur))
      }
      _ => events.push(r(dur))
    }
  }
  { events, channel: chords.channel, program: chords.program }
}

///| 从调性 + 音级序列生成旋律
pub fn melody_degrees(
  key : Key,
  degrees : Array[Int],
  dur : Duration,
) -> Track {
  let events = []
  for d in degrees {
    events.push(n(key.degree(d, 4), dur))
  }
  track(events)
}
