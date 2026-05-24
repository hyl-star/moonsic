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

// ============================================================
// parse_pitch / parse_pitch_class / FFI JSON 测试
// ============================================================

///|
test "parse_pitch_C4_ok" {
  let r = @moonsic.parse_pitch("C4")
  assert_true(r.is_ok())
  let p = r.unwrap()
  assert_eq(p.to_midi(), 60)
  assert_eq(p.to_string(), "C4")
}

///|
test "parse_pitch_F_sharp_3_ok" {
  let r = @moonsic.parse_pitch("F#3")
  assert_true(r.is_ok())
  let p = r.unwrap()
  assert_eq(p.to_midi(), 54)
}

///|
test "parse_pitch_Bb5_ok" {
  let r = @moonsic.parse_pitch("Bb5")
  assert_true(r.is_ok())
  let p = r.unwrap()
  assert_eq(p.to_midi(), 82)
}

///|
test "parse_pitch_H_sharp_13_err" {
  let r = @moonsic.parse_pitch("H#13")
  assert_true(r.is_err())
}

///|
test "parse_pitch_empty_err" {
  let r = @moonsic.parse_pitch("")
  assert_true(r.is_err())
}

///|
test "parse_pitch_invalid_note_err" {
  let r = @moonsic.parse_pitch("X9")
  assert_true(r.is_err())
}

///|
test "parse_pitch_class_C_sharp_ok" {
  let r = @moonsic.parse_pitch_class("C#")
  assert_true(r.is_ok())
  let pc = r.unwrap()
  // PitchClass "C#" = C (accidental not stored in PitchClass)
  assert_eq(pc.base_semitone(), 0)
}

///|
test "parse_pitch_class_H_err" {
  let r = @moonsic.parse_pitch_class("H")
  assert_true(r.is_err())
}

///|
test "parse_pitch_class_C_ok" {
  let r = @moonsic.parse_pitch_class("C")
  assert_true(r.is_ok())
  assert_eq(r.unwrap().base_semitone(), 0)
}

///|
test "parse_pitch_class_Db_ok" {
  let r = @moonsic.parse_pitch_class("Db")
  assert_true(r.is_ok())
  // "Db" → PitchClass D
  assert_eq(r.unwrap().base_semitone(), 2)
}

///|
test "parse_pitch_class_empty_err" {
  let r = @moonsic.parse_pitch_class("")
  assert_true(r.is_err())
}

///|
test "parse_pitch_class_with_octave_err" {
  let r = @moonsic.parse_pitch_class("C4")
  assert_true(r.is_err())
}

///|
test "ffi_parse_pitch_to_midi_C4" {
  let json = @moonsic.ffi_parse_pitch_to_midi("C4")
  assert_true(json.contains("60"))
  assert_true(json.contains("true"))
}

///|
test "ffi_parse_pitch_to_midi_X9_error" {
  let json = @moonsic.ffi_parse_pitch_to_midi("X9")
  assert_true(json.contains("error"))
  assert_true(json.contains("false"))
}

///|
test "ffi_parse_chord_tones_Cm7" {
  let json = @moonsic.ffi_parse_chord_tones("Cm7")
  assert_true(json.contains("Eb"))
  assert_true(json.contains("true"))
}

///|
test "ffi_parse_chord_tones_invalid" {
  let json = @moonsic.ffi_parse_chord_tones("H#dim")
  assert_true(json.contains("error"))
}

///|
test "ffi_build_scale_C_major" {
  let json = @moonsic.ffi_build_scale("C major")
  assert_true(json.contains("\"C\""))
  assert_true(json.contains("\"D\""))
  assert_true(json.contains("\"E\""))
  assert_true(json.contains("true"))
}

///|
test "ffi_build_scale_invalid" {
  let json = @moonsic.ffi_build_scale("X blarg")
  assert_true(json.contains("error"))
}

///|
test "parse_pitch_multi_octave_C10" {
  let r = @moonsic.parse_pitch("C10")
  assert_true(r.is_ok())
  let p = r.unwrap()
  assert_eq(p.to_midi(), 132)
}

///|
test "parse_pitch_class_double_accidental_err" {
  let r = @moonsic.parse_pitch_class("C##")
  assert_true(r.is_err())
}

// ============================================================
// 节奏与时间模块测试 — Rational + DurUnit + 换算 + 解析
// ============================================================

// --- Rational 基础 ---

///|
test "rational_create_ok" {
  let r = @moonsic.rational(1, 2)
  assert_true(r.is_ok())
  let v = r.unwrap()
  assert_eq(v.numerator, 1)
  assert_eq(v.denominator, 2)
}

///|
test "rational_create_err_zero_denominator" {
  let r = @moonsic.rational(1, 0)
  assert_true(r.is_err())
}

///|
test "rational_create_err_negative_denominator" {
  let r = @moonsic.rational(1, -1)
  assert_true(r.is_err())
}

///|
test "rational_auto_reduce" {
  // 2/4 → 1/2
  let r = @moonsic.rational(2, 4).unwrap()
  assert_eq(r.numerator, 1)
  assert_eq(r.denominator, 2)
}

///|
test "rational_auto_reduce_negative" {
  // -2/4 → -1/2
  let r = @moonsic.rational(-2, 4).unwrap()
  assert_eq(r.numerator, -1)
  assert_eq(r.denominator, 2)
}

///|
test "rational_add" {
  // 1/2 + 1/4 = 3/4
  let a = @moonsic.rational(1, 2).unwrap()
  let b = @moonsic.rational(1, 4).unwrap()
  let c = @moonsic.rational_add(a, b)
  assert_eq(c.numerator, 3)
  assert_eq(c.denominator, 4)
}

///|
test "rational_sub" {
  // 3/4 - 1/4 = 1/2
  let a = @moonsic.rational(3, 4).unwrap()
  let b = @moonsic.rational(1, 4).unwrap()
  let c = @moonsic.rational_sub(a, b)
  assert_eq(c.numerator, 1)
  assert_eq(c.denominator, 2)
}

///|
test "rational_mul" {
  // 1/2 * 2/3 = 1/3
  let a = @moonsic.rational(1, 2).unwrap()
  let b = @moonsic.rational(2, 3).unwrap()
  let c = @moonsic.rational_mul(a, b)
  assert_eq(c.numerator, 1)
  assert_eq(c.denominator, 3)
}

///|
test "rational_div" {
  // (1/2) / (1/4) = 2/1
  let a = @moonsic.rational(1, 2).unwrap()
  let b = @moonsic.rational(1, 4).unwrap()
  let c = @moonsic.rational_div(a, b).unwrap()
  assert_eq(c.numerator, 2)
  assert_eq(c.denominator, 1)
}

///|
test "rational_div_by_zero_err" {
  let a = @moonsic.rational(1, 2).unwrap()
  let b = @moonsic.rational(0, 1).unwrap()
  let c = @moonsic.rational_div(a, b)
  assert_true(c.is_err())
}

///|
test "rational_is_integer_true" {
  // 4/2 = 2
  let r = @moonsic.rational(4, 2).unwrap()
  assert_true(@moonsic.rational_is_integer(r))
}

///|
test "rational_is_integer_false" {
  // 1/2
  let r = @moonsic.rational(1, 2).unwrap()
  assert_false(@moonsic.rational_is_integer(r))
}

///|
test "rational_to_int_ok" {
  let r = @moonsic.rational(4, 2).unwrap()
  let i = @moonsic.rational_to_int(r).unwrap()
  assert_eq(i, 2)
}

///|
test "rational_to_int_err_non_integer" {
  let r = @moonsic.rational(1, 2).unwrap()
  let i = @moonsic.rational_to_int(r)
  assert_true(i.is_err())
}

///|
test "rational_to_double" {
  // 1/2 = 0.5
  let r = @moonsic.rational(1, 2).unwrap()
  let d = @moonsic.rational_to_double(r)
  assert_true(d > 0.49 && d < 0.51)
}

///|
test "rational_to_double_negative" {
  // -3/4 = -0.75
  let r = @moonsic.rational(-3, 4).unwrap()
  let d = @moonsic.rational_to_double(r)
  assert_true(d < -0.74 && d > -0.76)
}

///|
test "rational_to_string" {
  let r = @moonsic.rational(3, 4).unwrap()
  assert_eq(r.to_string(), "3/4")
}

