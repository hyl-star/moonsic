// v9 低音生成器

///|
pub(all) enum BassStyle {
  Root
  RootFifth
  Octave
  Walking
}

///|
pub fn bass_from_progression(chords : Track, style : BassStyle, octave : Int) -> Track {
  let events = []
  for evt in chords.events {
    match evt {
      Chord(c) => {
        let root = if c.pitches.length() > 0 { c.pitches[0] } else { pitch(C, Natural, octave) }
        let dur = c.duration
        match style {
          Root => events.push(Note(note(root, dur)))
          RootFifth => {
            events.push(Note(note(root, quarter())))
            let fifth = root.transpose(7)
            events.push(Note(note(fifth, quarter())))
          }
          Octave => {
            events.push(Note(note(root, quarter())))
            let up = pitch(root.class, root.accidental, root.octave + 1)
            events.push(Note(note(up, quarter())))
          }
          Walking => {
            events.push(Note(note(root, eighth())))
            events.push(Note(note(root.transpose(2), eighth())))
            events.push(Note(note(root.transpose(4), eighth())))
            events.push(Note(note(root.transpose(7), eighth())))
          }
        }
      }
      _ => events.push(Rest(rest(evt.duration())))
    }
  }
  track(events)
}
