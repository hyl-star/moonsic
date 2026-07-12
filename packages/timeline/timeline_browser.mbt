///|
pub fn note_events_to_browser_js(events : Array[NoteEvent]) -> String {
  let mut result = "window.MOONSIC_DEMO_EVENTS = [\n"
  for i = 0; i < events.length(); i = i + 1 {
    let event = events[i]
    let velocity = (event.velocity.to_double() / 127.0 * 100.0)
      .to_int()
      .to_double() /
      100.0
    result = result +
      "  { start: \{event.start}, duration: \{event.duration}, midi: \{event.midi_note}, velocity: \{velocity}, channel: \{event.channel} }"
    if i < events.length() - 1 {
      result = result + ","
    }
    result = result + "\n"
  }
  result + "];"
}
