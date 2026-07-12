///|
pub fn bench_sort_note_events(count : Int) -> String {
  let events : Array[NoteEvent] = []
  for i = 0; i < count; i = i + 1 {
    events.push({
      start: (count - i).to_double(),
      duration: 1.0,
      midi_note: 60,
      velocity: 90,
      channel: 0,
    })
  }
  let sorted = sort_note_events(events)
  "sort_note_events count=\{count} first=\{sorted[0].start}"
}
