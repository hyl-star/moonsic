// ============================================================
// MidiScore + SimpleScore → MidiScore conversion
// ============================================================

///|
pub(all) struct MidiTrack {
  name : String
  program : Int
  channel : Int
  events : Array[MidiEvent]
}

///|
pub(all) struct MidiScore {
  ppq : Int
  tracks : Array[MidiTrack]
}

// --- event sorting ---

///|
fn event_priority(kind : MidiEventKind) -> Int {
  match kind {
    TrackName(name=_) => 0
    TimeSignatureMeta(numerator=_, denominator=_) => 1
    TempoChange(bpm=_) => 3
    ProgramChange(channel=_, program=_) => 4
    ControlChange(channel=_, controller=_, value=_) => 5
    NoteOff(channel=_, note=_, velocity=_) => 7
    NoteOn(channel=_, note=_, velocity=_) => 8
    EndOfTrack => 13
  }
}

///|
pub fn sort_midi_events(events : Array[MidiEvent]) -> Array[MidiEvent] {
  let n = events.length()
  for i = 1; i < n; i = i + 1 {
    let key = events[i]
    let mut j = i - 1
    while j >= 0 {
      let cur = events[j]
      if cur.tick > key.tick ||
        (
          cur.tick == key.tick &&
          event_priority(cur.kind) > event_priority(key.kind)
        ) {
        events[j + 1] = cur
        j = j - 1
      } else {
        break
      }
    }
    events[j + 1] = key
  }
  events
}

// --- conversion ---

///|
pub fn simple_score_to_midi_score(
  score : @score.SimpleScore,
  ppq : Int,
) -> MidiScore {
  let meta_events : Array[MidiEvent] = []
  meta_events.push({ tick: 0, kind: TrackName(name="Meta") })
  meta_events.push({ tick: 0, kind: TempoChange(bpm=score.tempo.bpm) })
  meta_events.push({
    tick: 0,
    kind: TimeSignatureMeta(
      numerator=score.time_signature.numerator,
      denominator=score.time_signature.denominator,
    ),
  })
  meta_events.push({ tick: 0, kind: EndOfTrack })

  let all_tracks : Array[MidiTrack] = [
    { name: "Meta", program: -1, channel: 0, events: meta_events },
  ]

  for track in score.tracks {
    let midi_events : Array[MidiEvent] = []
    let ch = match track.channel {
      Some(c) => c.value
      None => 0
    }
    let prog = match track.program {
      Some(p) => p.value
      None => -1
    }
    midi_events.push({ tick: 0, kind: TrackName(name="Track ch=\{ch}") })
    if prog >= 0 {
      midi_events.push({
        tick: 0,
        kind: ProgramChange(channel=ch, program=prog),
      })
    }
    // Flatten events
    let mut current_tick = 0
    for evt in track.events {
      let dur_ticks = match
        @time.rhythm_duration_to_ticks(evt_duration(evt), ppq) {
        Ok(t) => t
        Err(_) => 480
      }
      match evt {
        @score.Note(n) => {
          let midi = n.pitch.to_midi()
          let vel = n.velocity.value
          midi_events.push({
            tick: current_tick,
            kind: NoteOn(channel=ch, note=midi, velocity=vel),
          })
          midi_events.push({
            tick: current_tick + dur_ticks,
            kind: NoteOff(channel=ch, note=midi, velocity=vel),
          })
        }
        @score.Chord(c) => {
          let vel = c.velocity.value
          for p in c.pitches {
            let midi = p.to_midi()
            midi_events.push({
              tick: current_tick,
              kind: NoteOn(channel=ch, note=midi, velocity=vel),
            })
            midi_events.push({
              tick: current_tick + dur_ticks,
              kind: NoteOff(channel=ch, note=midi, velocity=vel),
            })
          }
        }
        @score.Rest(_) => ()
      }
      current_tick = current_tick + dur_ticks
    }
    let mut max_tick = 0
    for e in midi_events {
      if e.tick > max_tick {
        max_tick = e.tick
      }
    }
    midi_events.push({ tick: max_tick, kind: EndOfTrack })
    all_tracks.push({
      name: "Track ch=\{ch}",
      program: prog,
      channel: ch,
      events: midi_events,
    })
  }
  { ppq, tracks: all_tracks }
}

///|
fn evt_duration(evt : @score.SimpleEvent) -> @time.RhythmDuration {
  match evt {
    @score.Note(n) => n.duration
    @score.Rest(r) => r.duration
    @score.Chord(c) => c.duration
  }
}