// --- 节奏时值换算 ---

///|
test "rhythm_duration_quarter_to_ticks" {
  // Quarter at ppq=480 → 480 ticks
  let d = @moonsic.RhythmDuration::{
    unit: @moonsic.DurQuarter,
    dots: 0,
    tuplet: None,
  }
  let ticks = @moonsic.rhythm_duration_to_ticks(d, 480).unwrap()
  assert_eq(ticks, 480)
}

///|
test "rhythm_duration_dotted_eighth_to_ticks" {
  // dotted Eighth at ppq=480 → 360 ticks
  let d = @moonsic.RhythmDuration::{
    unit: @moonsic.DurEighth,
    dots: 1,
    tuplet: None,
  }
  let ticks = @moonsic.rhythm_duration_to_ticks(d, 480).unwrap()
  assert_eq(ticks, 360)
}

///|
test "rhythm_duration_triplet_eighth_to_ticks" {
  // triplet Eighth (3:2 8) at ppq=480 → 160 ticks
  let d = @moonsic.RhythmDuration::{
    unit: @moonsic.DurEighth,
    dots: 0,
    tuplet: Some(@moonsic.TupletRatio::{ actual: 3, normal: 2 }),
  }
  let ticks = @moonsic.rhythm_duration_to_ticks(d, 480).unwrap()
  assert_eq(ticks, 160)
}

///|
test "rhythm_duration_to_ticks_invalid_ppq" {
  let d = @moonsic.RhythmDuration::{
    unit: @moonsic.DurQuarter,
    dots: 0,
    tuplet: None,
  }
  let r = @moonsic.rhythm_duration_to_ticks(d, 0)
  assert_true(r.is_err())
}

///|
test "rhythm_duration_whole_to_ticks" {
  // Whole at ppq=480 → 1920 ticks
  let d = @moonsic.RhythmDuration::{
    unit: @moonsic.DurWhole,
    dots: 0,
    tuplet: None,
  }
  let ticks = @moonsic.rhythm_duration_to_ticks(d, 480).unwrap()
  assert_eq(ticks, 1920)
}

///|
test "rhythm_duration_half_to_ticks" {
  // Half at ppq=480 → 960 ticks
  let d = @moonsic.RhythmDuration::{
    unit: @moonsic.DurHalf,
    dots: 0,
    tuplet: None,
  }
  let ticks = @moonsic.rhythm_duration_to_ticks(d, 480).unwrap()
  assert_eq(ticks, 960)
}

///|
test "rhythm_duration_sixteenth_to_ticks" {
  // Sixteenth at ppq=480 → 120 ticks
  let d = @moonsic.RhythmDuration::{
    unit: @moonsic.DurSixteenth,
    dots: 0,
    tuplet: None,
  }
  let ticks = @moonsic.rhythm_duration_to_ticks(d, 480).unwrap()
  assert_eq(ticks, 120)
}

///|
test "rhythm_duration_thirtysecond_to_ticks" {
  // ThirtySecond at ppq=480 → 60 ticks
  let d = @moonsic.RhythmDuration::{
    unit: @moonsic.ThirtySecond,
    dots: 0,
    tuplet: None,
  }
  let ticks = @moonsic.rhythm_duration_to_ticks(d, 480).unwrap()
  assert_eq(ticks, 60)
}

///|
test "rhythm_duration_double_dotted_to_ticks" {
  // double-dotted Quarter at ppq=480 → 480 * 7/4 = 840 ticks
  let d = @moonsic.RhythmDuration::{
    unit: @moonsic.DurQuarter,
    dots: 2,
    tuplet: None,
  }
  let ticks = @moonsic.rhythm_duration_to_ticks(d, 480).unwrap()
  assert_eq(ticks, 840)
}

// --- 小节长度 ---

///|
test "bar_length_4_4" {
  // 4/4 bar length → 1920 ticks at ppq=480
  let sig = @moonsic.time_signature(4, 4)
  let ticks = @moonsic.bar_length_ticks(sig, 480).unwrap()
  assert_eq(ticks, 1920)
}

///|
test "bar_length_6_8" {
  // 6/8 bar length → 1440 ticks at ppq=480
  let sig = @moonsic.time_signature(6, 8)
  let ticks = @moonsic.bar_length_ticks(sig, 480).unwrap()
  assert_eq(ticks, 1440)
}

///|
test "bar_length_3_4" {
  // 3/4 bar length → 1440 ticks at ppq=480
  let sig = @moonsic.time_signature(3, 4)
  let ticks = @moonsic.bar_length_ticks(sig, 480).unwrap()
  assert_eq(ticks, 1440)
}

///|
test "bar_length_invalid_ppq" {
  let sig = @moonsic.time_signature(4, 4)
  let r = @moonsic.bar_length_ticks(sig, 0)
  assert_true(r.is_err())
}

///|
test "bar_length_invalid_time_sig" {
  // 5/3 is invalid (denominator 3 not a power of two)
  let r = @moonsic.parse_time_sig("5/3")
  assert_true(r.is_err())
}

// --- BPM/Tick/秒 换算 ---

///|
test "bpm_to_microseconds_per_quarter_120" {
  // 120bpm → 500000 microseconds/quarter
  let us = @moonsic.bpm_to_microseconds_per_quarter(120.0).unwrap()
  assert_eq(us, 500000)
}

///|
test "bpm_to_microseconds_per_quarter_60" {
  // 60bpm → 1000000 microseconds/quarter
  let us = @moonsic.bpm_to_microseconds_per_quarter(60.0).unwrap()
  assert_eq(us, 1000000)
}

///|
test "bpm_to_microseconds_per_quarter_invalid" {
  // BPM <= 0
  let r = @moonsic.bpm_to_microseconds_per_quarter(0.0)
  assert_true(r.is_err())
  let r2 = @moonsic.bpm_to_microseconds_per_quarter(-1.0)
  assert_true(r2.is_err())
}

///|
test "ticks_to_seconds_120bpm" {
  // 120bpm 480 ticks → 0.5s
  let sec = @moonsic.ticks_to_seconds(480, 120.0, 480).unwrap()
  assert_true(sec > 0.49 && sec < 0.51)
}

///|
test "ticks_to_seconds_60bpm" {
  // 60bpm 480 ticks → 1.0s
  let sec = @moonsic.ticks_to_seconds(480, 60.0, 480).unwrap()
  assert_true(sec > 0.99 && sec < 1.01)
}

///|
test "ticks_to_seconds_invalid_ppq" {
  let r = @moonsic.ticks_to_seconds(480, 120.0, 0)
  assert_true(r.is_err())
}

///|
test "ticks_to_seconds_invalid_bpm" {
  let r = @moonsic.ticks_to_seconds(480, 0.0, 480)
  assert_true(r.is_err())
}

///|
test "seconds_to_ticks_120bpm" {
  // 0.5s at 120bpm ppq=480 → 480 ticks
  let ticks = @moonsic.seconds_to_ticks(0.5, 120.0, 480)
  assert_eq(ticks, 480)
}

///|
test "seconds_to_ticks_60bpm" {
  // 1.0s at 60bpm ppq=480 → 480 ticks
  let ticks = @moonsic.seconds_to_ticks(1.0, 60.0, 480)
  assert_eq(ticks, 480)
}

///|
test "ticks_to_quarter_beats_480_ppq" {
  // 480 ticks / 480 ppq = 1 quarter beat
  let r = @moonsic.ticks_to_quarter_beats(480, 480)
  assert_eq(r.numerator, 1)
  assert_eq(r.denominator, 1)
}

///|
test "ticks_to_quarter_beats_240_ppq" {
  // 240 ticks / 480 ppq = 1/2 quarter beat
  let r = @moonsic.ticks_to_quarter_beats(240, 480)
  assert_eq(r.numerator, 1)
  assert_eq(r.denominator, 2)
}

// --- 解析：拍号 ---

///|
test "parse_time_sig_4_4_ok" {
  let r = @moonsic.parse_time_sig("4/4")
  assert_true(r.is_ok())
  let sig = r.unwrap()
  assert_eq(sig.numerator, 4)
  assert_eq(sig.denominator, 4)
}

