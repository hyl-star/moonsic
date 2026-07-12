///|
pub fn bench_timeline_to_web_events(count : Int) -> String {
  let events : Array[@timeline.NoteEvent] = []
  for i = 0; i < count; i = i + 1 {
    events.push({
      start: i.to_double() * 0.25,
      duration: 0.25,
      midi_note: 60 + i % 12,
      velocity: 90 + i % 20,
      channel: i % 16,
    })
  }
  let timeline = @timeline.timeline_from_events_checked(
    events,
    120,
    events.length().to_double() * 0.25,
  ).unwrap()
  let config = default_web_playback_config()
  let doc = timeline_to_web_events_checked(timeline, config).unwrap()
  "timeline_to_web_events count=\{count} events_out=\{doc.events.length()}"
}

///|
pub fn bench_web_event_document_to_json(count : Int) -> String {
  let events : Array[@timeline.NoteEvent] = []
  for i = 0; i < count; i = i + 1 {
    events.push({
      start: i.to_double() * 0.25,
      duration: 0.25,
      midi_note: 60 + i % 12,
      velocity: 90 + i % 20,
      channel: i % 16,
    })
  }
  let timeline = @timeline.timeline_from_events_checked(
    events,
    120,
    events.length().to_double() * 0.25,
  ).unwrap()
  let config = default_web_playback_config()
  let doc = timeline_to_web_events_checked(timeline, config).unwrap()
  let json = web_event_document_to_json(doc)
  "web_event_document_to_json count=\{count} json_len=\{json.length()}"
}

///|
pub fn bench_note_events_to_web_events(count : Int) -> String {
  let events : Array[@timeline.NoteEvent] = []
  for i = 0; i < count; i = i + 1 {
    events.push({
      start: i.to_double() * 0.25,
      duration: 0.25,
      midi_note: 60 + i % 12,
      velocity: 90 + i % 20,
      channel: i % 16,
    })
  }
  let config = default_web_playback_config()
  let doc = note_events_to_web_events(events, config)
  "note_events_to_web_events count=\{count} events_out=\{doc.events.length()}"
}
