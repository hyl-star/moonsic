// ============================================================
// v2 chord 包测试
// ============================================================

// --- ChordQuality ---

///|
test "chord_quality_major_intervals" {
  let iv = @chord.MajorTriad.intervals()
  assert_eq(iv.length(), 3)
  assert_eq(iv[0], 0)
  assert_eq(iv[1], 4)
  assert_eq(iv[2], 7)
}

///|
test "chord_quality_dominant_7th" {
  let iv = @chord.DominantSeventh.intervals()
  assert_eq(iv.length(), 4)
  assert_eq(iv[3], 10)
}

///|
test "chord_quality_dim7" {
  let iv = @chord.Diminished7.intervals()
  assert_eq(iv.length(), 4)
  assert_eq(iv[3], 9)
}

// --- chord_pitches ---

///|
test "chord_pitches_C_major" {
  let pitches = @chord.chord_pitches(@pitch.c(4), @chord.MajorTriad)
  assert_eq(pitches.length(), 3)
  assert_eq(pitches[0].to_midi(), 60) // C4
  assert_eq(pitches[1].to_midi(), 64) // E4
  assert_eq(pitches[2].to_midi(), 67) // G4
}

///|
test "chord_pitches_A_minor" {
  let pitches = @chord.chord_pitches(@pitch.a(3), @chord.MinorTriad)
  assert_eq(pitches.length(), 3)
  assert_eq(pitches[0].to_midi(), 57) // A3
  assert_eq(pitches[1].to_midi(), 60) // C4
  assert_eq(pitches[2].to_midi(), 64) // E4
}

///|
test "chord_pitches_B_dim" {
  let pitches = @chord.chord_pitches(@pitch.b(3), @chord.DiminishedTriad)
  assert_eq(pitches.length(), 3)
  assert_eq(pitches[0].to_midi(), 59) // B3
  assert_eq(pitches[1].to_midi(), 62) // D4
  assert_eq(pitches[2].to_midi(), 65) // F4
}

///|
test "chord_pitches_C_aug" {
  let pitches = @chord.chord_pitches(@pitch.c(4), @chord.AugmentedTriad)
  assert_eq(pitches.length(), 3)
  assert_eq(pitches[2].to_midi(), 68) // G#4
}

///|
test "chord_pitches_G_dom7" {
  let pitches = @chord.chord_pitches(@pitch.g(3), @chord.DominantSeventh)
  assert_eq(pitches.length(), 4)
  assert_eq(pitches[0].to_midi(), 55) // G3
  assert_eq(pitches[1].to_midi(), 59) // B3
  assert_eq(pitches[2].to_midi(), 62) // D4
  assert_eq(pitches[3].to_midi(), 65) // F4
}

///|
test "chord_pitches_C_maj7" {
  let pitches = @chord.chord_pitches(@pitch.c(4), @chord.MajorSeventh)
  assert_eq(pitches.length(), 4)
  assert_eq(pitches[3].to_midi(), 71) // B4
}

///|
test "chord_pitches_A_min7" {
  let pitches = @chord.chord_pitches(@pitch.a(3), @chord.MinorSeventh)
  assert_eq(pitches.length(), 4)
  assert_eq(pitches[0].to_midi(), 57) // A3
  assert_eq(pitches[1].to_midi(), 60) // C4
  assert_eq(pitches[2].to_midi(), 64) // E4
  assert_eq(pitches[3].to_midi(), 67) // G4
}

///|
test "chord_pitches_F_sharp_root_spelling" {
  let pitches = @chord.chord_pitches(@pitch.fs(4), @chord.MajorTriad)
  assert_eq(pitches.length(), 3)
  assert_eq(pitches[0].to_midi(), 66) // F#4
}

///|
test "chord_pitches_Bb_root_spelling" {
  let pitches = @chord.chord_pitches(@pitch.bb(4), @chord.MajorTriad)
  assert_eq(pitches.length(), 3)
  assert_eq(pitches[0].to_midi(), 70) // Bb4
}

// --- chord_invert ---

///|
test "chord_invert_first" {
  let pitches = @chord.chord_pitches(@pitch.c(4), @chord.MajorTriad)
  let inv = @chord.chord_invert(pitches, 1).unwrap()
  assert_eq(inv.length(), 3)
  assert_eq(inv[0].to_midi(), 64) // E4
  assert_eq(inv[2].to_midi(), 72) // C5
}

