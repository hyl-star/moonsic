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

// --- v3 harmony tests ---

///|
test "dim_chord" {
  let evt = @moonsic.dim(@moonsic.b(3), @moonsic.half())
  let track = @moonsic.melody([evt])
  let events = track.to_note_events()
  // B dim = B(59) D(62) F(65)
  assert_eq(events.length(), 3)
  assert_eq(events[0].midi_note, 59)
  assert_eq(events[1].midi_note, 62)
  assert_eq(events[2].midi_note, 65)
}

///|
test "dom7_chord" {
  let evt = @moonsic.dom7(@moonsic.g(3), @moonsic.half())
  let track = @moonsic.melody([evt])
  let events = track.to_note_events()
  // G7 = G(55) B(59) D(62) F(65)
  assert_eq(events.length(), 4)
  assert_eq(events[0].midi_note, 55)
  assert_eq(events[3].midi_note, 65)
}

///|
test "chord_invert" {
  let c = @moonsic.chord(
    [@moonsic.c(4), @moonsic.e(4), @moonsic.g(4)],
    @moonsic.quarter(),
  )
  let inv1 = c.invert(1) // first inversion: E G C5
  assert_eq(inv1.pitches[0].to_midi(), 64) // E4
  assert_eq(inv1.pitches[2].to_midi(), 72) // C5
}

///|
test "minor_progression" {
  let chords = @moonsic.progression(
    @moonsic.a(3),
    @moonsic.NaturalMinor,
    [@moonsic.I, @moonsic.IV, @moonsic.V],
    @moonsic.quarter(),
  )
  let events = chords.to_note_events()
  // Am: i = A C E (minor), iv = D F A (minor), v = E G B (minor)
  assert_eq(events[0].midi_note, 57) // A3
  assert_eq(events[3].midi_note, 62) // D4
}

// --- v3 key tests ---

///|
test "key_degree_f_major" {
  let k = @moonsic.key(@moonsic.f(4), @moonsic.Major)
  // F major degree 4 should be Bb, not A#
  let p = k.degree(4, 4)
  assert_eq(p.to_midi(), 70) // Bb4 = 70
  assert_eq(p.to_string(), "Bb4")
}

///|
test "key_scale_g_major" {
  let k = @moonsic.key(@moonsic.g(4), @moonsic.Major)
  let s = k.scale(4, 1)
  assert_eq(s.length(), 7)
  // G major: G A B C D E F#
  assert_eq(s[6].to_string(), "F#4")
}

///|
test "wav_bytes_not_empty" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let score = @moonsic.score1(t)
  let wav = score.to_wav_bytes()
  assert_true(wav.length() > 44)
}

///|
test "wav_header_riff_wave" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let score = @moonsic.score1(t)
  let wav = score.to_wav_bytes()
  // RIFF header
  assert_eq(wav[0], b'R')
  assert_eq(wav[1], b'I')
  assert_eq(wav[2], b'F')
  assert_eq(wav[3], b'F')
  // WAVE
  assert_eq(wav[8], b'W')
  assert_eq(wav[9], b'A')
  assert_eq(wav[10], b'V')
  assert_eq(wav[11], b'E')
  // fmt
  assert_eq(wav[12], b'f')
  assert_eq(wav[13], b'm')
  assert_eq(wav[14], b't')
  // data
  assert_eq(wav[36], b'd')
  assert_eq(wav[37], b'a')
  assert_eq(wav[38], b't')
  assert_eq(wav[39], b'a')
}

///|
test "melody_str_chord" {
  let t = @moonsic.melody_str("[C4 E4 G4]h")
  let events = t.to_note_events()
  assert_eq(events.length(), 3)
  assert_eq(events[0].midi_note, 60)
  assert_eq(events[2].midi_note, 67)
}

///|
test "melody_str_velocity" {
  let t = @moonsic.melody_str("C4q:64 D4q:80")
  let events = t.to_note_events()
  assert_eq(events[0].velocity, 64)
  assert_eq(events[1].velocity, 80)
}

///|
test "melody_str_repeat" {
  let t = @moonsic.melody_str("C4q x4")
  assert_eq(t.event_count(), 4)
}

///|
test "score_str_tempo_time" {
  let s = @moonsic.score_str("tempo 140\ntime 3/4\nC4q D4q")
  assert_eq(s.tempo.bpm, 140)
  assert_eq(s.time_signature.numerator, 3)
}

///|
test "pitch_midi_boundary" {
  let p = @moonsic.pitch
  assert_eq(p(@moonsic.C, @moonsic.Natural, -1).to_midi(), 0)
  assert_eq(p(@moonsic.G, @moonsic.Natural, 9).to_midi(), 127)
}

///|
test "pitch_enharmonic" {
  let p = @moonsic.pitch
  assert_eq(
    p(@moonsic.C, @moonsic.Sharp, 4).to_midi(),
    p(@moonsic.D, @moonsic.Flat, 4).to_midi(),
  )
}

