// v9 伴奏模板

///|
pub(all) enum AccompanimentStyle {
  BlockChords
  PopBallad
  SimpleArpeggio
  BassAndPad
}

///|
/// 从调性和罗马数字生成多轨伴奏
pub fn accompany(
  key : Key,
  progression_text : String,
  style : AccompanimentStyle,
  chord_dur : Duration,
) -> Array[Track] {
  let chords = roman_progression(key, progression_text, chord_dur)
  let voiced = voice_lead(chords)
  let tracks = []
  match style {
    BlockChords => {
      tracks.push(voiced)
    }
    PopBallad => {
      // voiced chords + root bass + up arpeggio
      tracks.push(voiced)
      tracks.push(bass_from_progression(chords, Root, 2))
      tracks.push(arpeggiate_with_style(chords, eighth(), Up))
    }
    SimpleArpeggio => {
      tracks.push(arpeggiate_with_style(chords, eighth(), UpDown))
    }
    BassAndPad => {
      tracks.push(voiced)
      tracks.push(bass_from_progression(chords, RootFifth, 2))
    }
  }
  tracks
}

///|
pub fn arpeggiate_with_style(chords : Track, step_dur : Duration, arp_style : ArpStyle) -> Track {
  match arp_style {
    Up => arpeggiate(chords, step_dur)
    Down => arpeggiate_down(chords, step_dur)
    UpDown => arpeggiate_updown(chords, step_dur)
    Alberti => arpeggiate_alberti(chords, step_dur)
  }
}

fn arpeggiate_down(chords : Track, step_dur : Duration) -> Track {
  let events = []
  for evt in chords.events {
    match evt {
      Chord(c) => {
        let n = c.pitches.length()
        let mut i = n - 1
        while i >= 0 {
          events.push(Note(note_with_velocity(c.pitches[i], step_dur, c.velocity)))
          i = i - 1
        }
      }
      _ => events.push(evt)
    }
  }
  track(events)
}

fn arpeggiate_updown(chords : Track, step_dur : Duration) -> Track {
  let events = []
  for evt in chords.events {
    match evt {
      Chord(c) => {
        let n = c.pitches.length()
        for i = 0; i < n; i = i + 1 {
          events.push(Note(note_with_velocity(c.pitches[i], step_dur, c.velocity)))
        }
        let mut j = n - 2
        while j >= 1 {
          events.push(Note(note_with_velocity(c.pitches[j], step_dur, c.velocity)))
          j = j - 1
        }
      }
      _ => events.push(evt)
    }
  }
  track(events)
}

fn arpeggiate_alberti(chords : Track, step_dur : Duration) -> Track {
  // Alberti bass pattern: low-high-middle-high
  let events = []
  for evt in chords.events {
    match evt {
      Chord(c) => {
        let n = c.pitches.length()
        if n >= 3 {
          events.push(Note(note_with_velocity(c.pitches[0], step_dur, c.velocity)))
          events.push(Note(note_with_velocity(c.pitches[n - 1], step_dur, c.velocity)))
          events.push(Note(note_with_velocity(c.pitches[1], step_dur, c.velocity)))
          events.push(Note(note_with_velocity(c.pitches[n - 1], step_dur, c.velocity)))
        } else if n >= 2 {
          events.push(Note(note_with_velocity(c.pitches[0], step_dur, c.velocity)))
          events.push(Note(note_with_velocity(c.pitches[1], step_dur, c.velocity)))
        }
      }
      _ => events.push(evt)
    }
  }
  track(events)
}
