///|
test "library identity" {
  assert_eq(@moonsic.name(), "moonsic")
  assert_eq(@moonsic.version(), "0.1.0")
}

///|
test "pitch_class_base_semitone" {
  assert_eq(@moonsic.C.base_semitone(), 0)
  assert_eq(@moonsic.D.base_semitone(), 2)
  assert_eq(@moonsic.E.base_semitone(), 4)
  assert_eq(@moonsic.F.base_semitone(), 5)
  assert_eq(@moonsic.G.base_semitone(), 7)
  assert_eq(@moonsic.A.base_semitone(), 9)
  assert_eq(@moonsic.B.base_semitone(), 11)
}

///|
test "pitch_class_to_string" {
  assert_eq(@moonsic.C.to_string(), "C")
  assert_eq(@moonsic.A.to_string(), "A")
}

///|
test "accidental_semitone_offset" {
  assert_eq(@moonsic.Natural.semitone_offset(), 0)
  assert_eq(@moonsic.Sharp.semitone_offset(), 1)
  assert_eq(@moonsic.Flat.semitone_offset(), -1)
}

///|
test "accidental_to_string" {
  assert_eq(@moonsic.Natural.to_string(), "")
  assert_eq(@moonsic.Sharp.to_string(), "#")
  assert_eq(@moonsic.Flat.to_string(), "b")
}

///|
test "pitch_to_midi" {
  let p = @moonsic.pitch
  assert_eq(p(@moonsic.C, @moonsic.Natural, 4).to_midi(), 60)
  assert_eq(p(@moonsic.A, @moonsic.Natural, 4).to_midi(), 69)
  assert_eq(p(@moonsic.C, @moonsic.Sharp, 4).to_midi(), 61)
  assert_eq(p(@moonsic.D, @moonsic.Flat, 4).to_midi(), 61)
  assert_eq(p(@moonsic.B, @moonsic.Natural, 3).to_midi(), 59)
  assert_eq(p(@moonsic.C, @moonsic.Natural, -1).to_midi(), 0)
  assert_eq(p(@moonsic.G, @moonsic.Natural, 9).to_midi(), 127)
}

///|
test "pitch_transpose" {
  let p = @moonsic.pitch
  let c4 = p(@moonsic.C, @moonsic.Natural, 4)
  assert_eq(c4.transpose(2).to_midi(), 62)
  assert_eq(c4.transpose(-12).to_midi(), 48)
}

///|
test "midi_to_pitch_roundtrip" {
  let result = @moonsic.midi_to_pitch(60)
  assert_eq(result.to_midi(), 60)
  assert_eq(result.to_string(), "C4")
}

///|
test "duration_beats" {
  assert_eq(@moonsic.Whole.beats(), 4.0)
  assert_eq(@moonsic.Half.beats(), 2.0)
  assert_eq(@moonsic.Quarter.beats(), 1.0)
  assert_eq(@moonsic.Eighth.beats(), 0.5)
  assert_eq(@moonsic.Sixteenth.beats(), 0.25)
}

///|
test "duration_ticks" {
  assert_eq(@moonsic.Quarter.ticks(480), 480)
  assert_eq(@moonsic.Whole.ticks(480), 1920)
  assert_eq(@moonsic.Half.ticks(480), 960)
  assert_eq(@moonsic.Eighth.ticks(480), 240)
  assert_eq(@moonsic.Sixteenth.ticks(480), 120)
  assert_eq(@moonsic.Quarter.ticks(960), 960)
}

///|
test "duration_seconds" {
  assert_eq(@moonsic.Quarter.seconds(120), 0.5)
  assert_eq(@moonsic.Half.seconds(120), 1.0)
  assert_eq(@moonsic.Eighth.seconds(120), 0.25)
  assert_eq(@moonsic.Quarter.seconds(60), 1.0)
  assert_eq(@moonsic.Quarter.seconds(240), 0.25)
}

///|
test "tempo" {
  let t = @moonsic.tempo(120)
  assert_eq(t.quarter_seconds(), 0.5)
  let t60 = @moonsic.tempo(60)
  assert_eq(t60.quarter_seconds(), 1.0)
  assert_true(@moonsic.is_valid_bpm(120))
  assert_false(@moonsic.is_valid_bpm(0))
}

///|
test "time_signature" {
  let ts = @moonsic.four_four()
  assert_eq(ts.numerator, 4)
  assert_eq(ts.denominator, 4)
  assert_true(@moonsic.is_valid_time_signature(4, 4))
  assert_true(@moonsic.is_valid_time_signature(3, 4))
  assert_false(@moonsic.is_valid_time_signature(0, 4))
  assert_false(@moonsic.is_valid_time_signature(4, 5))
}