///|
test "midi_to_pitch_roundtrip_extended" {
  for i = 0; i < 128; i = i + 1 {
    let pitch = @moonsic.midi_to_pitch(i)
    assert_eq(pitch.to_midi(), i)
  }
}

///|
test "duration_dotted_edge" {
  assert_eq(@moonsic.dotted(@moonsic.dotted(@moonsic.quarter())).beats(), 2.25)
  assert_eq(@moonsic.dotted(@moonsic.whole()).beats(), 6.0)
}

///|
test "chord_empty_pitches" {
  let c = @moonsic.chord([], @moonsic.quarter())
  assert_eq(c.pitches.length(), 0)
}

///|
test "music_event_transpose_rest" {
  let evt = @moonsic.r(@moonsic.quarter())
  let t = evt.transpose(5)
  assert_eq(t.duration().beats(), 1.0)
}

///|
test "track_empty" {
  let t = @moonsic.empty_track()
  assert_eq(t.event_count(), 0)
  assert_eq(t.duration_beats(), 0.0)
  assert_eq(t.to_note_events().length(), 0)
}

///|
test "track_repeat_zero" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let r = t.repeat(0)
  assert_eq(r.event_count(), 0)
}

///|
test "track_metadata_after_concat" {
  let a = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
    .with_volume(0.5)
    .with_pan(0.3)
  let b = @moonsic.melody([@moonsic.n(@moonsic.d(4), @moonsic.quarter())])
  let c = a.concat(b)
  assert_eq(c.to_note_events().length(), 2)
}

///|
test "score_master_gain_default" {
  let s = @moonsic.score1(@moonsic.empty_track())
  assert_true(s.master_gain > 0.0)
}

///|
test "score_transpose_preserves_tempo" {
  let s = @moonsic.score_with(
    [@moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])],
    140,
    @moonsic.four_four(),
  )
  let t = s.transpose(2)
  assert_eq(t.tempo.bpm, 140)
  assert_eq(t.time_signature.numerator, 4)
}

///|
test "score_empty" {
  let s = @moonsic.score([])
  assert_eq(s.track_count(), 0)
  assert_eq(s.duration_beats(), 0.0)
}

///|
test "midi_export_drum_channel" {
  let t = @moonsic.track_with_channel(
    [@moonsic.n(@moonsic.c(4), @moonsic.quarter())],
    9,
  )
  let s = @moonsic.score1(t)
  assert_true(s.to_midi_bytes().length() > 0)
}

///|
test "wav_bytes_has_data" {
  let s = @moonsic.score1(
    @moonsic.melody([
      @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
      @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
    ]),
  )
  assert_true(s.to_wav_bytes().length() > 100)
}

///|
test "wav_header_channels_mono" {
  let s = @moonsic.score1(
    @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())]),
  )
  let wav = s.to_wav_bytes()
  assert_eq(wav[22], (1).to_byte())
}

///|
test "wav_chord_mix" {
  let s = @moonsic.score1(
    @moonsic.melody([@moonsic.major(@moonsic.c(4), @moonsic.quarter())]),
  )
  assert_true(s.to_wav_bytes().length() > 44)
}

///|
test "browser_js_output_shape" {
  let s = @moonsic.score1(
    @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())]),
  )
  let js = @moonsic.note_events_to_browser_js(s.to_note_events())
  assert_true(js.length() > 30)
}

///|
test "scale_two_octaves" {
  let s = @moonsic.scale(@moonsic.c(4), @moonsic.Major, 2)
  assert_eq(s.length(), 14)
  assert_eq(s[0].to_midi(), 60)
  assert_eq(s[7].to_midi(), 72)
}

///|
test "degree_9th" {
  let p = @moonsic.degree(@moonsic.c(4), @moonsic.Major, 9)
  assert_eq(p.to_midi(), 74)
}

///|
test "roman_progression_text_parse" {
  let k = @moonsic.key(@moonsic.c(4), @moonsic.Major)
  let t = @moonsic.roman_progression(k, "I V vi IV", @moonsic.half())
  assert_eq(t.event_count(), 4)
}

///|
test "chord_distance_same" {
  let a = @moonsic.chord(
    [@moonsic.c(4), @moonsic.e(4), @moonsic.g(4)],
    @moonsic.quarter(),
  )
  let b = @moonsic.chord(
    [@moonsic.c(4), @moonsic.e(4), @moonsic.g(4)],
    @moonsic.quarter(),
  )
  assert_eq(@moonsic.chord_distance(a, b), 0)
}

///|
test "bass_root_octave" {
  let chords = @moonsic.progression(
    @moonsic.c(3),
    @moonsic.Major,
    [@moonsic.I],
    @moonsic.half(),
  )
  let bass = @moonsic.bass_from_progression(chords, @moonsic.Root, 2)
  assert_eq(bass.to_note_events()[0].midi_note, 36)
}

///|
test "bass_root_fifth_duration" {
  let chords = @moonsic.progression(
    @moonsic.c(3),
    @moonsic.Major,
    [@moonsic.I],
    @moonsic.whole(),
  )
  let bass = @moonsic.bass_from_progression(chords, @moonsic.RootFifth, 2)
  assert_eq(bass.to_note_events().length(), 4)
}