///|
test "chord_invert_negative_err" {
  let pitches = @chord.chord_pitches(@pitch.c(4), @chord.MajorTriad)
  assert_true(@chord.chord_invert(pitches, -1) is Err(_))
}

///|
test "chord_invert_single_note_ok" {
  let pitches = [@pitch.c(4)]
  let inv = @chord.chord_invert(pitches, 5).unwrap()
  assert_eq(inv.length(), 1)
}

// --- parse_chord ---

///|
test "parse_chord_C_major" {
  let r = @chord.parse_chord("C")
  assert_true(r is Ok(_))
  let pitches = r.unwrap()
  assert_eq(pitches.length(), 3)
  assert_eq(pitches[0].to_midi(), 60)
}

///|
test "parse_chord_Cm" {
  let r = @chord.parse_chord("Cm")
  assert_true(r is Ok(_))
  let pitches = r.unwrap()
  assert_eq(pitches.length(), 3)
  assert_eq(pitches[0].to_midi(), 60)
  assert_eq(pitches[1].to_midi(), 63) // Eb4
}

///|
test "parse_chord_Cmaj7" {
  let r = @chord.parse_chord("Cmaj7")
  assert_true(r is Ok(_))
  let pitches = r.unwrap()
  assert_eq(pitches.length(), 4)
  assert_eq(pitches[3].to_midi(), 71) // B4
}

///|
test "parse_chord_Am7" {
  let r = @chord.parse_chord("Am7")
  assert_true(r is Ok(_))
  let pitches = r.unwrap()
  assert_eq(pitches.length(), 4)
  assert_eq(pitches[0].to_midi(), 69) // A4
  assert_eq(pitches[3].to_midi(), 79) // G5
}

///|
test "parse_chord_G7" {
  let r = @chord.parse_chord("G7")
  assert_true(r is Ok(_))
  let pitches = r.unwrap()
  assert_eq(pitches.length(), 4)
  assert_eq(pitches[3].to_midi(), 77) // F5
}

///|
test "parse_chord_F_sharp_dim" {
  let r = @chord.parse_chord("F#dim")
  assert_true(r is Ok(_))
  let pitches = r.unwrap()
  assert_eq(pitches.length(), 3)
  assert_eq(pitches[0].to_midi(), 66) // F#4
}

///|
test "parse_chord_Dm7" {
  let r = @chord.parse_chord("Dm7")
  assert_true(r is Ok(_))
  let pitches = r.unwrap()
  assert_eq(pitches.length(), 4)
}

///|
test "parse_chord_C_garbage_err" {
  let r = @chord.parse_chord("Cgarbage")
  assert_true(r is Err(_))
}

///|
test "parse_chord_H_err" {
  let r = @chord.parse_chord("H")
  assert_true(r is Err(_))
}

///|
test "parse_chord_empty_err" {
  let r = @chord.parse_chord("")
  assert_true(r is Err(_))
}

///|
test "parse_chord_Bb_major" {
  let r = @chord.parse_chord("Bb")
  assert_true(r is Ok(_))
  let pitches = r.unwrap()
  assert_eq(pitches[0].to_midi(), 70) // Bb4
}

// --- parse_chord_quality_checked ---

///|
test "parse_chord_quality_maj7" {
  let r = @chord.parse_chord_quality_checked("maj7")
  assert_true(r is Ok(_))
}

///|
test "parse_chord_quality_dim" {
  let r = @chord.parse_chord_quality_checked("dim")
  assert_true(r is Ok(_))
}

///|
test "parse_chord_quality_empty" {
  let r = @chord.parse_chord_quality_checked("")
  assert_true(r is Ok(_))
}

///|
test "parse_chord_quality_garbage_err" {
  let r = @chord.parse_chord_quality_checked("xyz")
  assert_true(r is Err(_))
}

// --- chord_pitch_classes ---

///|
test "chord_pitch_classes_C_major" {
  let classes = @chord.chord_pitch_classes(@pitch.c(4), @chord.MajorTriad)
  assert_eq(classes.length(), 3)
}

// --- ChordError ---

///|
test "chord_error_to_string" {
  let e = @chord.ChordError::InvalidChord("test")
  assert_true(e.to_string().contains("无效和弦"))
}

///|
test "chord_error_empty_chord" {
  let e = @chord.ChordError::EmptyChord("test")
  assert_true(e.to_string().contains("空和弦"))
}