///|
test "parse_time_sig_6_8_ok" {
  let r = @moonsic.parse_time_sig("6/8")
  assert_true(r.is_ok())
  let sig = r.unwrap()
  assert_eq(sig.numerator, 6)
  assert_eq(sig.denominator, 8)
}

///|
test "parse_time_sig_3_4_ok" {
  let r = @moonsic.parse_time_sig("3/4")
  assert_true(r.is_ok())
  let sig = r.unwrap()
  assert_eq(sig.numerator, 3)
  assert_eq(sig.denominator, 4)
}

///|
test "parse_time_sig_5_3_err" {
  // denominator 3 not valid
  let r = @moonsic.parse_time_sig("5/3")
  assert_true(r.is_err())
}

///|
test "parse_time_sig_empty_err" {
  let r = @moonsic.parse_time_sig("")
  assert_true(r.is_err())
}

///|
test "parse_time_sig_no_slash_err" {
  let r = @moonsic.parse_time_sig("44")
  assert_true(r.is_err())
}

///|
test "parse_time_sig_negative_err" {
  // -4/4 not valid
  let r = @moonsic.parse_time_sig("-4/4")
  assert_true(r.is_err())
}

// --- 解析：时值单位 ---

///|
test "parse_dur_unit_q_ok" {
  let r = @moonsic.parse_dur_unit("q")
  assert_true(r.is_ok())
  let d = r.unwrap()
  // d.unit is Quarter
  assert_eq(d.dots, 0)
  assert_true(d.tuplet is None(_))
}

///|
test "parse_dur_unit_q_dotted_ok" {
  let r = @moonsic.parse_dur_unit("q.")
  assert_true(r.is_ok())
  let d = r.unwrap()
  assert_eq(d.dots, 1)
  assert_true(d.tuplet is None(_))
}

///|
test "parse_dur_unit_8_dotted_ok" {
  let r = @moonsic.parse_dur_unit("8.")
  assert_true(r.is_ok())
  let d = r.unwrap()
  assert_eq(d.dots, 1)
}

///|
test "parse_dur_unit_triplet_ok" {
  let r = @moonsic.parse_dur_unit("3:2 8")
  assert_true(r.is_ok())
  let d = r.unwrap()
  assert_eq(d.dots, 0)
  match d.tuplet {
    Some(ratio) => {
      assert_eq(ratio.actual, 3)
      assert_eq(ratio.normal, 2)
    }
    None => assert_true(false)
  }
}

///|
test "parse_dur_unit_whole_ok" {
  let r = @moonsic.parse_dur_unit("w")
  assert_true(r.is_ok())
}

///|
test "parse_dur_unit_half_ok" {
  let r = @moonsic.parse_dur_unit("h")
  assert_true(r.is_ok())
}

///|
test "parse_dur_unit_h_dotted_ok" {
  // "h." should be dotted half
  let r = @moonsic.parse_dur_unit("h.")
  assert_true(r.is_ok())
  let d = r.unwrap()
  assert_eq(d.dots, 1)
}

///|
test "parse_dur_unit_empty_err" {
  let r = @moonsic.parse_dur_unit("")
  assert_true(r.is_err())
}

///|
test "parse_dur_unit_invalid_err" {
  let r = @moonsic.parse_dur_unit("x")
  assert_true(r.is_err())
}

///|
test "parse_dur_unit_triplet_invalid_err" {
  // missing space
  let r = @moonsic.parse_dur_unit("3:28")
  assert_true(r.is_err())
}

///|
test "parse_dur_unit_double_dotted_ok" {
  // "q.." should be double-dotted quarter
  let r = @moonsic.parse_dur_unit("q..")
  assert_true(r.is_ok())
  let d = r.unwrap()
  assert_eq(d.dots, 2)
}

///|
test "parse_dur_unit_w_dotted_ok" {
  // "w." should be dotted whole
  let r = @moonsic.parse_dur_unit("w.")
  assert_true(r.is_ok())
  let d = r.unwrap()
  assert_eq(d.dots, 1)
}

// --- 解析：速度 ---

///|
test "parse_tempo_120_ok" {
  let r = @moonsic.parse_tempo("120")
  assert_true(r.is_ok())
  let bpm = r.unwrap()
  assert_true(bpm > 119.9 && bpm < 120.1)
}

///|
test "parse_tempo_120bpm_ok" {
  let r = @moonsic.parse_tempo("120bpm")
  assert_true(r.is_ok())
  let bpm = r.unwrap()
  assert_true(bpm > 119.9 && bpm < 120.1)
}

///|
test "parse_tempo_120_BPM_ok" {
  // case insensitive
  let r = @moonsic.parse_tempo("120BPM")
  assert_true(r.is_ok())
  let bpm = r.unwrap()
  assert_true(bpm > 119.9 && bpm < 120.1)
}

///|
test "parse_tempo_negative_err" {
  let r = @moonsic.parse_tempo("-120bpm")
  assert_true(r.is_err())
}

///|
test "parse_tempo_zero_err" {
  let r = @moonsic.parse_tempo("0")
  assert_true(r.is_err())
}

///|
test "parse_tempo_empty_err" {
  let r = @moonsic.parse_tempo("")
  assert_true(r.is_err())
}

///|
test "parse_tempo_invalid_err" {
  let r = @moonsic.parse_tempo("abc")
  assert_true(r.is_err())
}

// --- DurUnit 转字符串 ---

///|
test "dur_unit_to_string" {
  assert_eq(@moonsic.DurQuarter.to_string(), "q")
  assert_eq(@moonsic.DurEighth.to_string(), "8")
  assert_eq(@moonsic.DurWhole.to_string(), "w")
  assert_eq(@moonsic.DurSixteenth.to_string(), "16")
}

// --- TimeError to_string ---

///|
test "time_error_to_string" {
  let e = @moonsic.TimeParseError("test")
  assert_true(e.to_string().contains("解析错误"))
  let e2 = @moonsic.InvalidTempo("bad")
  assert_true(e2.to_string().contains("无效速度"))
}

// --- rhythm_duration_to_fraction ---

///|
test "rhythm_duration_to_fraction_quarter" {
  let d = @moonsic.RhythmDuration::{
    unit: @moonsic.DurQuarter,
    dots: 0,
    tuplet: None,
  }
  let frac = @moonsic.rhythm_duration_to_fraction(d)
  assert_eq(frac.numerator, 1)
  assert_eq(frac.denominator, 1)
}

///|
test "rhythm_duration_to_fraction_dotted_eighth" {
  let d = @moonsic.RhythmDuration::{
    unit: @moonsic.DurEighth,
    dots: 1,
    tuplet: None,
  }
  let frac = @moonsic.rhythm_duration_to_fraction(d)
  assert_eq(frac.numerator, 3)
  assert_eq(frac.denominator, 4)
}

///|
test "rhythm_duration_to_fraction_triplet_eighth" {
  let d = @moonsic.RhythmDuration::{
    unit: @moonsic.DurEighth,
    dots: 0,
    tuplet: Some(@moonsic.TupletRatio::{ actual: 3, normal: 2 }),
  }
  let frac = @moonsic.rhythm_duration_to_fraction(d)
  assert_eq(frac.numerator, 1)
  assert_eq(frac.denominator, 3)
}

// ============================================================
// Position 互转测试
// ============================================================

///|
test "position_to_ticks_bar1_beat0_4_4" {
  let pos = @moonsic.BarPosition::{
    bar: 1,
    beat: @moonsic.rational(0, 1).unwrap(),
    offset: @moonsic.rational(0, 1).unwrap(),
  }
  let sig = @moonsic.time_signature(4, 4)
  let ticks = @moonsic.position_to_ticks(pos, sig, 480).unwrap()
  assert_eq(ticks, 1920)
}

///|
test "position_to_ticks_bar0_beat2_4_4" {
  let pos = @moonsic.BarPosition::{
    bar: 0,
    beat: @moonsic.rational(2, 1).unwrap(),
    offset: @moonsic.rational(0, 1).unwrap(),
  }
  let sig = @moonsic.time_signature(4, 4)
  let ticks = @moonsic.position_to_ticks(pos, sig, 480).unwrap()
  assert_eq(ticks, 960)
}

///|
test "ticks_to_position_1920_4_4" {
  let sig = @moonsic.time_signature(4, 4)
  let pos = @moonsic.ticks_to_position(1920, sig, 480).unwrap()
  assert_eq(pos.bar, 1)
  assert_eq(pos.beat.numerator, 0)
  assert_eq(pos.offset.numerator, 0)
}