///|
test "arpeggio_up_down" {
  let chords = @moonsic.progression(
    @moonsic.c(3),
    @moonsic.Major,
    [@moonsic.I],
    @moonsic.half(),
  )
  let arp = @moonsic.arpeggiate_dir(chords, @moonsic.eighth(), @moonsic.UpDown)
  let events = arp.to_note_events()
  assert_eq(events.length(), 4)
}

///|
test "arpeggio_alberti" {
  let chords = @moonsic.progression(
    @moonsic.c(3),
    @moonsic.Major,
    [@moonsic.I],
    @moonsic.half(),
  )
  let arp = @moonsic.arpeggiate_dir(chords, @moonsic.eighth(), @moonsic.Alberti)
  let events = arp.to_note_events()
  assert_eq(events.length(), 4)
  assert_eq(events[1].midi_note, 55)
}

///|
test "accompany_pop_ballad" {
  let k = @moonsic.key(@moonsic.c(4), @moonsic.Major)
  let tracks = @moonsic.accompany(
    k,
    "I V vi IV",
    @moonsic.PopBallad,
    @moonsic.half(),
  )
  assert_eq(tracks.length(), 3)
}

///|
test "accompany_block_chords" {
  let k = @moonsic.key(@moonsic.c(4), @moonsic.Major)
  let tracks = @moonsic.accompany(
    k,
    "I vi IV V",
    @moonsic.BlockChords,
    @moonsic.half(),
  )
  assert_eq(tracks.length(), 1)
}

// --- v10 补充测试 ---

///|
test "pentatonic_major_scale" {
  let s = @moonsic.scale(@moonsic.c(4), @moonsic.MajorPentatonic, 1)
  assert_eq(s.length(), 5)
  // C D E G A (C=60, D=62, E=64, G=67, A=69)
  assert_eq(s[0].to_midi(), 60)
  assert_eq(s[1].to_midi(), 62)
  assert_eq(s[2].to_midi(), 64)
  assert_eq(s[3].to_midi(), 67)
  assert_eq(s[4].to_midi(), 69)
}

///|
test "pentatonic_minor_scale" {
  let s = @moonsic.scale(@moonsic.c(4), @moonsic.MinorPentatonic, 1)
  assert_eq(s.length(), 5)
  // C Eb F G Bb (C=60, Eb=63, F=65, G=67, Bb=70)
  assert_eq(s[0].to_midi(), 60)
  assert_eq(s[1].to_midi(), 63)
  assert_eq(s[2].to_midi(), 65)
  assert_eq(s[3].to_midi(), 67)
  assert_eq(s[4].to_midi(), 70)
}

///|
test "voice_leading_preserves_event_count" {
  let chords = @moonsic.progression(
    @moonsic.c(3),
    @moonsic.Major,
    [@moonsic.I, @moonsic.IV, @moonsic.V],
    @moonsic.half(),
  )
  let voiced = @moonsic.voice_lead(chords)
  assert_eq(voiced.event_count(), chords.event_count())
}

///|
test "arpeggio_down" {
  let chords = @moonsic.progression(
    @moonsic.c(3),
    @moonsic.Major,
    [@moonsic.I],
    @moonsic.half(),
  )
  let arp = @moonsic.arpeggiate_dir(chords, @moonsic.eighth(), @moonsic.Down)
  let events = arp.to_note_events()
  assert_eq(events.length(), 3)
  // Down should give G3(55), E3(52), C3(48)
  assert_eq(events[0].midi_note, 55)
  assert_eq(events[1].midi_note, 52)
  assert_eq(events[2].midi_note, 48)
}

///|
test "bass_octave_style" {
  let chords = @moonsic.progression(
    @moonsic.c(3),
    @moonsic.Major,
    [@moonsic.I],
    @moonsic.whole(),
  )
  let bass = @moonsic.bass_from_progression(chords, @moonsic.Octave, 2)
  let events = bass.to_note_events()
  // octave alternates C2(36) and C3(48) on each beat
  assert_eq(events.length(), 4)
  assert_eq(events[0].midi_note, 36)
  assert_eq(events[1].midi_note, 48)
}

///|
test "bass_walking_style" {
  let chords = @moonsic.progression(
    @moonsic.c(3),
    @moonsic.Major,
    [@moonsic.I],
    @moonsic.half(),
  )
  let bass = @moonsic.bass_from_progression(chords, @moonsic.Walking, 2)
  let events = bass.to_note_events()
  assert_true(events.length() > 0)
  // walking uses eigth notes (0.5 beat each), total 2 beats = 4 events
  assert_eq(events.length(), 4)
}

///|
test "aug_chord" {
  let evt = @moonsic.aug(@moonsic.c(4), @moonsic.half())
  let track = @moonsic.melody([evt])
  let events = track.to_note_events()
  // C aug = C(60) E(64) G#(68)
  assert_eq(events.length(), 3)
  assert_eq(events[0].midi_note, 60)
  assert_eq(events[1].midi_note, 64)
  assert_eq(events[2].midi_note, 68)
}

