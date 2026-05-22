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
