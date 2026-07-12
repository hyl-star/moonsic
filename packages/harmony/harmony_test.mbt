// ============================================================
// v2 harmony 包测试
// ============================================================

// --- RomanNumeral ---

///|
test "roman_chord_quality_C_major_I" {
  let q = @harmony.roman_chord_quality(@scale.Major, @harmony.I)
  assert_eq(q.intervals().length(), 3)
}

///|
test "roman_chord_quality_C_major_VII_dim" {
  let q = @harmony.roman_chord_quality(@scale.Major, @harmony.VII)
  assert_eq(q.intervals()[2], 6) // dim triad has b5
}

// --- parse_roman_text ---

///|
test "parse_roman_I_V_vi_IV" {
  let rns = @harmony.parse_roman_text("I V vi IV")
  assert_eq(rns.length(), 4)
}

///|
test "parse_roman_ii_V_I" {
  let rns = @harmony.parse_roman_text("ii V I")
  assert_eq(rns.length(), 3)
}

///|
test "parse_roman_VII" {
  let rns = @harmony.parse_roman_text("VII")
  assert_eq(rns.length(), 1)
}

///|
test "parse_roman_IV_first" {
  let rns = @harmony.parse_roman_text("IV I")
  assert_eq(rns.length(), 2)
}

// --- roman_progression_checked ---

///|
test "roman_progression_C_I_V_vi_IV" {
  let k = @scale.key(@pitch.c(4), @scale.Major)
  let r = @harmony.roman_progression_checked(
    k,
    [@harmony.I, @harmony.V, @harmony.VI, @harmony.IV],
    4,
  )
  assert_true(r is Ok(_))
  let chords = r.unwrap()
  assert_eq(chords.length(), 4)
  // I = C major
  assert_eq(chords[0][0].to_midi(), 60)
  assert_eq(chords[0][1].to_midi(), 64)
  assert_eq(chords[0][2].to_midi(), 67)
  // V = G major
  assert_eq(chords[1][0].to_midi(), 67)
}

///|
test "roman_progression_Am_i_iv_V" {
  let k = @scale.key(@pitch.a(3), @scale.NaturalMinor)
  let r = @harmony.roman_progression_checked(
    k,
    [@harmony.I, @harmony.IV, @harmony.V],
    3,
  )
  assert_true(r is Ok(_))
  let chords = r.unwrap()
  assert_eq(chords.length(), 3)
  assert_eq(chords[0][0].to_midi(), 57) // A3
  assert_eq(chords[1][0].to_midi(), 62) // D4
  assert_eq(chords[2][0].to_midi(), 64) // E4 (major V)
}

///|
test "roman_progression_empty_err" {
  let k = @scale.key(@pitch.c(4), @scale.Major)
  let r = @harmony.roman_progression_checked(k, [], 4)
  assert_true(r is Err(_))
}

// --- roman_progression_text_checked ---

///|
test "roman_text_I_V_vi_IV" {
  let k = @scale.key(@pitch.c(4), @scale.Major)
  let r = @harmony.roman_progression_text_checked(k, "I V vi IV", 4)
  assert_true(r is Ok(_))
  let chords = r.unwrap()
  assert_eq(chords.length(), 4)
}

// --- sort_pitches ---

///|
test "sort_pitches_ascending" {
  let pitches = [@pitch.g(4), @pitch.c(4), @pitch.e(4)]
  let sorted = @harmony.sort_pitches(pitches)
  assert_eq(sorted[0].to_midi(), 60)
  assert_eq(sorted[1].to_midi(), 64)
  assert_eq(sorted[2].to_midi(), 67)
}

// --- chord_distance_pitches ---

///|
test "chord_distance_same" {
  let a = [@pitch.c(4), @pitch.e(4), @pitch.g(4)]
  assert_eq(@harmony.chord_distance_pitches(a, a), 0)
}

///|
test "chord_distance_up_fifth" {
  let a = [@pitch.c(4), @pitch.e(4), @pitch.g(4)]
  let b = [@pitch.g(4), @pitch.b(4), @pitch.d(5)]
  assert_true(@harmony.chord_distance_pitches(a, b) > 0)
}

// --- voice_lead_pitches ---

///|
test "voice_lead_I_V" {
  let k = @scale.key(@pitch.c(4), @scale.Major)
  let chords = @harmony.roman_progression_checked(
    k,
    [@harmony.I, @harmony.V],
    4,
  ).unwrap()
  let r = @harmony.voice_lead_pitches(chords)
  assert_true(r is Ok(_))
  assert_eq(r.unwrap().length(), 2)
}

///|
test "voice_lead_empty_err" {
  let r = @harmony.voice_lead_pitches([])
  assert_true(r is Err(_))
}

///|
test "voice_lead_reduces_distance" {
  let k = @scale.key(@pitch.c(4), @scale.Major)
  let chords = @harmony.roman_progression_checked(
    k,
    [@harmony.I, @harmony.V],
    4,
  ).unwrap()
  let before = @harmony.chord_distance_pitches(chords[0], chords[1])
  let after_vl = @harmony.voice_lead_pitches(chords).unwrap()
  let after = @harmony.chord_distance_pitches(after_vl[0], after_vl[1])
  assert_true(after <= before)
}

// --- HarmonyError ---

///|
test "harmony_error_to_string" {
  let e = @harmony.HarmonyError::InvalidRoman("test")
  assert_true(e.to_string().contains("无效罗马数字"))
}

///|
test "harmony_error_empty_progression" {
  let e = @harmony.HarmonyError::EmptyProgression("test")
  assert_true(e.to_string().contains("空进行"))
}