///|
test "maj7_chord" {
  let evt = @moonsic.maj7(@moonsic.c(4), @moonsic.half())
  let track = @moonsic.melody([evt])
  let events = track.to_note_events()
  // Cmaj7 = C(60) E(64) G(67) B(71)
  assert_eq(events.length(), 4)
  assert_eq(events[0].midi_note, 60)
  assert_eq(events[1].midi_note, 64)
  assert_eq(events[2].midi_note, 67)
  assert_eq(events[3].midi_note, 71)
}

///|
test "min7_chord" {
  let evt = @moonsic.min7(@moonsic.a(3), @moonsic.half())
  let track = @moonsic.melody([evt])
  let events = track.to_note_events()
  // Am7 = A(57) C(60) E(64) G(67)
  assert_eq(events.length(), 4)
  assert_eq(events[0].midi_note, 57)
  assert_eq(events[1].midi_note, 60)
  assert_eq(events[2].midi_note, 64)
  assert_eq(events[3].midi_note, 67)
}

///|
test "chord_quality_intervals_builtin" {
  let major_int = @moonsic.MajorTriad.intervals()
  assert_eq(major_int.length(), 3)
  assert_eq(major_int[0], 0)
  assert_eq(major_int[1], 4)
  assert_eq(major_int[2], 7)
  let dim_int = @moonsic.DiminishedTriad.intervals()
  assert_eq(dim_int[0], 0)
  assert_eq(dim_int[1], 3)
  assert_eq(dim_int[2], 6)
  let aug_int = @moonsic.AugmentedTriad.intervals()
  assert_eq(aug_int[0], 0)
  assert_eq(aug_int[1], 4)
  assert_eq(aug_int[2], 8)
  let dom7_int = @moonsic.DominantSeventh.intervals()
  assert_eq(dom7_int.length(), 4)
  let maj7_int = @moonsic.MajorSeventh.intervals()
  assert_eq(maj7_int[3], 11)
  let min7_int = @moonsic.MinorSeventh.intervals()
  assert_eq(min7_int[3], 10)
}

///|
test "browser_js_starts_with_global_var" {
  let s = @moonsic.score1(
    @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())]),
  )
  let js = @moonsic.note_events_to_browser_js(s.to_note_events())
  assert_true(js.contains("window.MOONSIC_DEMO_EVENTS"))
}

///|
test "browser_js_contains_note_fields" {
  let s = @moonsic.score1(
    @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())]),
  )
  let js = @moonsic.note_events_to_browser_js(s.to_note_events())
  assert_true(js.contains("start"))
  assert_true(js.contains("duration"))
}

///|
test "section_create" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let s = @moonsic.section("verse", [t])
  assert_eq(s.name, "verse")
  assert_eq(s.tracks.length(), 1)
  assert_eq(s.duration_beats(), 1.0)
}

///|
test "track_append_event" {
  let t = @moonsic.empty_track()
  let t2 = t.append(@moonsic.n(@moonsic.c(4), @moonsic.quarter()))
  let t3 = t2.append(@moonsic.n(@moonsic.d(4), @moonsic.quarter()))
  assert_eq(t3.event_count(), 2)
  assert_eq(t3.duration_beats(), 2.0)
}

///|
test "track_pad_to" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let padded = t.pad_to(4.0)
  assert_eq(padded.event_count(), 3) // 1 original + 1 half + 1 quarter rest = 3 events
  assert_true(padded.duration_beats() >= 4.0)
}

///|
test "track_with_mute" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let muted = t.with_mute(true)
  assert_true(muted.mute)
  assert_true(muted.event_count() == t.event_count())
}

///|
test "chord_with_velocity_explicit" {
  let c = @moonsic.chord_with_velocity(
    [@moonsic.c(4), @moonsic.e(4), @moonsic.g(4)],
    @moonsic.quarter(),
    64,
  )
  assert_eq(c.velocity, 64)
  assert_eq(c.pitches.length(), 3)
}

///|
test "pitch_is_valid_midi_boundary" {
  let p = @moonsic.pitch
  assert_true(p(@moonsic.B, @moonsic.Natural, 3).is_valid_midi()) // 59, valid
  assert_true(p(@moonsic.B, @moonsic.Natural, 3).is_valid_midi())
  let high = p(@moonsic.G, @moonsic.Natural, 9) // 127, valid
  assert_true(high.is_valid_midi())
  let too_low = p(@moonsic.B, @moonsic.Flat, -2) // invalid
  assert_false(too_low.is_valid_midi())
  let too_high = p(@moonsic.G, @moonsic.Sharp, 9) // 128, invalid
  assert_false(too_high.is_valid_midi())
}

///|
test "duration_to_string" {
  assert_eq(@moonsic.Quarter.to_string(), "quarter")
  assert_eq(@moonsic.Half.to_string(), "half")
  assert_eq(@moonsic.Sixteenth.to_string(), "sixteenth")
  assert_true(@moonsic.dotted(@moonsic.Half).to_string().contains("dotted"))
}

