// ============================================================
// v2 琶音 — 将和弦展开为顺序音符
// ============================================================

///|
/// 将和弦进行琶音化：每个和弦音按 step_duration 展开为顺序音符
pub fn arpeggiate(chords : Track, step_duration : Duration) -> Track {
  let new_events = []
  let mut cursor = 0.0
  for evt in chords.events {
    match evt {
      Chord(c) => {
        let step_beats = step_duration.beats()
        for p in c.pitches {
          let ne = Note(note_with_velocity(p, step_duration, c.velocity))
          new_events.push(ne)
          cursor = cursor + step_beats
        }
      }
      Note(_) | Rest(_) => {
        new_events.push(evt)
        cursor = cursor + evt.duration().beats()
      }
    }
  }
  {
    events: new_events,
    channel: chords.channel,
    program: chords.program,
    volume: chords.volume,
    pan: chords.pan,
    mute: chords.mute,
  }
}
