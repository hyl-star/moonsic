// ============================================================
// 歌曲结构 — Section + arrange + 编曲工具
// ============================================================

///|
pub(all) struct Section {
  name : String
  tracks : Array[Track]
}

///|
pub fn section(name : String, tracks : Array[Track]) -> Section {
  { name, tracks }
}

///|
pub fn intro(tracks : Array[Track]) -> Section { section("intro", tracks) }
pub fn verse(tracks : Array[Track]) -> Section { section("verse", tracks) }
pub fn chorus(tracks : Array[Track]) -> Section { section("chorus", tracks) }
pub fn bridge(tracks : Array[Track]) -> Section { section("bridge", tracks) }
pub fn outro(tracks : Array[Track]) -> Section { section("outro", tracks) }

///|
pub fn Section::duration_beats(self : Section) -> Double {
  let mut max_b = 0.0
  for t in self.tracks {
    let b = t.duration_beats()
    if b > max_b { max_b = b }
  }
  max_b
}

///|
pub fn Track::pad_to(self : Track, target_beats : Double) -> Track {
  let current = self.duration_beats()
  if current >= target_beats { return self }
  let mut gap = target_beats - current
  let events = []
  for e in self.events { events.push(e) }
  while gap > 0.0 {
    if gap >= 4.0 {
      events.push(Rest(rest(Whole))); gap = gap - 4.0
    } else if gap >= 2.0 {
      events.push(Rest(rest(Half))); gap = gap - 2.0
    } else if gap >= 1.0 {
      events.push(Rest(rest(Quarter))); gap = gap - 1.0
    } else if gap >= 0.5 {
      events.push(Rest(rest(Eighth))); gap = gap - 0.5
    } else {
      events.push(Rest(rest(Sixteenth))); gap = gap - 0.25
    }
  }
  { events, channel: self.channel, program: self.program, volume: self.volume, pan: self.pan, mute: self.mute }
}

///|
pub fn layer(tracks : Array[Track]) -> Score { score(tracks) }

///|
pub fn arrange(sections : Array[Section], bpm : Int, ts : TimeSignature) -> Score {
  let mut max_tracks = 0
  for s in sections {
    let n = s.tracks.length()
    if n > max_tracks { max_tracks = n }
  }
  let result_tracks = []
  for i = 0; i < max_tracks; i = i + 1 { result_tracks.push(empty_track()) }
  for s in sections {
    let dur = s.duration_beats()
    for i = 0; i < max_tracks; i = i + 1 {
      let t = if i < s.tracks.length() { s.tracks[i] } else { empty_track() }
      result_tracks[i] = result_tracks[i].concat(t.pad_to(dur))
    }
  }
  score_with_tempo(result_tracks, tempo(bpm), ts)
}

///|
pub fn bass_roots(chords : Track, dur : Duration) -> Track {
  let events = []
  for evt in chords.events {
    match evt {
      Chord(c) => events.push(Note(note(c.pitches[0], dur)))
      _ => events.push(Rest(rest(dur)))
    }
  }
  { events, channel: chords.channel, program: chords.program, volume: chords.volume, pan: chords.pan, mute: chords.mute }
}

///|
pub fn melody_degrees(key : Key, degrees : Array[Int], dur : Duration) -> Track {
  let events = []
  for d in degrees {
    events.push(Note(note(key.degree(d, 4), dur)))
  }
  track(events)
}