///|
test "bass_rest_on_non_chord_event" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(3), @moonsic.quarter())])
  let bass = @moonsic.bass_from_progression(t, @moonsic.Root, 2)
  let events = bass.to_note_events()
  assert_eq(events.length(), 0) // Note events produce rests, no note output
}

///|
test "instrument_track_program_preserved" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let t2 = @moonsic.instrument(t, @moonsic.violin())
  assert_eq(t2.program, 40)
}

// --- v9 补充测试 ---

///|
test "roman_progression_single_iv" {
  let k = @moonsic.key(@moonsic.c(4), @moonsic.Major)
  let t = @moonsic.roman_progression(k, "IV", @moonsic.half())
  assert_eq(t.event_count(), 1)
  // IV in C major = F major, root = F4(65)
  let events = t.to_note_events()
  assert_eq(events[0].midi_note, 65)
}

///|
test "roman_progression_single_vii" {
  let k = @moonsic.key(@moonsic.c(4), @moonsic.Major)
  let t = @moonsic.roman_progression(k, "vii", @moonsic.half())
  assert_eq(t.event_count(), 1)
  // vii in C major = B dim, root = B4(71)
  let events = t.to_note_events()
  assert_eq(events[0].midi_note, 71)
}

///|
test "roman_progression_single_ii" {
  let k = @moonsic.key(@moonsic.c(4), @moonsic.Major)
  let t = @moonsic.roman_progression(k, "ii", @moonsic.half())
  assert_eq(t.event_count(), 1)
  // ii in C major = D minor, root = D4(62)
  let events = t.to_note_events()
  assert_eq(events[0].midi_note, 62)
}

///|
test "roman_progression_single_iii" {
  let k = @moonsic.key(@moonsic.c(4), @moonsic.Major)
  let t = @moonsic.roman_progression(k, "iii", @moonsic.half())
  assert_eq(t.event_count(), 1)
  // iii in C major = E minor, root = E4(64)
  let events = t.to_note_events()
  assert_eq(events[0].midi_note, 64)
}

///|
test "roman_progression_single_vi" {
  let k = @moonsic.key(@moonsic.c(4), @moonsic.Major)
  let t = @moonsic.roman_progression(k, "vi", @moonsic.half())
  assert_eq(t.event_count(), 1)
  // vi in C major = A minor, root = A4(69)
  let events = t.to_note_events()
  assert_eq(events[0].midi_note, 69)
}

///|
test "chord_distance_nonzero" {
  // C major vs D minor should have non-zero distance
  let a = @moonsic.chord(
    [@moonsic.c(4), @moonsic.e(4), @moonsic.g(4)],
    @moonsic.quarter(),
  )
  let b = @moonsic.chord(
    [@moonsic.d(4), @moonsic.f(4), @moonsic.a(4)],
    @moonsic.quarter(),
  )
  let d = @moonsic.chord_distance(a, b)
  assert_true(d > 0)
}

///|
test "bass_from_progression_empty_chord" {
  // 空 pitches 和弦应默认为 C 音
  let emptychord = @moonsic.Chord(@moonsic.chord([], @moonsic.whole()))
  let t = @moonsic.track([emptychord])
  let bass = @moonsic.bass_from_progression(t, @moonsic.Root, 3)
  let events = bass.to_note_events()
  assert_eq(events.length(), 1)
  // 默认 pitch(C, Natural, 3) = C3 = MIDI 48
  assert_eq(events[0].midi_note, 48)
}

///|
test "accompany_simple_arpeggio" {
  let k = @moonsic.key(@moonsic.c(4), @moonsic.Major)
  let tracks = @moonsic.accompany(
    k,
    "I vi",
    @moonsic.SimpleArpeggio,
    @moonsic.half(),
  )
  // SimpleArpeggio = 一条 UpDown 琶音轨
  assert_eq(tracks.length(), 1)
  let events = tracks[0].to_note_events()
  // C major(3音) UpDown=4, Am(3音) UpDown=4 → 共8个事件
  assert_eq(events.length(), 8)
}

///|
test "accompany_bass_and_pad" {
  let k = @moonsic.key(@moonsic.c(4), @moonsic.Major)
  let tracks = @moonsic.accompany(k, "I", @moonsic.BassAndPad, @moonsic.whole())
  // BassAndPad = voiced 和弦轨 + 低音轨
  assert_eq(tracks.length(), 2)
  // 两条轨都有内容
  assert_true(tracks[0].event_count() > 0)
  assert_true(tracks[1].event_count() > 0)
}

///|
test "arpeggio_up_ascending_order" {
  let chords = @moonsic.progression(
    @moonsic.c(3),
    @moonsic.Major,
    [@moonsic.I],
    @moonsic.half(),
  )
  let arp = @moonsic.arpeggiate_dir(chords, @moonsic.eighth(), @moonsic.Up)
  let events = arp.to_note_events()
  assert_eq(events.length(), 3)
  // Up = 升序: C3(48), E3(52), G3(55)
  assert_eq(events[0].midi_note, 48)
  assert_eq(events[1].midi_note, 52)
  assert_eq(events[2].midi_note, 55)
}