///|
test "is_valid_midi_note" {
  assert_true(@moonsic.is_valid_midi_note(0))
  assert_true(@moonsic.is_valid_midi_note(127))
  assert_false(@moonsic.is_valid_midi_note(-1))
  assert_false(@moonsic.is_valid_midi_note(128))
}

///|
test "is_valid_velocity" {
  assert_true(@moonsic.is_valid_velocity(0))
  assert_true(@moonsic.is_valid_velocity(127))
  assert_false(@moonsic.is_valid_velocity(-1))
  assert_false(@moonsic.is_valid_velocity(128))
}

///|
test "is_valid_channel" {
  assert_true(@moonsic.is_valid_channel(0))
  assert_true(@moonsic.is_valid_channel(15))
  assert_false(@moonsic.is_valid_channel(-1))
  assert_false(@moonsic.is_valid_channel(16))
}

///|
test "note_default_velocity" {
  let p = @moonsic.pitch
  let n = @moonsic.note(p(@moonsic.C, @moonsic.Natural, 4), @moonsic.Quarter)
  assert_eq(n.velocity, 100)
}

///|
test "note_with_explicit_velocity" {
  let p = @moonsic.pitch
  let n = @moonsic.note_with_velocity(
    p(@moonsic.C, @moonsic.Natural, 4),
    @moonsic.Quarter,
    64,
  )
  assert_eq(n.velocity, 64)
}

///|
test "note_transpose" {
  let p = @moonsic.pitch
  let n = @moonsic.note(p(@moonsic.C, @moonsic.Natural, 4), @moonsic.Quarter)
  let t = n.transpose(2)
  assert_eq(t.pitch.to_midi(), 62)
  assert_eq(t.duration.beats(), 1.0)
  assert_eq(t.velocity, 100)
}

///|
test "track_duration_beats" {
  let p = @moonsic.pitch
  let track = @moonsic.track([
    @moonsic.Note(
      @moonsic.note(p(@moonsic.C, @moonsic.Natural, 4), @moonsic.Quarter),
    ),
    @moonsic.Note(
      @moonsic.note(p(@moonsic.D, @moonsic.Natural, 4), @moonsic.Half),
    ),
  ])
  assert_eq(track.duration_beats(), 3.0)
}

///|
test "track_repeat" {
  let p = @moonsic.pitch
  let track = @moonsic.track([
    @moonsic.Note(
      @moonsic.note(p(@moonsic.C, @moonsic.Natural, 4), @moonsic.Quarter),
    ),
  ])
  let r0 = track.repeat(0)
  assert_eq(r0.event_count(), 0)
  let r1 = track.repeat(1)
  assert_eq(r1.event_count(), 1)
  let r2 = track.repeat(2)
  assert_eq(r2.event_count(), 2)
}

///|
test "score_duration_beats" {
  let p = @moonsic.pitch
  let track1 = @moonsic.track([
    @moonsic.Note(
      @moonsic.note(p(@moonsic.C, @moonsic.Natural, 4), @moonsic.Quarter),
    ),
    @moonsic.Note(
      @moonsic.note(p(@moonsic.D, @moonsic.Natural, 4), @moonsic.Quarter),
    ),
  ])
  let track2 = @moonsic.track([
    @moonsic.Note(
      @moonsic.note(p(@moonsic.E, @moonsic.Natural, 4), @moonsic.Whole),
    ),
  ])
  let score = @moonsic.score([track1, track2])
  assert_eq(score.duration_beats(), 4.0)
}

///|
test "track_to_note_events" {
  let p = @moonsic.pitch
  let track = @moonsic.track([
    @moonsic.Note(
      @moonsic.note(p(@moonsic.C, @moonsic.Natural, 4), @moonsic.Quarter),
    ),
    @moonsic.Rest(@moonsic.rest(@moonsic.Quarter)),
    @moonsic.Note(
      @moonsic.note(p(@moonsic.D, @moonsic.Natural, 4), @moonsic.Half),
    ),
  ])
  let events = track.to_note_events()
  assert_eq(events.length(), 2)
  assert_eq(events[0].start, 0.0)
  assert_eq(events[0].duration, 1.0)
  assert_eq(events[0].midi_note, 60)
  assert_eq(events[1].start, 2.0)
  assert_eq(events[1].duration, 2.0)
  assert_eq(events[1].midi_note, 62)
}

