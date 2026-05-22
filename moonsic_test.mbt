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

///|
test "natural_pitch" {
  assert_eq(@moonsic.natural_pitch(@moonsic.C, 4).to_midi(), 60)
  assert_eq(@moonsic.natural_pitch(@moonsic.A, 4).to_midi(), 69)
}

///|
test "pitch_shortcuts_natural" {
  assert_eq(@moonsic.c(4).to_midi(), 60)
  assert_eq(@moonsic.d(4).to_midi(), 62)
  assert_eq(@moonsic.e(4).to_midi(), 64)
  assert_eq(@moonsic.f(4).to_midi(), 65)
  assert_eq(@moonsic.g(4).to_midi(), 67)
  assert_eq(@moonsic.a(4).to_midi(), 69)
  assert_eq(@moonsic.b(4).to_midi(), 71)
}

///|
test "pitch_shortcuts_sharp" {
  assert_eq(@moonsic.cs(4).to_midi(), 61)
  assert_eq(@moonsic.ds(4).to_midi(), 63)
  assert_eq(@moonsic.fs(4).to_midi(), 66)
  assert_eq(@moonsic.gs(4).to_midi(), 68)
}

///|
test "pitch_shortcuts_flat" {
  assert_eq(@moonsic.db(4).to_midi(), 61)
  assert_eq(@moonsic.eb(4).to_midi(), 63)
  assert_eq(@moonsic.gb(4).to_midi(), 66)
  assert_eq(@moonsic.ab(4).to_midi(), 68)
  assert_eq(@moonsic.bb(4).to_midi(), 70)
}

///|
test "duration_shortcuts" {
  assert_eq(@moonsic.quarter().beats(), 1.0)
  assert_eq(@moonsic.half().ticks(480), 960)
  assert_eq(@moonsic.whole().beats(), 4.0)
  assert_eq(@moonsic.eighth().beats(), 0.5)
  assert_eq(@moonsic.sixteenth().beats(), 0.25)
}

///|
test "event_shortcuts" {
  let evt = @moonsic.n(@moonsic.c(4), @moonsic.quarter())
  assert_eq(evt.duration().beats(), 1.0)
  let rest_evt = @moonsic.r(@moonsic.half())
  assert_eq(rest_evt.duration().beats(), 2.0)
  let vel_evt = @moonsic.nv(@moonsic.c(4), @moonsic.quarter(), 64)
  assert_eq(vel_evt.duration().beats(), 1.0)
}

///|
test "track_score_builders" {
  let lead = @moonsic.melody([
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
  ])
  assert_eq(lead.event_count(), 2)
  let song = @moonsic.score1(lead)
  assert_eq(song.track_count(), 1)
  let song2 = @moonsic.score_with([lead], 120, @moonsic.four_four())
  assert_eq(song2.track_count(), 1)
}

///|
test "note_event_frequency" {
  let track = @moonsic.melody([@moonsic.n(@moonsic.a(4), @moonsic.quarter())])
  let events = track.to_note_events()
  let freq = events[0].frequency()
  assert_true(freq > 439.9 && freq < 440.1)
}

///|
test "dotted_duration_beats" {
  assert_eq(@moonsic.dotted(@moonsic.quarter()).beats(), 1.5)
  assert_eq(@moonsic.dotted(@moonsic.half()).beats(), 3.0)
  assert_eq(@moonsic.dotted(@moonsic.eighth()).beats(), 0.75)
}

///|
test "dotted_duration_ticks" {
  assert_eq(@moonsic.dotted(@moonsic.quarter()).ticks(480), 720)
  assert_eq(@moonsic.dotted(@moonsic.half()).ticks(480), 1440)
}

///|
test "dotted_duration_seconds" {
  assert_eq(@moonsic.dotted(@moonsic.quarter()).seconds(120), 0.75)
}

///|
test "dotted_in_track_flattening" {
  let track = @moonsic.melody([
    @moonsic.n(@moonsic.c(4), @moonsic.dotted(@moonsic.quarter())),
  ])
  let events = track.to_note_events()
  assert_eq(events[0].duration, 1.5)
}

