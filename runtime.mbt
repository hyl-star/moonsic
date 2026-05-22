// ============================================================
// 事件运行时 — NoteEvent 结构体、轨道/乐谱展开
// ============================================================

// --- NoteEvent ---

///|
/// 运行时音符事件：具体的开始时间、时长、MIDI 编号、力度、通道
pub(all) struct NoteEvent {
  start : Double
  duration : Double
  midi_note : Int
  velocity : Int
  channel : Int
}

///|
/// 事件的结束时间
pub fn NoteEvent::end(self : NoteEvent) -> Double {
  self.start + self.duration
}

///|
/// 开始时间转为秒（需 BPM）
pub fn NoteEvent::start_seconds(self : NoteEvent, bpm : Int) -> Double {
  let quarter_sec = 60.0 / bpm.to_double()
  self.start * quarter_sec
}

///|
/// 时长转为秒（需 BPM）
pub fn NoteEvent::duration_seconds(self : NoteEvent, bpm : Int) -> Double {
  let quarter_sec = 60.0 / bpm.to_double()
  self.duration * quarter_sec
}

///|
/// 开始时间转为 MIDI tick 数
pub fn NoteEvent::start_ticks(self : NoteEvent, ppq : Int) -> Int {
  (self.start * ppq.to_double()).to_int()
}

///|
/// 时长转为 MIDI tick 数
pub fn NoteEvent::duration_ticks(self : NoteEvent, ppq : Int) -> Int {
  (self.duration * ppq.to_double()).to_int()
}

///|
pub fn NoteEvent::to_string(self : NoteEvent) -> String {
  "NoteEvent(start=\{self.start}, dur=\{self.duration}, midi=\{self.midi_note}, v=\{self.velocity}, ch=\{self.channel})"
}

// --- 轨道展开 ---

///|
/// 将轨道展开为 NoteEvent 序列
/// 休止符推进时间但不产生事件，音符产生 NoteEvent
pub fn Track::to_note_events(self : Track) -> Array[NoteEvent] {
  let mut cursor = 0.0
  let events = []
  for e in self.events {
    match e {
      Note(n) => {
        let ne = {
          start: cursor,
          duration: n.duration.beats(),
          midi_note: n.pitch.to_midi(),
          velocity: n.velocity,
          channel: self.channel,
        }
        events.push(ne)
        cursor = cursor + n.duration.beats()
      }
      Rest(r) => cursor = cursor + r.duration.beats()
    }
  }
  events
}

///|
/// 将乐谱展开为 NoteEvent 序列（多轨道合并，按开始时间稳定排序）
pub fn Score::to_note_events(self : Score) -> Array[NoteEvent] {
  let all_events = []
  for track in self.tracks {
    let track_events = track.to_note_events()
    for e in track_events {
      all_events.push(e)
    }
  }
  sort_note_events(all_events)
}

///|
/// 按 start 时间稳定排序
fn sort_note_events(events : Array[NoteEvent]) -> Array[NoteEvent] {
  let n = events.length()
  if n <= 1 {
    return events
  }
  for i = 1; i < n; i = i + 1 {
    let key = events[i]
    let mut j = i - 1
    while j >= 0 && events[j].start > key.start {
      events[j + 1] = events[j]
      j = j - 1
    }
    events[j + 1] = key
  }
  events
}
