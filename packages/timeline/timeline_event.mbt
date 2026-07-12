///|
pub(all) struct NoteEvent {
  start : Double
  duration : Double
  midi_note : Int
  velocity : Int
  channel : Int
}

///|
pub fn NoteEvent::end(self : NoteEvent) -> Double {
  self.start + self.duration
}

///|
pub fn NoteEvent::start_seconds(self : NoteEvent, bpm : Int) -> Double {
  let quarter_sec = 60.0 / bpm.to_double()
  self.start * quarter_sec
}

///|
pub fn NoteEvent::duration_seconds(self : NoteEvent, bpm : Int) -> Double {
  let quarter_sec = 60.0 / bpm.to_double()
  self.duration * quarter_sec
}

///|
pub fn NoteEvent::start_ticks(self : NoteEvent, ppq : Int) -> Int {
  (self.start * ppq.to_double()).to_int()
}

///|
pub fn NoteEvent::duration_ticks(self : NoteEvent, ppq : Int) -> Int {
  (self.duration * ppq.to_double()).to_int()
}

///|
pub fn NoteEvent::to_string(self : NoteEvent) -> String {
  "NoteEvent(start=\{self.start}, dur=\{self.duration}, midi=\{self.midi_note}, v=\{self.velocity}, ch=\{self.channel})"
}

///|
pub fn sort_note_events(events : Array[NoteEvent]) -> Array[NoteEvent] {
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