///|
test "major_chord_midi" {
  let evt = @moonsic.major(@moonsic.c(4), @moonsic.quarter())
  // C major = C4(60) E4(64) G4(67)
  let track = @moonsic.melody([evt])
  let events = track.to_note_events()
  assert_eq(events.length(), 3)
  assert_eq(events[0].midi_note, 60)
  assert_eq(events[1].midi_note, 64)
  assert_eq(events[2].midi_note, 67)
  // All have same start and duration
  assert_eq(events[0].start, 0.0)
  assert_eq(events[1].start, 0.0)
  assert_eq(events[2].start, 0.0)
}

///|
test "minor_chord_midi" {
  let evt = @moonsic.minor(@moonsic.a(3), @moonsic.quarter())
  // A minor = A3(57) C4(60) E4(64)
  let track = @moonsic.melody([evt])
  let events = track.to_note_events()
  assert_eq(events.length(), 3)
  assert_eq(events[0].midi_note, 57)
  assert_eq(events[1].midi_note, 60)
  assert_eq(events[2].midi_note, 64)
}

///|
test "chord_transpose" {
  let evt = @moonsic.major(@moonsic.c(4), @moonsic.quarter())
  let transposed = evt.transpose(2)
  let track = @moonsic.melody([transposed])
  let events = track.to_note_events()
  // D major = D4(62) F#4(66) A4(69)
  assert_eq(events[0].midi_note, 62)
  assert_eq(events[1].midi_note, 66)
  assert_eq(events[2].midi_note, 69)
}

///|
test "chord_cursor_advances_once" {
  let track = @moonsic.melody([
    @moonsic.major(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
  ])
  let events = track.to_note_events()
  // 3 chord tones + 1 note = 4 events
  assert_eq(events.length(), 4)
  // D4 starts after the chord (1 beat later)
  assert_eq(events[3].midi_note, 62)
  assert_eq(events[3].start, 1.0)
}

///|
test "chord_midi_export" {
  let lead = @moonsic.melody([@moonsic.major(@moonsic.c(4), @moonsic.quarter())])
  let score = @moonsic.score1(lead)
  let bytes = score.to_midi_bytes()
  let file = @midi.parse(bytes)
  // meta track + 1 music track
  assert_eq(file.tracks.length(), 2)
}

// --- v2 theory tests ---

///|
test "scale_major_c" {
  let s = @moonsic.scale(@moonsic.c(4), @moonsic.Major, 1)
  assert_eq(s.length(), 7)
  assert_eq(s[0].to_midi(), 60) // C4
  assert_eq(s[2].to_midi(), 64) // E4
  assert_eq(s[4].to_midi(), 67) // G4
}

///|
test "scale_minor_a" {
  let s = @moonsic.scale(@moonsic.a(3), @moonsic.NaturalMinor, 1)
  assert_eq(s.length(), 7)
  assert_eq(s[0].to_midi(), 57) // A3
  assert_eq(s[2].to_midi(), 60) // C4
}

///|
test "degree_helper" {
  assert_eq(@moonsic.degree(@moonsic.c(4), @moonsic.Major, 1).to_midi(), 60) // C4
  assert_eq(@moonsic.degree(@moonsic.c(4), @moonsic.Major, 5).to_midi(), 67) // G4
  assert_eq(@moonsic.degree(@moonsic.c(4), @moonsic.Major, 8).to_midi(), 72) // C5
}

///|
test "progression_I_V_vi_IV" {
  let chords = @moonsic.progression(
    @moonsic.c(3),
    @moonsic.Major,
    [@moonsic.I, @moonsic.V, @moonsic.VI, @moonsic.IV],
    @moonsic.half(),
  )
  assert_eq(chords.event_count(), 4)
  // 展平验证 MIDI 值
  let events = chords.to_note_events()
  // I = C major: C3(48) E3(52) G3(55)
  assert_eq(events[0].midi_note, 48)
  assert_eq(events[1].midi_note, 52)
  assert_eq(events[2].midi_note, 55)
}

///|
test "progression_timing" {
  let chords = @moonsic.progression(
    @moonsic.c(3),
    @moonsic.Major,
    [@moonsic.I, @moonsic.IV],
    @moonsic.quarter(),
  )
  let events = chords.to_note_events()
  // I: 3 notes at start=0, IV: 3 notes at start=1
  assert_eq(events[0].start, 0.0) // I tones
  assert_eq(events[3].start, 1.0) // IV tones
}

// --- v2 pattern tests ---

///|
test "track_concat" {
  let a = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let b = @moonsic.melody([@moonsic.n(@moonsic.d(4), @moonsic.quarter())])
  let ab = a.concat(b)
  assert_eq(ab.event_count(), 2)
  assert_eq(ab.duration_beats(), 2.0)
}

///|
test "track_reverse" {
  let t = @moonsic.melody([
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.half()),
  ])
  let rev = t.reverse()
  assert_eq(rev.event_count(), 2)
  assert_eq(rev.duration_beats(), t.duration_beats())
}