///|
test "ticks_to_position_960_4_4" {
  let sig = @moonsic.time_signature(4, 4)
  let pos = @moonsic.ticks_to_position(960, sig, 480).unwrap()
  assert_eq(pos.bar, 0)
  assert_eq(pos.beat.numerator, 2)
  assert_eq(pos.offset.numerator, 0)
}

///|
test "position_to_ticks_invalid_sig_err" {
  let pos = @moonsic.BarPosition::{
    bar: 0,
    beat: @moonsic.rational(0, 1).unwrap(),
    offset: @moonsic.rational(0, 1).unwrap(),
  }
  // 5/3 是非法拍号
  let sig = @moonsic.time_signature(5, 3)
  let r = @moonsic.position_to_ticks(pos, sig, 480)
  assert_true(r is Err(_))
}

///|
test "ticks_to_position_negative_tick_err" {
  let sig = @moonsic.time_signature(4, 4)
  let r = @moonsic.ticks_to_position(-1, sig, 480)
  assert_true(r is Err(_))
}

///|
test "position_to_ticks_invalid_ppq_err" {
  let pos = @moonsic.BarPosition::{
    bar: 0,
    beat: @moonsic.rational(0, 1).unwrap(),
    offset: @moonsic.rational(0, 1).unwrap(),
  }
  let sig = @moonsic.time_signature(4, 4)
  let r = @moonsic.position_to_ticks(pos, sig, 0)
  assert_true(r is Err(_))
}

// ============================================================
// TimeMap 测试
// ============================================================

///|
test "make_time_map_ok" {
  let sig = @moonsic.time_signature(4, 4)
  let tm = @moonsic.make_time_map(480, sig, 120.0).unwrap()
  assert_eq(tm.ppq, 480)
  assert_eq(tm.sig_num, 4)
  assert_eq(tm.sig_den, 4)
  assert_true(tm.tempo_bpm > 119.9 && tm.tempo_bpm < 120.1)
}

///|
test "make_time_map_invalid_ppq_err" {
  let sig = @moonsic.time_signature(4, 4)
  let r = @moonsic.make_time_map(0, sig, 120.0)
  assert_true(r is Err(_))
}

///|
test "make_time_map_invalid_sig_err" {
  let sig = @moonsic.time_signature(5, 3)
  let r = @moonsic.make_time_map(480, sig, 120.0)
  assert_true(r is Err(_))
}

///|
test "make_time_map_invalid_bpm_err" {
  let sig = @moonsic.time_signature(4, 4)
  let r = @moonsic.make_time_map(480, sig, 0.0)
  assert_true(r is Err(_))
}

///|
test "tempo_at_tick_before_change_initial" {
  let sig = @moonsic.time_signature(4, 4)
  let tm = @moonsic.make_time_map(480, sig, 120.0).unwrap()
  let bpm = @moonsic.tempo_at_tick(tm, 0)
  assert_true(bpm > 119.9 && bpm < 120.1)
}

///|
test "tempo_at_tick_at_change_value" {
  let sig = @moonsic.time_signature(4, 4)
  let tm = @moonsic.make_time_map(480, sig, 120.0).unwrap()
  let ch = @moonsic.TempoChange::{ at_tick: 480, tempo_bpm: 140.0 }
  let tm2 = @moonsic.add_tempo_change(tm, ch)
  // Before change (tick 479): still 120
  let bpm_before = @moonsic.tempo_at_tick(tm2, 479)
  assert_true(bpm_before > 119.9 && bpm_before < 120.1)
  // At change (tick 480): becomes 140
  let bpm_at = @moonsic.tempo_at_tick(tm2, 480)
  assert_true(bpm_at > 139.9 && bpm_at < 140.1)
  // After change (tick 960): stays 140
  let bpm_after = @moonsic.tempo_at_tick(tm2, 960)
  assert_true(bpm_after > 139.9 && bpm_after < 140.1)
}

///|
test "signature_at_bar_default_sig" {
  let sig = @moonsic.time_signature(4, 4)
  let tm = @moonsic.make_time_map(480, sig, 120.0).unwrap()
  let (num, den) = @moonsic.signature_at_bar(tm, 0)
  assert_eq(num, 4)
  assert_eq(den, 4)
}

///|
test "add_tempo_change_returns_timemap" {
  let sig = @moonsic.time_signature(4, 4)
  let tm = @moonsic.make_time_map(480, sig, 120.0).unwrap()
  let ch = @moonsic.TempoChange::{ at_tick: 960, tempo_bpm: 100.0 }
  let tm2 = @moonsic.add_tempo_change(tm, ch)
  assert_eq(tm2.tempo_changes.length(), 1)
  assert_eq(tm2.tempo_changes[0].at_tick, 960)
}

///|
test "add_sig_change_updates_signature_at_bar" {
  let sig = @moonsic.time_signature(4, 4)
  let tm = @moonsic.make_time_map(480, sig, 120.0).unwrap()
  let ch = @moonsic.TimeSigChange::{ at_bar: 4, sig_num: 3, sig_den: 4 }
  let tm2 = @moonsic.add_sig_change(tm, ch)
  // Before bar 4: still 4/4
  let (n1, d1) = @moonsic.signature_at_bar(tm2, 3)
  assert_eq(n1, 4)
  assert_eq(d1, 4)
  // At bar 4: becomes 3/4
  let (n2, d2) = @moonsic.signature_at_bar(tm2, 4)
  assert_eq(n2, 3)
  assert_eq(d2, 4)
}

///|
test "ticks_to_seconds_timemap_basic" {
  let sig = @moonsic.time_signature(4, 4)
  let tm = @moonsic.make_time_map(480, sig, 120.0).unwrap()
  // 480 ticks at 120 bpm ppq=480 → 0.5 seconds
  let sec = @moonsic.ticks_to_seconds_timemap(480, tm).unwrap()
  assert_true(sec > 0.49 && sec < 0.51)
}

///|
test "ticks_to_seconds_timemap_multi_tempo" {
  let sig = @moonsic.time_signature(4, 4)
  let tm = @moonsic.make_time_map(480, sig, 120.0).unwrap()
  let ch = @moonsic.TempoChange::{ at_tick: 480, tempo_bpm: 60.0 }
  let tm2 = @moonsic.add_tempo_change(tm, ch)
  // Segment 1: 0..480 at 120 bpm → 0.5s
  // Segment 2: 480..960 at 60 bpm → 1.0s
  // Total: 1.5s
  let sec = @moonsic.ticks_to_seconds_timemap(960, tm2).unwrap()
  assert_true(sec > 1.49 && sec < 1.51)
}

///|
test "ticks_to_seconds_timemap_negative_target_err" {
  let sig = @moonsic.time_signature(4, 4)
  let tm = @moonsic.make_time_map(480, sig, 120.0).unwrap()
  let r = @moonsic.ticks_to_seconds_timemap(-1, tm)
  assert_true(r is Err(_))
}

// ============================================================
// FFI JSON 测试
// ============================================================

///|
test "ffi_parse_time_sig_4_4" {
  let json = @moonsic.ffi_parse_time_sig("4/4")
  assert_true(json.contains("4"))
  assert_true(json.contains("true"))
}

///|
test "ffi_duration_ticks_q_480" {
  let json = @moonsic.ffi_duration_ticks("q", 480)
  assert_true(json.contains("480"))
  assert_true(json.contains("true"))
}

///|
test "ffi_parse_tempo_120bpm" {
  let json = @moonsic.ffi_parse_tempo("120bpm")
  assert_true(json.contains("120"))
  assert_true(json.contains("true"))
}

///|
test "ffi_parse_time_sig_5_3_error" {
  let json = @moonsic.ffi_parse_time_sig("5/3")
  assert_true(json.contains("error"))
  assert_true(json.contains("false"))
}

///|
test "ffi_bar_length_4_4_480" {
  let json = @moonsic.ffi_bar_length("4/4", 480)
  assert_true(json.contains("1920"))
  assert_true(json.contains("true"))
}

///|
test "ffi_ticks_to_seconds_480_120_480" {
  let json = @moonsic.ffi_ticks_to_seconds(480, 120.0, 480)
  assert_true(json.contains("0.5"))
  assert_true(json.contains("true"))
}

