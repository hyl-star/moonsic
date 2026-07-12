///|
pub fn bench_wav_render(count : Int) -> String {
  let events : Array[@timeline.NoteEvent] = []
  for i = 0; i < count; i = i + 1 {
    events.push({
      start: i.to_double() * 0.1,
      duration: 0.05,
      midi_note: 60,
      velocity: 90,
      channel: 0,
    })
  }
  let config = default_wav_render_config()
  match note_events_to_wav_bytes_checked(events, config) {
    Ok(bytes) => "wav_render count=\{count} bytes=\{bytes.length()}"
    Err(e) => "wav_render error=\{e.to_string()}"
  }
}
