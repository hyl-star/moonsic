// ============================================================
// v2 scale 包测试
// ============================================================

// --- ScaleKind ---

///|
test "scale_kind_major_intervals" {
  let iv = @scale.Major.intervals()
  assert_eq(iv.length(), 7)
  assert_eq(iv[0], 0)
  assert_eq(iv[1], 2)
}

///|
test "scale_kind_minor_pentatonic" {
  let iv = @scale.MinorPentatonic.intervals()
  assert_eq(iv.length(), 5)
}

// --- build_scale ---

///|
test "build_scale_C_major_count" {
  let s = @scale.build_scale(@pitch.C, @scale.Major)
  assert_eq(s.tones.length(), 7)
  assert_eq(s.spelled_tones.length(), 7)
}

///|
test "build_scale_C_major_midi" {
  let s = @scale.build_scale(@pitch.C, @scale.Major)
  assert_eq(s.spelled_tones[0].to_midi(), 60) // C4
  assert_eq(s.spelled_tones[2].to_midi(), 64) // E4
  assert_eq(s.spelled_tones[4].to_midi(), 67) // G4
}

///|
test "build_scale_A_minor_spelled" {
  let s = @scale.build_scale_spelled(
    @pitch.A,
    @pitch.Natural,
    @scale.NaturalMinor,
  )
  assert_eq(s.spelled_tones.length(), 7)
  assert_eq(s.spelled_tones[0].to_midi(), 69) // A4
  assert_eq(s.spelled_tones[1].to_midi(), 71) // B4
  assert_eq(s.spelled_tones[2].to_midi(), 72) // C5
}

///|
test "build_scale_D_dorian_count" {
  let s = @scale.build_scale(@pitch.D, @scale.Dorian)
  assert_eq(s.tones.length(), 7)
}

// --- parse_scale ---

///|
test "parse_scale_C_major" {
  let r = @scale.parse_scale("C major")
  assert_true(r is Ok(_))
  let s = r.unwrap()
  assert_eq(s.spelled_tones.length(), 7)
  assert_eq(s.spelled_tones[0].to_midi(), 60)
}

///|
test "parse_scale_F_sharp_major" {
  let r = @scale.parse_scale("F# major")
  assert_true(r is Ok(_))
  let s = r.unwrap()
  assert_eq(s.spelled_tones.length(), 7)
}

///|
test "parse_scale_Bb_minor" {
  let r = @scale.parse_scale("Bb minor")
  assert_true(r is Ok(_))
  let s = r.unwrap()
  assert_eq(s.spelled_tones.length(), 7)
}

///|
test "parse_scale_D_dorian" {
  let r = @scale.parse_scale("D dorian")
  assert_true(r is Ok(_))
}

///|
test "parse_scale_empty_err" {
  let r = @scale.parse_scale("")
  assert_true(r is Err(_))
}

///|
test "parse_scale_invalid_root_err" {
  let r = @scale.parse_scale("X lydian")
  assert_true(r is Err(_))
}

///|
test "parse_scale_trailing_err" {
  let r = @scale.parse_scale("C major xyz")
  assert_true(r is Err(_))
}

// --- Key ---

///|
test "key_C_major_degree_1" {
  let k = @scale.key(@pitch.c(4), @scale.Major)
  let r = k.key_degree_checked(1, 4)
  assert_true(r is Ok(_))
  assert_eq(r.unwrap().to_midi(), 60)
}

///|
test "key_C_major_degree_5" {
  let k = @scale.key(@pitch.c(4), @scale.Major)
  let r = k.key_degree_checked(5, 4)
  assert_true(r is Ok(_))
  assert_eq(r.unwrap().to_midi(), 67)
}

///|
test "key_G_major_degree_7" {
  let k = @scale.key(@pitch.g(4), @scale.Major)
  let r = k.key_degree_checked(7, 4)
  assert_true(r is Ok(_))
  assert_eq(r.unwrap().to_midi(), 78) // F#5, letter wraps B->C
}

///|
test "key_F_major_degree_4" {
  let k = @scale.key(@pitch.f(4), @scale.Major)
  let r = k.key_degree_checked(4, 4)
  assert_true(r is Ok(_))
  assert_eq(r.unwrap().to_midi(), 70) // Bb4
}

///|
test "key_degree_zero_err" {
  let k = @scale.key(@pitch.c(4), @scale.Major)
  let r = k.key_degree_checked(0, 4)
  assert_true(r is Err(_))
}

///|
test "key_degree_negative_err" {
  let k = @scale.key(@pitch.c(4), @scale.Major)
  let r = k.key_degree_checked(-1, 4)
  assert_true(r is Err(_))
}

///|
test "key_scale_C_major_one_octave" {
  let k = @scale.key(@pitch.c(4), @scale.Major)
  let s = k.scale(4, 1)
  assert_eq(s.length(), 7)
  assert_eq(s[0].to_midi(), 60)
}

///|
test "Key_tonic_pitch" {
  let k = @scale.key(@pitch.a(3), @scale.NaturalMinor)
  assert_eq(k.tonic_pitch().to_midi(), 57)
}

///|
test "Key_scale_kind" {
  let k = @scale.key(@pitch.c(4), @scale.Dorian)
  assert_eq(k.scale_kind().intervals().length(), 7)
}

// --- ScaleError ---

///|
test "scale_error_to_string" {
  let e = @scale.ScaleError::InvalidScale("test")
  assert_true(e.to_string().contains("无效音阶"))
}

///|
test "scale_error_invalid_degree" {
  let e = @scale.ScaleError::InvalidDegree("test")
  assert_true(e.to_string().contains("无效音级"))
}