///|
test "ffi_duration_ticks_invalid_err" {
  let json = @moonsic.ffi_duration_ticks("x", 480)
  assert_true(json.contains("error"))
  assert_true(json.contains("false"))
}

///|
test "ffi_parse_tempo_invalid_err" {
  let json = @moonsic.ffi_parse_tempo("-120bpm")
  assert_true(json.contains("error"))
  assert_true(json.contains("false"))
}

// ============================================================
// 播放时间线测试 — PlaybackTimeline
// ============================================================

///|
test "timeline_from_score_single_note" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let score = @moonsic.score1(t)
  let tl = @moonsic.timeline_from_score(score)
  assert_eq(tl.event_count(), 1)
  assert_true(tl.total_seconds > 0.49 && tl.total_seconds < 0.51)
}

///|
test "timeline_from_score_empty" {
  let score = @moonsic.score([])
  let tl = @moonsic.timeline_from_score(score)
  assert_eq(tl.event_count(), 0)
  assert_eq(tl.duration(), 0.0)
  assert_true(tl.is_empty())
}

///|
test "timeline_at_second_active" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let score = @moonsic.score1(t)
  let tl = @moonsic.timeline_from_score(score)
  // t=0.0 应该捕获到事件
  let active = tl.at_second(0.0)
  assert_eq(active.length(), 1)
  assert_eq(active[0].midi_note, 60)
}

///|
test "timeline_at_second_at_boundary" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let score = @moonsic.score1(t)
  let tl = @moonsic.timeline_from_score(score)
  // t=0.5 是事件结束时刻，在半开区间 [start, end) 中不该被捕获
  let at_exact_end = tl.at_second(0.5)
  assert_eq(at_exact_end.length(), 0)
  // t=0.499 接近结束但仍在区间内
  let at_just_before = tl.at_second(0.499)
  assert_eq(at_just_before.length(), 1)
}

///|
test "timeline_at_second_empty" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let score = @moonsic.score1(t)
  let tl = @moonsic.timeline_from_score(score)
  // 事件在 [0.0, 0.5)，t=1.0 外
  let active = tl.at_second(1.0)
  assert_eq(active.length(), 0)
}

///|
test "timeline_events_between_range" {
  let t = @moonsic.melody([
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.e(4), @moonsic.quarter()),
  ])
  let score = @moonsic.score1(t)
  let tl = @moonsic.timeline_from_score(score)
  // 第二拍: 0.5 ~ 1.0，D4 在此区间
  let between = tl.events_between(0.5, 1.0)
  assert_eq(between.length(), 1)
  assert_eq(between[0].midi_note, 62)
}

///|
test "timeline_events_between_overlap" {
  let t = @moonsic.melody([
    @moonsic.n(@moonsic.c(4), @moonsic.half()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
  ])
  let score = @moonsic.score1(t)
  let tl = @moonsic.timeline_from_score(score)
  // 窗口 0.25 ~ 0.75，C4(half) 覆盖整个范围，D4 从 beat 2 开始（秒=1.0）不覆盖
  let between = tl.events_between(0.25, 0.75)
  assert_eq(between.length(), 1)
  assert_eq(between[0].midi_note, 60)
}

///|
test "timeline_at_second_chord" {
  let evt = @moonsic.major(@moonsic.c(4), @moonsic.quarter())
  let t = @moonsic.melody([evt])
  let score = @moonsic.score1(t)
  let tl = @moonsic.timeline_from_score(score)
  // C major 和弦 3 音在 t=0
  let active = tl.at_second(0.0)
  assert_eq(active.length(), 3)
}

///|
test "timeline_from_score_multi_track" {
  let t1 = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let t2 = @moonsic.track_with_channel(
    [@moonsic.n(@moonsic.e(4), @moonsic.quarter())],
    1,
  )
  let score = @moonsic.score([t1, t2])
  let tl = @moonsic.timeline_from_score(score)
  assert_eq(tl.event_count(), 2)
  // 两个事件都在 t=0
  let active = tl.at_second(0.0)
  assert_eq(active.length(), 2)
}

///|
test "timeline_from_score_custom_tempo" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let score = @moonsic.score_with([t], 60, @moonsic.four_four())
  let tl = @moonsic.timeline_from_score(score)
  // 60bpm: quarter = 1.0s
  assert_true(tl.total_seconds > 0.99 && tl.total_seconds < 1.01)
  // 事件在 t=0
  let active = tl.at_second(0.0)
  assert_eq(active.length(), 1)
}

///|
test "timeline_at_second_channel_filter" {
  let t1 = @moonsic.track_with_channel(
    [@moonsic.n(@moonsic.c(4), @moonsic.quarter())],
    0,
  )
  let t2 = @moonsic.track_with_channel(
    [@moonsic.n(@moonsic.e(4), @moonsic.quarter())],
    1,
  )
  let score = @moonsic.score([t1, t2])
  let tl = @moonsic.timeline_from_score(score)
  // channel 0
  let ch0 = tl.at_second_channel(0.0, 0)
  assert_eq(ch0.length(), 1)
  assert_eq(ch0[0].midi_note, 60)
  // channel 1
  let ch1 = tl.at_second_channel(0.0, 1)
  assert_eq(ch1.length(), 1)
  assert_eq(ch1[0].midi_note, 64)
  // non-existent channel
  let ch2 = tl.at_second_channel(0.0, 2)
  assert_eq(ch2.length(), 0)
}

///|
test "timeline_duration_beats_conversion" {
  let t = @moonsic.melody([
    @moonsic.n(@moonsic.c(4), @moonsic.half()),
    @moonsic.n(@moonsic.d(4), @moonsic.half()),
  ])
  let score = @moonsic.score_with([t], 120, @moonsic.four_four())
  let tl = @moonsic.timeline_from_score(score)
  // 2 half = 4 beats = 2.0s at 120bpm
  assert_eq(tl.duration(), 2.0)
}

///|
test "timeline_event_start_is_seconds" {
  let t = @moonsic.melody([
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
  ])
  let score = @moonsic.score_with([t], 120, @moonsic.four_four())
  let tl = @moonsic.timeline_from_score(score)
  // C4 在 [0.0, 0.5)，D4 在 [0.5, 1.0)，查询 [0.5, 0.6) 仅覆盖 D4
  let events = tl.events_between(0.5, 0.6)
  assert_eq(events.length(), 1)
  assert_eq(events[0].midi_note, 62)
}

///|
test "timeline_last_end" {
  let t = @moonsic.melody([
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.half()),
  ])
  let score = @moonsic.score_with([t], 120, @moonsic.four_four())
  let tl = @moonsic.timeline_from_score(score)
  // C4 在 0.0 ~ 0.5, D4(half) 在 0.5 ~ 1.5
  assert_true(tl.last_end() > 1.49 && tl.last_end() < 1.51)
}

///|
test "timeline_last_end_empty" {
  let score = @moonsic.score([])
  let tl = @moonsic.timeline_from_score(score)
  assert_eq(tl.last_end(), 0.0)
}

///|
test "timeline_events_between_empty_range" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let score = @moonsic.score1(t)
  let tl = @moonsic.timeline_from_score(score)
  // 事件在 [0, 0.5)，查询 [10, 20) 无交集
  let between = tl.events_between(10.0, 20.0)
  assert_eq(between.length(), 0)
}

///|
test "timeline_to_string" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let score = @moonsic.score1(t)
  let tl = @moonsic.timeline_from_score(score)
  let s = tl.to_string()
  assert_true(s.contains("PlaybackTimeline"))
  assert_true(s.contains("1"))
}

// ============================================================
// score_midi 测试 — MIDI 语义适配层
// ============================================================

///|
test "score_midi_validate_midi_note" {
  assert_true(@moonsic.validate_midi_note(0))
  assert_true(@moonsic.validate_midi_note(60))
  assert_true(@moonsic.validate_midi_note(127))
  assert_false(@moonsic.validate_midi_note(-1))
  assert_false(@moonsic.validate_midi_note(128))
}

///|
test "score_midi_validate_channel" {
  assert_true(@moonsic.validate_channel(0))
  assert_true(@moonsic.validate_channel(15))
  assert_false(@moonsic.validate_channel(-1))
  assert_false(@moonsic.validate_channel(16))
}

