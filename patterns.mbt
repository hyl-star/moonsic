// ============================================================
// v2 模式变换 — concat, reverse, stretch, map_velocity, octave
// ============================================================

// --- 拼接 ---

///|
/// 将另一轨道的事件追加到当前轨道末尾（保留通道）
pub fn Track::concat(self : Track, other : Track) -> Track {
  let new_events = []
  for e in self.events {
    new_events.push(e)
  }
  for e in other.events {
    new_events.push(e)
  }
  { events: new_events, channel: self.channel, program: self.program }
}

// --- 反转 ---

///|
/// 反转事件顺序（时值和通道不变）
pub fn Track::reverse(self : Track) -> Track {
  let new_events = []
  let n = self.events.length()
  for i = 0; i < n; i = i + 1 {
    new_events.push(self.events[n - 1 - i])
  }
  { events: new_events, channel: self.channel, program: self.program }
}

// --- 拉伸 ---

///|
/// 时长缩放（factor=2 → 时长翻倍）
pub fn Duration::stretch(self : Duration, factor : Double) -> Duration {
  // 用基础拍数 × factor 构造新 Duration
  let new_beats = self.beats() * factor
  duration_from_beats(new_beats)
}

///|
/// 根据拍数反推最接近的 Duration
fn duration_from_beats(beats : Double) -> Duration {
  if beats >= 3.75 {
    Whole // 4.0
  } else if beats >= 1.75 {
    Half // 2.0
  } else if beats >= 0.75 {
    Quarter // 1.0
  } else if beats >= 0.375 {
    Eighth // 0.5
  } else {
    Sixteenth // 0.25
  }
}

///|
/// 音符拉伸
pub fn Note::stretch(self : Note, factor : Double) -> Note {
  {
    pitch: self.pitch,
    duration: self.duration.stretch(factor),
    velocity: self.velocity,
  }
}

///|
/// 休止拉伸
pub fn Rest::stretch(self : Rest, factor : Double) -> Rest {
  { duration: self.duration.stretch(factor) }
}

///|
/// 音乐事件拉伸
pub fn MusicEvent::stretch(self : MusicEvent, factor : Double) -> MusicEvent {
  match self {
    Note(n) => Note(n.stretch(factor))
    Rest(r) => Rest(r.stretch(factor))
    Chord(c) => Chord(chord_stretch(c, factor))
  }
}

///|
/// 和弦拉伸（内部）
fn chord_stretch(c : Chord, factor : Double) -> Chord {
  {
    pitches: c.pitches,
    duration: c.duration.stretch(factor),
    velocity: c.velocity,
  }
}

///|
/// 轨道拉伸
pub fn Track::stretch(self : Track, factor : Double) -> Track {
  let new_events = []
  for e in self.events {
    new_events.push(e.stretch(factor))
  }
  { events: new_events, channel: self.channel, program: self.program }
}

// --- 力度映射 ---

///|
/// 音符力度设置
pub fn Note::with_velocity(self : Note, velocity : Int) -> Note {
  { pitch: self.pitch, duration: self.duration, velocity }
}

///|
/// 和弦力度设置
pub fn Chord::with_velocity(self : Chord, velocity : Int) -> Chord {
  { pitches: self.pitches, duration: self.duration, velocity }
}

///|
/// 音乐事件力度映射
pub fn MusicEvent::map_velocity(
  self : MusicEvent,
  f : (Int) -> Int,
) -> MusicEvent {
  match self {
    Note(n) => Note(n.with_velocity(f(n.velocity)))
    Rest(r) => Rest(r)
    Chord(c) => Chord(c.with_velocity(f(c.velocity)))
  }
}

///|
/// 轨道力度映射
pub fn Track::map_velocity(self : Track, f : (Int) -> Int) -> Track {
  let new_events = []
  for e in self.events {
    new_events.push(e.map_velocity(f))
  }
  { events: new_events, channel: self.channel, program: self.program }
}

// --- 八度移调 ---

///|
/// 升高一个八度
pub fn Track::up_octave(self : Track) -> Track {
  self.transpose(12)
}

///|
/// 降低一个八度
pub fn Track::down_octave(self : Track) -> Track {
  self.transpose(-12)
}
