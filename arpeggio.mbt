// 琶音 — 将和弦展开为顺序音符

///|
pub(all) enum ArpStyle { Up; Down; UpDown; Alberti }

///|
pub fn arpeggiate(chords : Track, step_duration : Duration) -> Track {
  arpeggiate_dir(chords, step_duration, Up)
}

fn arpeggiate_dir(chords : Track, step_dur : Duration, style : ArpStyle) -> Track {
  let new_events = []
  for evt in chords.events {
    match evt {
      Chord(c) => {
        let pitches = order_pitches(c.pitches, style)
        for p in pitches {
          new_events.push(Note(note_with_velocity(p, step_dur, c.velocity)))
        }
      }
      _ => new_events.push(evt)
    }
  }
  { events: new_events, channel: chords.channel, program: chords.program, volume: chords.volume, pan: chords.pan, mute: chords.mute }
}

fn order_pitches(pitches : Array[Pitch], style : ArpStyle) -> Array[Pitch] {
  let n = pitches.length()
  match style {
    Up => { let result = []; for i = 0; i < n; i = i + 1 { result.push(pitches[i]) }; result }
    Down => { let result = []; let mut i = n - 1; while i >= 0 { result.push(pitches[i]); i = i - 1 }; result }
    UpDown => {
      let result = []
      for i = 0; i < n; i = i + 1 { result.push(pitches[i]) }
      let mut j = n - 2
      while j >= 1 { result.push(pitches[j]); j = j - 1 }
      result
    }
    Alberti => {
      let result = []
      if n >= 3 {
        result.push(pitches[0])
        result.push(pitches[n - 1])
        result.push(pitches[1])
        result.push(pitches[n - 1])
      } else { for p in pitches { result.push(p) } }
      result
    }
  }
}