///|
test "score_midi_validate_velocity" {
  assert_true(@moonsic.validate_velocity(0))
  assert_true(@moonsic.validate_velocity(127))
  assert_false(@moonsic.validate_velocity(-1))
  assert_false(@moonsic.validate_velocity(128))
}

///|
test "score_midi_validate_program" {
  assert_true(@moonsic.validate_program(0))
  assert_true(@moonsic.validate_program(127))
  assert_false(@moonsic.validate_program(-1))
  assert_false(@moonsic.validate_program(128))
}

///|
test "score_midi_note_on_ok" {
  let r = @moonsic.note_on(0, 0, 60, 100)
  assert_true(r.is_ok())
  let e = r.unwrap()
  assert_eq(e.tick, 0)
}

///|
test "score_midi_note_on_invalid_note" {
  let r = @moonsic.note_on(0, 0, 128, 100)
  assert_true(r.is_err())
}

///|
test "score_midi_note_on_invalid_channel" {
  let r = @moonsic.note_on(0, 16, 60, 100)
  assert_true(r.is_err())
}

///|
test "score_midi_program_change_ok" {
  let r = @moonsic.program_change(0, 0, 40)
  assert_true(r.is_ok())
  let e = r.unwrap()
  assert_eq(e.tick, 0)
}

///|
test "score_midi_program_change_invalid" {
  let r = @moonsic.program_change(0, 0, 128)
  assert_true(r.is_err())
}

///|
test "score_midi_control_change_ok" {
  let r = @moonsic.control_change(0, 0, 7, 100)
  assert_true(r.is_ok())
  let e = r.unwrap()
  assert_eq(e.tick, 0)
}

///|
test "score_midi_control_change_invalid_ctrl" {
  let r = @moonsic.control_change(0, 0, 128, 100)
  assert_true(r.is_err())
}

///|
test "score_midi_to_score_basic" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let s = @moonsic.score1(t)
  let ms = @moonsic.score_to_midi_score(s, 480)
  assert_eq(ms.tracks.length(), 2)
  assert_eq(ms.ppq, 480)
  let music = ms.tracks[1]
  assert_true(music.events.length() >= 4)
}

///|
test "score_midi_to_score_with_instrument" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let t2 = @moonsic.instrument(t, @moonsic.violin())
  let s = @moonsic.score1(t2)
  let ms = @moonsic.score_to_midi_score(s, 480)
  assert_eq(ms.tracks.length(), 2)
  assert_eq(ms.tracks[1].program, 40)
}

///|
test "score_midi_sort_events_by_tick" {
  let e1 = @moonsic.note_on(480, 0, 60, 100).unwrap()
  let e2 = @moonsic.note_on(0, 0, 60, 100).unwrap()
  let sorted = @moonsic.sort_midi_events([e1, e2])
  assert_eq(sorted[0].tick, 0)
  assert_eq(sorted[1].tick, 480)
}

///|
test "score_midi_sort_events_same_tick_priority" {
  let e1 = @moonsic.note_on(0, 0, 60, 100).unwrap()
  let e2 = @moonsic.tempo_change(0, 120).unwrap()
  let e3 = @moonsic.track_name(0, "Test").unwrap()
  let sorted = @moonsic.sort_midi_events([e1, e2, e3])
  assert_eq(sorted.length(), 3)
  assert_eq(sorted[0].tick, 0)
  assert_eq(sorted[1].tick, 0)
  assert_eq(sorted[2].tick, 0)
}

///|
test "score_midi_to_bytes_not_empty" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let s = @moonsic.score1(t)
  let ms = @moonsic.score_to_midi_score(s, 480)
  let bytes = @moonsic.midi_score_to_bytes(ms)
  assert_true(bytes.length() > 0)
}

///|
test "score_midi_roundtrip" {
  let t = @moonsic.melody([
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
  ])
  let s = @moonsic.score1(t)
  let bytes = @moonsic.score_to_midi_bytes(s, 480)
  let file = @midi.parse(bytes)
  assert_eq(file.tracks.length(), 2)
  assert_eq(file.division, (480).to_uint16())
}

///|
test "score_midi_to_score_two_tracks" {
  let t1 = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let t2 = @moonsic.melody([@moonsic.n(@moonsic.e(4), @moonsic.quarter())])
  let s = @moonsic.score([t1, t2])
  let ms = @moonsic.score_to_midi_score(s, 480)
  assert_eq(ms.tracks.length(), 3)
}

///|
test "score_midi_tempo_change_event" {
  let r = @moonsic.tempo_change(0, 140)
  assert_true(r.is_ok())
  let e = r.unwrap()
  assert_eq(e.tick, 0)
}

///|
test "score_midi_tempo_change_invalid_bpm" {
  let r = @moonsic.tempo_change(0, 0)
  assert_true(r.is_err())
}

///|
test "score_midi_end_of_track" {
  let r = @moonsic.end_of_track(960)
  assert_true(r.is_ok())
  let e = r.unwrap()
  assert_eq(e.tick, 960)
}

///|
test "score_midi_multi_note_score" {
  let t = @moonsic.melody([
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.e(4), @moonsic.half()),
  ])
  let s = @moonsic.score1(t)
  let ms = @moonsic.score_to_midi_score(s, 480)
  let music = ms.tracks[1]
  assert_eq(music.events.length(), 8)
}

///|
test "score_midi_chord_expands" {
  let t = @moonsic.melody([@moonsic.major(@moonsic.c(4), @moonsic.quarter())])
  let s = @moonsic.score1(t)
  let ms = @moonsic.score_to_midi_score(s, 480)
  let music = ms.tracks[1]
  assert_eq(music.events.length(), 8)
}

///|
test "score_midi_bytes_with_instrument" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let t2 = @moonsic.instrument(t, @moonsic.acoustic_grand_piano())
  let s = @moonsic.score1(t2)
  let bytes = @moonsic.score_to_midi_bytes(s, 480)
  let file = @midi.parse(bytes)
  assert_eq(file.tracks.length(), 2)
}

// ============================================================
// 曲谱布局模块测试 — Measure/Voice/Staff/Part/ScoreLayout
// ============================================================

// --- Measure 构造 ---

///|
test "make_measure_valid" {
  let sig = @moonsic.four_four()
  let events = [@moonsic.n(@moonsic.c(4), @moonsic.quarter())]
  let r = @moonsic.make_measure(0, Some(sig), events)
  assert_true(r.is_ok())
  let m = r.unwrap()
  assert_eq(m.index, 0)
  assert_eq(m.event_count(), 1)
}

///|
test "make_measure_negative_index_err" {
  let sig = @moonsic.four_four()
  let r = @moonsic.make_measure(-1, Some(sig), [])
  assert_true(r.is_err())
}

///|
test "make_measure_invalid_time_sig_err" {
  let bad_sig = @moonsic.time_signature(5, 3)
  let r = @moonsic.make_measure(0, Some(bad_sig), [])
  assert_true(r.is_err())
}

///|
test "empty_measure_creates_basic" {
  let m = @moonsic.empty_measure(3)
  assert_eq(m.index, 3)
  assert_eq(m.event_count(), 0)
}

// --- Voice 构造 ---

///|
test "make_voice_valid" {
  let m = @moonsic.empty_measure(0)
  let r = @moonsic.make_voice("RH", [m])
  assert_true(r.is_ok())
  let v = r.unwrap()
  assert_eq(@moonsic.voice_measure_count(v), 1)
}

///|
test "make_voice_empty_name_err" {
  let r = @moonsic.make_voice("", [])
  assert_true(r.is_err())
}

///|
test "voice_add_measure_adds_one" {
  let v = @moonsic.empty_voice("RH")
  let m = @moonsic.empty_measure(0)
  let r = @moonsic.voice_add_measure(v, m)
  assert_true(r.is_ok())
  let v2 = r.unwrap()
  assert_eq(@moonsic.voice_measure_count(v2), 1)
}

///|
test "empty_voice_creates_with_name" {
  let v = @moonsic.empty_voice("Bass")
  assert_eq(@moonsic.voice_measure_count(v), 0)
}

// --- Staff 构造 ---

///|
test "make_staff_valid" {
  let v = @moonsic.empty_voice("RH")
  let r = @moonsic.make_staff("Piano", Some(0), Some(0), Some("Grand Piano"), [
    v,
  ])
  assert_true(r.is_ok())
  let s = r.unwrap()
  assert_eq(s.name, "Piano")
}