///|
test "arpeggio_updown_pattern" {
  let chords = @moonsic.progression(
    @moonsic.c(3),
    @moonsic.Major,
    [@moonsic.I],
    @moonsic.half(),
  )
  let arp = @moonsic.arpeggiate_dir(chords, @moonsic.eighth(), @moonsic.UpDown)
  let events = arp.to_note_events()
  // UpDown on 3 pitches: C3, E3, G3, E3 = 4 events
  assert_eq(events.length(), 4)
  assert_eq(events[0].midi_note, 48) // C3
  assert_eq(events[1].midi_note, 52) // E3
  assert_eq(events[2].midi_note, 55) // G3
  assert_eq(events[3].midi_note, 52) // E3 (回来不含两端的重复)
}

///|
test "arpeggio_alberti_pattern" {
  let chords = @moonsic.progression(
    @moonsic.c(3),
    @moonsic.Major,
    [@moonsic.I],
    @moonsic.half(),
  )
  let arp = @moonsic.arpeggiate_dir(chords, @moonsic.eighth(), @moonsic.Alberti)
  let events = arp.to_note_events()
  // Alberti on C major: C3(48), G3(55), E3(52), G3(55) = 4 events
  assert_eq(events.length(), 4)
  assert_eq(events[0].midi_note, 48) // low
  assert_eq(events[1].midi_note, 55) // high
  assert_eq(events[2].midi_note, 52) // middle
  assert_eq(events[3].midi_note, 55) // high
}

///|
test "roman_progression_minor_key" {
  let k = @moonsic.key(@moonsic.a(3), @moonsic.NaturalMinor)
  let t = @moonsic.roman_progression(k, "i iv v", @moonsic.half())
  assert_eq(t.event_count(), 3)
  // A natural minor: i=Am, iv=Dm, v=Em
  let events = t.to_note_events()
  assert_eq(events[0].midi_note, 57) // A3 for i
  assert_eq(events[3].midi_note, 62) // D4 for iv
  assert_eq(events[6].midi_note, 64) // E4 for v
}

///|
test "accompany_block_chords_output" {
  let k = @moonsic.key(@moonsic.c(4), @moonsic.Major)
  let tracks = @moonsic.accompany(
    k,
    "I IV",
    @moonsic.BlockChords,
    @moonsic.half(),
  )
  assert_eq(tracks.length(), 1)
  let events = tracks[0].to_note_events()
  // I=C major(3) + IV=F major(3) = 6 events
  assert_eq(events.length(), 6)
}

///|
test "voice_lead_output_contains_chords" {
  let chords = @moonsic.progression(
    @moonsic.c(3),
    @moonsic.Major,
    [@moonsic.I, @moonsic.IV, @moonsic.V, @moonsic.I],
    @moonsic.half(),
  )
  let voiced = @moonsic.voice_lead(chords)
  assert_eq(voiced.event_count(), 4)
  let events = voiced.to_note_events()
  // 4 chords × 3 notes each = 12 events
  assert_eq(events.length(), 12)
}

// --- v10 enum expansion tests ---

///|
test "accidental_double_flat_offset" {
  assert_eq(@moonsic.DoubleFlat.semitone_offset(), -2)
}

///|
test "accidental_double_sharp_offset" {
  assert_eq(@moonsic.DoubleSharp.semitone_offset(), 2)
}

///|
test "scale_dorian_c" {
  let s = @moonsic.scale(@moonsic.c(4), @moonsic.Dorian, 1)
  assert_eq(s.length(), 7)
  // C Dorian: C D Eb F G A Bb
  assert_eq(s[0].to_midi(), 60) // C
  assert_eq(s[1].to_midi(), 62) // D
  assert_eq(s[2].to_midi(), 63) // Eb
  assert_eq(s[3].to_midi(), 65) // F
  assert_eq(s[4].to_midi(), 67) // G
  assert_eq(s[5].to_midi(), 69) // A
  assert_eq(s[6].to_midi(), 70) // Bb
}

///|
test "scale_chromatic_c" {
  let s = @moonsic.scale(@moonsic.c(4), @moonsic.Chromatic, 1)
  assert_eq(s.length(), 12)
}

///|
test "chord_half_dim7" {
  let evt = @moonsic.chord_quality(
    @moonsic.b(3),
    @moonsic.HalfDiminished7,
    @moonsic.half(),
  )
  let track = @moonsic.melody([evt])
  let events = track.to_note_events()
  // B half-dim7 = B D F A
  assert_eq(events.length(), 4)
  assert_eq(events[0].midi_note, 59) // B
  assert_eq(events[1].midi_note, 62) // D
  assert_eq(events[2].midi_note, 65) // F
  assert_eq(events[3].midi_note, 69) // A
}