///|
test "note_event_end" {
  let p = @moonsic.pitch
  let track = @moonsic.track([
    @moonsic.Note(
      @moonsic.note(p(@moonsic.C, @moonsic.Natural, 4), @moonsic.Quarter),
    ),
  ])
  let events = track.to_note_events()
  assert_eq(events[0].end(), 1.0)
}

///|
test "track_channel" {
  let p = @moonsic.pitch
  let track = @moonsic.track_with_channel(
    [
      @moonsic.Note(
        @moonsic.note(p(@moonsic.C, @moonsic.Natural, 4), @moonsic.Quarter),
      ),
    ],
    3,
  )
  let events = track.to_note_events()
  assert_eq(events[0].channel, 3)
}

///|
test "note_event_time_conversion" {
  let p = @moonsic.pitch
  let track = @moonsic.track([
    @moonsic.Note(
      @moonsic.note(p(@moonsic.C, @moonsic.Natural, 4), @moonsic.Quarter),
    ),
  ])
  let events = track.to_note_events()
  assert_eq(events[0].start_seconds(120), 0.0)
  assert_eq(events[0].duration_seconds(120), 0.5)
  assert_eq(events[0].start_ticks(480), 0)
  assert_eq(events[0].duration_ticks(480), 480)
}

///|
test "track_transpose_runtime" {
  let p = @moonsic.pitch
  let track = @moonsic.track([
    @moonsic.Note(
      @moonsic.note(p(@moonsic.C, @moonsic.Natural, 4), @moonsic.Quarter),
    ),
  ])
  let t = track.transpose(2)
  let events = t.to_note_events()
  assert_eq(events[0].midi_note, 62)
}

///|
test "score_to_note_events" {
  let p = @moonsic.pitch
  let track1 = @moonsic.track_with_channel(
    [
      @moonsic.Note(
        @moonsic.note(p(@moonsic.C, @moonsic.Natural, 4), @moonsic.Quarter),
      ),
    ],
    0,
  )
  let track2 = @moonsic.track_with_channel(
    [
      @moonsic.Note(
        @moonsic.note(p(@moonsic.E, @moonsic.Natural, 4), @moonsic.Quarter),
      ),
    ],
    1,
  )
  let score = @moonsic.score([track1, track2])
  let events = score.to_note_events()
  assert_eq(events.length(), 2)
  assert_eq(events[0].midi_note, 60)
  assert_eq(events[0].channel, 0)
  assert_eq(events[1].midi_note, 64)
  assert_eq(events[1].channel, 1)
}

///|
test "midi_to_frequency" {
  let f = @moonsic.midi_to_frequency(69)
  assert_true(f > 439.9 && f < 440.1)
  let f60 = @moonsic.midi_to_frequency(60)
  assert_true(f60 > 261.0 && f60 < 262.0)
}

///|
test "pitch_frequency" {
  let p = @moonsic.pitch
  let a4 = p(@moonsic.A, @moonsic.Natural, 4)
  let freq = a4.frequency()
  assert_true(freq > 439.9 && freq < 440.1)
}

///|
test "midi_export_not_empty" {
  let p = @moonsic.pitch
  let track = @moonsic.track([
    @moonsic.Note(
      @moonsic.note(p(@moonsic.C, @moonsic.Natural, 4), @moonsic.Quarter),
    ),
  ])
  let score = @moonsic.score([track])
  let bytes = score.to_midi_bytes()
  assert_true(bytes.length() > 0)
}

///|
test "midi_export_roundtrip" {
  let p = @moonsic.pitch
  let track = @moonsic.track([
    @moonsic.Note(
      @moonsic.note(p(@moonsic.C, @moonsic.Natural, 4), @moonsic.Quarter),
    ),
    @moonsic.Note(
      @moonsic.note(p(@moonsic.D, @moonsic.Natural, 4), @moonsic.Quarter),
    ),
  ])
  let score = @moonsic.score([track])
  let bytes = score.to_midi_bytes()
  let file = @midi.parse(bytes)
  assert_eq(file.tracks.length(), 2)
  assert_eq(file.division, @moonsic.DEFAULT_PPQ.to_uint16())
}

///|
test "midi_export_has_meta_track" {
  let p = @moonsic.pitch
  let track = @moonsic.track([
    @moonsic.Note(
      @moonsic.note(p(@moonsic.C, @moonsic.Natural, 4), @moonsic.Quarter),
    ),
  ])
  let score = @moonsic.score([track])
  let bytes = score.to_midi_bytes()
  let file = @midi.parse(bytes)
  assert_true(file.tracks[0].events.length() >= 3)
}

// --- v1.5 ergonomic API tests ---