///|
test "make_staff_invalid_channel_err" {
  let r = @moonsic.make_staff("Piano", Some(16), None, None, [])
  assert_true(r.is_err())
}

///|
test "make_staff_invalid_program_err" {
  let r = @moonsic.make_staff("Piano", None, Some(128), None, [])
  assert_true(r.is_err())
}

///|
test "staff_add_voice_adds_one" {
  let s = @moonsic.empty_staff("Piano")
  let v = @moonsic.empty_voice("RH")
  let r = @moonsic.staff_add_voice(s, v)
  assert_true(r.is_ok())
}

// --- Part 构造 ---

///|
test "make_part_valid" {
  let s = @moonsic.empty_staff("Piano")
  let r = @moonsic.make_part("Keyboard", [s])
  assert_true(r.is_ok())
}

///|
test "part_add_staff_adds_one" {
  let p = @moonsic.empty_part("Keyboard")
  let s = @moonsic.empty_staff("Piano")
  let r = @moonsic.part_add_staff(p, s)
  assert_true(r.is_ok())
  let p2 = r.unwrap()
  assert_eq(p2.staves.length(), 1)
}

// --- ScoreLayout 构造 ---

///|
test "make_score_layout_valid" {
  let r = @moonsic.make_score_layout("My Song", 480, [])
  assert_true(r.is_ok())
  let sl = r.unwrap()
  assert_eq(sl.title, "My Song")
  assert_eq(sl.ppq, 480)
}

///|
test "make_score_layout_invalid_ppq_zero_err" {
  let r = @moonsic.make_score_layout("Bad", 0, [])
  assert_true(r.is_err())
}

///|
test "empty_score_layout_creates_basic" {
  let r = @moonsic.empty_score_layout("Empty", 480)
  assert_true(r.is_ok())
  let sl = r.unwrap()
  assert_eq(sl.title, "Empty")
  assert_eq(@moonsic.score_layout_measure_count(sl), 0)
}

///|
test "layout_add_part_works" {
  let r = @moonsic.empty_score_layout("Song", 480)
  let sl = r.unwrap()
  let p = @moonsic.empty_part("Piano")
  let sl2 = @moonsic.layout_add_part(sl, p)
  assert_eq(sl2.parts.length(), 1)
}

// --- 校验 ---

///|
test "validate_measure_under_capacity_ok" {
  let sig = @moonsic.four_four()
  let events = [
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
  ]
  let r = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let vr = @moonsic.validate_measure(r, sig, 480)
  assert_true(vr.is_ok())
}

///|
test "validate_measure_overflow_err" {
  // 4/4 at ppq=480 has 1920 ticks. Whole(1920) + Half(960) = 2880 > 1920
  let sig = @moonsic.four_four()
  let events = [
    @moonsic.n(@moonsic.c(4), @moonsic.whole()),
    @moonsic.n(@moonsic.d(4), @moonsic.half()),
  ]
  let r = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let vr = @moonsic.validate_measure(r, sig, 480)
  assert_true(vr.is_err())
}

///|
test "validate_measure_at_capacity_ok" {
  let sig = @moonsic.four_four()
  let events = [
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.e(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.f(4), @moonsic.quarter()),
  ]
  let r = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let vr = @moonsic.validate_measure(r, sig, 480)
  assert_true(vr.is_ok())
}

///|
test "validate_measure_overflow_3_4" {
  let sig = @moonsic.time_signature(3, 4)
  // 3/4 at ppq=480 has 1440 ticks. Half(960) + Q(480) + Q(480) = 1920 > 1440
  let events = [
    @moonsic.n(@moonsic.c(4), @moonsic.half()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.e(4), @moonsic.quarter()),
  ]
  let r = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let vr = @moonsic.validate_measure(r, sig, 480)
  assert_true(vr.is_err())
}

///|
test "validate_measure_invalid_ppq_err" {
  let sig = @moonsic.four_four()
  let events = [@moonsic.n(@moonsic.c(4), @moonsic.quarter())]
  let r = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let vr = @moonsic.validate_measure(r, sig, 0)
  assert_true(vr.is_err())
}

///|
test "validate_score_layout_full_ok" {
  let sig = @moonsic.four_four()
  let events = [
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
  ]
  let m = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let v = @moonsic.make_voice("RH", [m]).unwrap()
  let s = @moonsic.make_staff("Piano", Some(0), Some(0), None, [v]).unwrap()
  let p = @moonsic.make_part("Keyboard", [s]).unwrap()
  let sl = @moonsic.make_score_layout("Test", 480, [p]).unwrap()
  let vr = @moonsic.validate_score_layout(sl)
  assert_true(vr.is_ok())
}

///|
test "validate_score_layout_overflow_fail" {
  let sig = @moonsic.four_four()
  let events = [
    @moonsic.n(@moonsic.c(4), @moonsic.whole()),
    @moonsic.n(@moonsic.d(4), @moonsic.half()),
  ]
  let m = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let v = @moonsic.make_voice("RH", [m]).unwrap()
  let s = @moonsic.make_staff("Piano", Some(0), None, None, [v]).unwrap()
  let p = @moonsic.make_part("Keyboard", [s]).unwrap()
  let sl = @moonsic.make_score_layout("Test", 480, [p]).unwrap()
  let vr = @moonsic.validate_score_layout(sl)
  assert_true(vr.is_err())
}

// --- 查询 ---

///|
test "measure_beat_duration_two_halves" {
  let sig = @moonsic.four_four()
  let events = [
    @moonsic.n(@moonsic.c(4), @moonsic.half()),
    @moonsic.n(@moonsic.d(4), @moonsic.half()),
  ]
  let m = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let dur = @moonsic.measure_beat_duration(m)
  assert_true(dur > 3.99 && dur < 4.01)
}

///|
test "measure_tick_duration_quarter" {
  let sig = @moonsic.four_four()
  let events = [@moonsic.n(@moonsic.c(4), @moonsic.quarter())]
  let m = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let ticks = @moonsic.measure_tick_duration(m, 480)
  assert_eq(ticks, 480)
}

///|
test "voice_measure_count_three" {
  let m0 = @moonsic.empty_measure(0)
  let m1 = @moonsic.empty_measure(1)
  let m2 = @moonsic.empty_measure(2)
  let v = @moonsic.make_voice("RH", [m0, m1, m2]).unwrap()
  assert_eq(@moonsic.voice_measure_count(v), 3)
}

///|
test "staff_measure_count_max_voice" {
  let m0 = @moonsic.empty_measure(0)
  let m1 = @moonsic.empty_measure(1)
  let v0 = @moonsic.make_voice("RH", [m0]).unwrap()
  let v1 = @moonsic.make_voice("LH", [m0, m1]).unwrap()
  let s = @moonsic.make_staff("Piano", None, None, None, [v0, v1]).unwrap()
  assert_eq(@moonsic.staff_measure_count(s), 2)
}

///|
test "score_layout_measure_count_multi_part" {
  let m = @moonsic.empty_measure(0)
  let v = @moonsic.make_voice("RH", [m]).unwrap()
  let s = @moonsic.make_staff("Piano", None, None, None, [v]).unwrap()
  let p = @moonsic.make_part("Keyboard", [s]).unwrap()
  let sl = @moonsic.make_score_layout("Song", 480, [p]).unwrap()
  assert_eq(@moonsic.score_layout_measure_count(sl), 1)
}

///|
test "score_layout_measure_count_empty" {
  let sl = @moonsic.empty_score_layout("Empty", 480).unwrap()
  assert_eq(@moonsic.score_layout_measure_count(sl), 0)
}

// --- 转换 ---

///|
test "staff_to_track_single_voice" {
  let sig = @moonsic.four_four()
  let events = [
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
  ]
  let m = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let v = @moonsic.make_voice("RH", [m]).unwrap()
  let s = @moonsic.make_staff("Piano", Some(0), Some(0), None, [v]).unwrap()
  let track = @moonsic.staff_to_track(s)
  assert_eq(track.channel, 0)
  assert_eq(track.program, 0)
  assert_eq(track.events.length(), 2)
}