///|
test "chord_sus4" {
  let evt = @moonsic.chord_quality(
    @moonsic.c(4),
    @moonsic.Suspended4,
    @moonsic.quarter(),
  )
  let track = @moonsic.melody([evt])
  let events = track.to_note_events()
  // C sus4 = C F G
  assert_eq(events.length(), 3)
  assert_eq(events[0].midi_note, 60) // C
  assert_eq(events[1].midi_note, 65) // F
  assert_eq(events[2].midi_note, 67) // G
}

// --- interval / scale / chord parse tests ---

///|
test "interval_between_major_third" {
  let iv = @moonsic.interval_between(@moonsic.c(4), @moonsic.e(4))
  assert_eq(iv.number, 3)
  assert_eq(iv.semitones, 4)
  assert_eq(iv.quality.to_string(), "M")
}

///|
test "interval_between_perfect_fifth" {
  let iv = @moonsic.interval_between(@moonsic.c(4), @moonsic.g(4))
  assert_eq(iv.number, 5)
  assert_eq(iv.semitones, 7)
  assert_eq(iv.quality.to_string(), "P")
}

///|
test "interval_between_minor_second" {
  let iv = @moonsic.interval_between(@moonsic.e(4), @moonsic.f(4))
  assert_eq(iv.number, 2)
  assert_eq(iv.semitones, 1)
  assert_eq(iv.quality.to_string(), "m")
}

///|
test "interval_between_unison" {
  let iv = @moonsic.interval_between(@moonsic.c(4), @moonsic.c(4))
  assert_eq(iv.number, 1)
  assert_eq(iv.semitones, 0)
  assert_eq(iv.quality.to_string(), "P")
}

///|
test "interval_between_octave" {
  let iv = @moonsic.interval_between(@moonsic.c(4), @moonsic.c(5))
  assert_eq(iv.number, 8)
  assert_eq(iv.semitones, 12)
  assert_eq(iv.quality.to_string(), "P")
}

///|
test "invert_interval_major_to_minor" {
  let iv = @moonsic.parse_interval("M3").unwrap()
  let inv = @moonsic.invert_interval(iv)
  assert_eq(inv.quality.to_string(), "m")
  assert_eq(inv.number, 6)
  assert_eq(inv.semitones, 8)
}

///|
test "invert_interval_perfect_stays" {
  let iv = @moonsic.parse_interval("P5").unwrap()
  let inv = @moonsic.invert_interval(iv)
  assert_eq(inv.quality.to_string(), "P")
  assert_eq(inv.number, 4)
  assert_eq(inv.semitones, 5)
}

///|
test "parse_interval_M3" {
  let r = @moonsic.parse_interval("M3")
  let iv = r.unwrap()
  assert_eq(iv.quality.to_string(), "M")
  assert_eq(iv.number, 3)
  assert_eq(iv.semitones, 4)
}

///|
test "parse_interval_P5" {
  let r = @moonsic.parse_interval("P5")
  let iv = r.unwrap()
  assert_eq(iv.quality.to_string(), "P")
  assert_eq(iv.number, 5)
  assert_eq(iv.semitones, 7)
}

///|
test "parse_interval_m7" {
  let r = @moonsic.parse_interval("m7")
  let iv = r.unwrap()
  assert_eq(iv.quality.to_string(), "m")
  assert_eq(iv.number, 7)
  assert_eq(iv.semitones, 10)
}

///|
test "parse_interval_A4" {
  let r = @moonsic.parse_interval("A4")
  let iv = r.unwrap()
  assert_eq(iv.quality.to_string(), "A")
  assert_eq(iv.number, 4)
  assert_eq(iv.semitones, 6)
}

///|
test "parse_interval_d5" {
  let r = @moonsic.parse_interval("d5")
  let iv = r.unwrap()
  assert_eq(iv.quality.to_string(), "d")
  assert_eq(iv.number, 5)
  assert_eq(iv.semitones, 6)
}

///|
test "parse_interval_invalid" {
  let r = @moonsic.parse_interval("X3")
  assert_true(r is Err(_))
}

///|
test "parse_chord_Cmaj" {
  let r = @moonsic.parse_chord("C")
  let chord = r.unwrap()
  let tones = @moonsic.chord_tones(chord)
  assert_eq(tones.length(), 3)
  assert_eq(tones[0].to_string(), "C")
  assert_eq(tones[1].to_string(), "E")
  assert_eq(tones[2].to_string(), "G")
}

///|
test "parse_chord_Cm" {
  let r = @moonsic.parse_chord("Cm")
  let chord = r.unwrap()
  let tones = @moonsic.chord_tones(chord)
  assert_eq(tones.length(), 3)
  assert_eq(tones[0].to_string(), "C")
  assert_eq(tones[1].to_string(), "E")
  assert_eq(tones[2].to_string(), "G")
}

///|
test "parse_chord_Cm7" {
  let r = @moonsic.parse_chord("Cm7")
  let chord = r.unwrap()
  let tones = @moonsic.chord_tones(chord)
  assert_eq(tones.length(), 4)
  assert_eq(tones[0].to_string(), "C")
  assert_eq(tones[1].to_string(), "E")
  assert_eq(tones[2].to_string(), "G")
  assert_eq(tones[3].to_string(), "B")
}

