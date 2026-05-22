// v9 低音生成器

///|
pub(all) enum BassStyle {
  Root
  RootFifth
  Octave
  Walking
}

///|
pub fn bass_from_progression(
  chords : Track,
  style : BassStyle,
  octave : Int,
) -> Track {
  let events = []
  for evt in chords.events {
    match evt {
      Chord(c) => {
        let orig_root = if c.pitches.length() > 0 {
          c.pitches[0]
        } else {
          pitch(C, Natural, octave)
        }
        // apply octave: move root to target octave
        let root = pitch(orig_root.class, orig_root.accidental, octave)
        let dur_beats = c.duration.beats()
        match style {
          Root => events.push(Note(note(root, c.duration)))
          RootFifth => {
            let step_beats = if dur_beats >= 2.0 {
              1.0
            } else {
              dur_beats / 2.0
            }
            let step_dur = duration_from_beats(step_beats)
            let steps = (dur_beats / step_beats).to_int()
            for i = 0; i < steps; i = i + 1 {
              let p = if i % 2 == 0 { root } else { root.transpose(7) }
              events.push(Note(note(p, step_dur)))
            }
          }
          Octave => {
            let step_beats = if dur_beats >= 2.0 {
              1.0
            } else {
              dur_beats / 2.0
            }
            let step_dur = duration_from_beats(step_beats)
            let steps = (dur_beats / step_beats).to_int()
            let up = pitch(root.class, root.accidental, root.octave + 1)
            for i = 0; i < steps; i = i + 1 {
              let p = if i % 2 == 0 { root } else { up }
              events.push(Note(note(p, step_dur)))
            }
          }
          Walking => {
            let steps = (dur_beats / 0.5).to_int()
            let walk_offsets = [0, 2, 4, 7]
            for i = 0; i < steps; i = i + 1 {
              let off = walk_offsets[i % walk_offsets.length()]
              events.push(Note(note(root.transpose(off), eighth())))
            }
          }
        }
      }
      _ => events.push(Rest(rest(evt.duration())))
    }
  }
  track(events)
}