///|
test "staff_to_track_default_channel_no_voices" {
  let s = @moonsic.empty_staff("Empty")
  let track = @moonsic.staff_to_track(s)
  assert_eq(track.channel, 0)
  assert_eq(track.program, -1)
  assert_eq(track.events.length(), 0)
}

///|
test "staff_to_track_multi_voice_interleave" {
  let sig = @moonsic.four_four()
  let events_rh = [@moonsic.n(@moonsic.c(4), @moonsic.quarter())]
  let events_lh = [@moonsic.n(@moonsic.c(3), @moonsic.quarter())]
  let m0 = @moonsic.make_measure(0, Some(sig), events_rh).unwrap()
  let m1 = @moonsic.make_measure(0, Some(sig), events_lh).unwrap()
  let v_rh = @moonsic.make_voice("RH", [m0]).unwrap()
  let v_lh = @moonsic.make_voice("LH", [m1]).unwrap()
  let s = @moonsic.make_staff("Piano", Some(0), None, None, [v_rh, v_lh]).unwrap()
  let track = @moonsic.staff_to_track(s)
  assert_eq(track.events.length(), 2)
}

///|
test "score_layout_to_score_multi_part" {
  let sig = @moonsic.four_four()
  let events = [@moonsic.n(@moonsic.c(4), @moonsic.quarter())]
  let m = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let v = @moonsic.make_voice("RH", [m]).unwrap()
  let s = @moonsic.make_staff("Piano", Some(0), Some(0), None, [v]).unwrap()
  let p = @moonsic.make_part("Keyboard", [s]).unwrap()
  let sl = @moonsic.make_score_layout("Song", 480, [p]).unwrap()
  let score = @moonsic.score_layout_to_score(sl)
  assert_eq(score.track_count(), 1)
  assert_eq(score.tracks[0].event_count(), 1)
}

// --- 错误路径测试 ---

///|
test "make_staff_empty_name_err" {
  let r = @moonsic.make_staff("", None, None, None, [])
  assert_true(r.is_err())
}

///|
test "make_staff_channel_negative_err" {
  let r = @moonsic.make_staff("Piano", Some(-1), None, None, [])
  assert_true(r.is_err())
}

///|
test "make_staff_program_negative_err" {
  let r = @moonsic.make_staff("Piano", None, Some(-1), None, [])
  assert_true(r.is_err())
}

///|
test "validate_voice_empty_name_err" {
  let v = @moonsic.empty_voice("")
  let vr = @moonsic.validate_voice(v, @moonsic.four_four(), 480)
  assert_true(vr.is_err())
}

///|
test "validate_staff_valid_ok" {
  let sig = @moonsic.four_four()
  let m = @moonsic.empty_measure(0)
  let v = @moonsic.make_voice("RH", [m]).unwrap()
  let s = @moonsic.make_staff("Piano", Some(0), None, None, [v]).unwrap()
  let vr = @moonsic.validate_staff(s, sig, 480)
  assert_true(vr.is_ok())
}

///|
test "validate_part_valid_ok" {
  let sig = @moonsic.four_four()
  let m = @moonsic.empty_measure(0)
  let v = @moonsic.make_voice("RH", [m]).unwrap()
  let s = @moonsic.make_staff("Piano", Some(0), None, None, [v]).unwrap()
  let p = @moonsic.make_part("Keyboard", [s]).unwrap()
  let vr = @moonsic.validate_part(p, sig, 480)
  assert_true(vr.is_ok())
}

///|
test "validate_part_empty_name_err" {
  let p = @moonsic.empty_part("")
  let vr = @moonsic.validate_part(p, @moonsic.four_four(), 480)
  assert_true(vr.is_err())
}

// --- ScoreError to_string ---

///|
test "score_error_invalid_measure_to_string" {
  let e = @moonsic.InvalidMeasure("bad measure")
  assert_true(e.to_string().contains("无效小节"))
}

///|
test "score_error_measure_overflow_to_string" {
  let e = @moonsic.MeasureOverflow("bar 3 overflow")
  assert_true(e.to_string().contains("小节溢出"))
}

///|
test "score_error_invalid_ppq_to_string" {
  let e = @moonsic.ScoreError::InvalidPPQ(0)
  assert_true(e.to_string().contains("无效 PPQ"))
}

///|
test "score_error_invalid_channel_to_string" {
  let e = @moonsic.InvalidChannel(16)
  assert_true(e.to_string().contains("无效通道"))
}

///|
test "score_error_invalid_program_to_string" {
  let e = @moonsic.InvalidProgram(128)
  assert_true(e.to_string().contains("无效乐器"))
}

///|
test "score_error_invalid_voice_to_string" {
  let e = @moonsic.InvalidVoice("bad")
  assert_true(e.to_string().contains("无效声部"))
}

///|
test "score_error_invalid_staff_to_string" {
  let e = @moonsic.InvalidStaff("bad")
  assert_true(e.to_string().contains("无效五线谱"))
}

///|
test "score_error_invalid_part_to_string" {
  let e = @moonsic.InvalidPart("bad")
  assert_true(e.to_string().contains("无效声部组"))
}

///|
test "score_error_invalid_score_layout_to_string" {
  let e = @moonsic.InvalidScoreLayout("bad")
  assert_true(e.to_string().contains("无效曲谱布局"))
}

// --- track_to_voice 反推 ---

///|
test "track_to_voice_basic" {
  let t = @moonsic.melody([
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
  ])
  let r = @moonsic.track_to_voice(t, "Melody", 480, @moonsic.four_four())
  assert_true(r.is_ok())
  let v = r.unwrap()
  assert_eq(@moonsic.voice_measure_count(v), 1)
}

///|
test "track_to_voice_measure_split" {
  let t = @moonsic.melody([
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.e(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.f(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.g(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.a(4), @moonsic.quarter()),
  ])
  let r = @moonsic.track_to_voice(t, "Melody", 480, @moonsic.four_four())
  assert_true(r.is_ok())
  let v = r.unwrap()
  assert_eq(@moonsic.voice_measure_count(v), 2)
}

///|
test "track_to_voice_invalid_ppq_err" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let r = @moonsic.track_to_voice(t, "Bad", 0, @moonsic.four_four())
  assert_true(r.is_err())
}

///|
test "track_to_voice_invalid_time_sig_err" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let bad_sig = @moonsic.time_signature(5, 3)
  let r = @moonsic.track_to_voice(t, "Bad", 480, bad_sig)
  assert_true(r.is_err())
}

// --- track_to_staff 反推 ---

///|
test "track_to_staff_basic" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let r = @moonsic.track_to_staff(t, "Piano", 480, @moonsic.four_four())
  assert_true(r.is_ok())
}

///|
test "track_to_staff_no_program" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let r = @moonsic.track_to_staff(t, "Melody", 480, @moonsic.four_four())
  assert_true(r.is_ok())
}

// --- 边界值测试 ---

///|
test "make_measure_none_signature_ok" {
  let r = @moonsic.make_measure(0, None, [])
  assert_true(r.is_ok())
  let m = r.unwrap()
  assert_eq(m.index, 0)
  assert_eq(m.event_count(), 0)
}

///|
test "measure_beat_duration_with_rest" {
  let sig = @moonsic.four_four()
  let events = [
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.r(@moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.half()),
  ]
  let m = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let dur = @moonsic.measure_beat_duration(m)
  assert_true(dur > 3.99 && dur < 4.01)
}

///|
test "staff_to_track_preserves_chord" {
  let sig = @moonsic.four_four()
  let events = [@moonsic.major(@moonsic.c(4), @moonsic.quarter())]
  let m = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let v = @moonsic.make_voice("RH", [m]).unwrap()
  let s = @moonsic.make_staff("Piano", Some(0), None, None, [v]).unwrap()
  let track = @moonsic.staff_to_track(s)
  assert_eq(track.events.length(), 1)
}

///|
test "score_layout_to_score_empty" {
  let sl = @moonsic.empty_score_layout("Empty", 480).unwrap()
  let score = @moonsic.score_layout_to_score(sl)
  assert_eq(score.track_count(), 0)
}

///|
test "make_score_layout_invalid_ppq_negative_err" {
  let r = @moonsic.make_score_layout("Bad", -1, [])
  assert_true(r.is_err())
}

///|
test "make_part_empty_name_err" {
  let r = @moonsic.make_part("", [])
  assert_true(r.is_err())
}