///|
test "parse_chord_G7" {
  let r = @moonsic.parse_chord("G7")
  let chord = r.unwrap()
  let tones = @moonsic.chord_tones(chord)
  assert_eq(tones.length(), 4)
  assert_eq(tones[0].to_string(), "G")
  assert_eq(tones[1].to_string(), "B")
  assert_eq(tones[2].to_string(), "D")
  assert_eq(tones[3].to_string(), "F")
}

///|
test "parse_chord_invalid" {
  let r = @moonsic.parse_chord("H")
  assert_true(r is Err(_))
}

///|
test "chord_tones_Cmaj7" {
  let r = @moonsic.parse_chord("Cmaj7")
  let chord = r.unwrap()
  let tones = @moonsic.chord_tones(chord)
  assert_eq(tones.length(), 4)
  assert_eq(tones[0].to_string(), "C")
  assert_eq(tones[1].to_string(), "E")
  assert_eq(tones[2].to_string(), "G")
  assert_eq(tones[3].to_string(), "B")
}

///|
test "parse_scale_C_major" {
  let r = @moonsic.parse_scale("C major")
  let scale = r.unwrap()
  assert_eq(scale.tones.length(), 7)
  assert_eq(scale.root.to_string(), "C")
  assert_eq(scale.tones[0].to_string(), "C")
  assert_eq(scale.tones[1].to_string(), "D")
  assert_eq(scale.tones[2].to_string(), "E")
  assert_eq(scale.tones[3].to_string(), "F")
  assert_eq(scale.tones[4].to_string(), "G")
  assert_eq(scale.tones[5].to_string(), "A")
  assert_eq(scale.tones[6].to_string(), "B")
}

///|
test "parse_scale_A_minor" {
  let r = @moonsic.parse_scale("A minor")
  let scale = r.unwrap()
  assert_eq(scale.tones.length(), 7)
  assert_eq(scale.root.to_string(), "A")
  assert_eq(scale.tones[0].to_string(), "A")
  assert_eq(scale.tones[1].to_string(), "B")
  assert_eq(scale.tones[2].to_string(), "C")
  assert_eq(scale.tones[3].to_string(), "D")
  assert_eq(scale.tones[4].to_string(), "E")
  assert_eq(scale.tones[5].to_string(), "F")
  assert_eq(scale.tones[6].to_string(), "G")
}

///|
test "parse_scale_D_dorian" {
  let r = @moonsic.parse_scale("D dorian")
  let scale = r.unwrap()
  assert_eq(scale.tones.length(), 7)
  assert_eq(scale.root.to_string(), "D")
  assert_eq(scale.tones[0].to_string(), "D")
  assert_eq(scale.tones[1].to_string(), "E")
  assert_eq(scale.tones[2].to_string(), "F")
  assert_eq(scale.tones[3].to_string(), "G")
  assert_eq(scale.tones[4].to_string(), "A")
  assert_eq(scale.tones[5].to_string(), "B")
  assert_eq(scale.tones[6].to_string(), "C")
}

///|
test "parse_scale_invalid" {
  let r = @moonsic.parse_scale("X lydian")
  assert_true(r is Err(_))
}

///|
test "build_scale_F_major" {
  let scale = @moonsic.build_scale(@moonsic.F, @moonsic.Major)
  assert_eq(scale.tones.length(), 7)
  assert_eq(scale.root.to_string(), "F")
  assert_eq(scale.tones[0].to_string(), "F")
  assert_eq(scale.tones[1].to_string(), "G")
  assert_eq(scale.tones[2].to_string(), "A")
  assert_eq(scale.tones[3].to_string(), "B")
  assert_eq(scale.tones[4].to_string(), "C")
  assert_eq(scale.tones[5].to_string(), "D")
  assert_eq(scale.tones[6].to_string(), "E")
}

///|
test "theory_error_to_string_InvalidPitch" {
  let e = @moonsic.InvalidPitch("bad")
  assert_true(e.to_string().contains("无效音高"))
}

///|
test "theory_error_to_string_ParseError" {
  let e = @moonsic.ParseError("oops")
  assert_true(e.to_string().contains("解析错误"))
}

///|
test "parse_chord_F_sharp_dim" {
  let r = @moonsic.parse_chord("F#dim")
  let chord = r.unwrap()
  let tones = @moonsic.chord_tones(chord)
  assert_eq(tones.length(), 3)
  assert_eq(tones[0].to_string(), "F")
  assert_eq(tones[1].to_string(), "A")
  assert_eq(tones[2].to_string(), "C")
}

///|
test "parse_chord_Dm7" {
  let r = @moonsic.parse_chord("Dm7")
  let chord = r.unwrap()
  let tones = @moonsic.chord_tones(chord)
  assert_eq(tones.length(), 4)
  assert_eq(tones[0].to_string(), "D")
  assert_eq(tones[1].to_string(), "F")
  assert_eq(tones[2].to_string(), "A")
  assert_eq(tones[3].to_string(), "C")
}