///|
test "track_stretch" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let t2 = t.stretch(2.0)
  assert_eq(t2.duration_beats(), 2.0)
}

///|
test "track_map_velocity" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let louder = t.map_velocity(fn(v) { v + 20 })
  let events = louder.to_note_events()
  assert_eq(events[0].velocity, 120)
}

///|
test "track_up_down_octave" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let up = t.up_octave()
  let events = up.to_note_events()
  assert_eq(events[0].midi_note, 72) // C5
  let down = t.down_octave()
  let down_events = down.to_note_events()
  assert_eq(down_events[0].midi_note, 48) // C3
}

// --- v2 instrument tests ---

///|
test "instrument_constants" {
  assert_eq(@moonsic.acoustic_grand_piano(), 0)
  assert_eq(@moonsic.violin(), 40)
  assert_eq(@moonsic.synth_lead_square(), 80)
}

///|
test "instrument_track" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let t2 = @moonsic.instrument(t, @moonsic.acoustic_grand_piano())
  // program 被设置
  let events = t2.to_note_events()
  assert_eq(events.length(), 1)
}

///|
test "midi_export_with_instrument" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let t2 = @moonsic.instrument(t, @moonsic.violin())
  let score = @moonsic.score1(t2)
  let bytes = score.to_midi_bytes()
  let file = @midi.parse(bytes)
  // meta track + 1 music track = 2
  assert_eq(file.tracks.length(), 2)
}

// --- v2 arpeggio + drum tests ---

///|
test "arpeggiate_chord" {
  let chords = @moonsic.progression(
    @moonsic.c(3),
    @moonsic.Major,
    [@moonsic.I],
    @moonsic.half(),
  )
  let arp = @moonsic.arpeggiate(chords, @moonsic.eighth())
  let events = arp.to_note_events()
  // C major chord: C3 E3 G3 → 3 sequential notes
  assert_eq(events.length(), 3)
  assert_eq(events[0].midi_note, 48) // C3
  assert_eq(events[1].midi_note, 52) // E3
  assert_eq(events[2].midi_note, 55) // G3
}

///|
test "drum_constants" {
  assert_eq(@moonsic.KICK, 36)
  assert_eq(@moonsic.SNARE, 38)
  assert_eq(@moonsic.CLOSED_HAT, 42)
  assert_eq(@moonsic.DRUM_CHANNEL, 9)
}

///|
test "basic_beat_bars" {
  let beat = @moonsic.basic_beat(1)
  // 3 tracks: kick, snare, hat
  assert_eq(beat.track_count(), 3)
  let events = beat.to_note_events()
  // kick(2) + snare(2) + hat(8) = 12 events per bar
  assert_eq(events.length(), 12)
}

///|
test "basic_beat_midi_export" {
  let beat = @moonsic.basic_beat(1)
  let song = @moonsic.score_with([beat.tracks[0]], 120, @moonsic.four_four())
  let bytes = song.to_midi_bytes()
  assert_true(bytes.length() > 0)
}
