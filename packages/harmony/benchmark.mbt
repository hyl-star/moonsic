// ============================================================
// v2 harmony 包基础性能基准
// ============================================================

///|
test "bench_roman_progression_500" {
  let k = @scale.key(@pitch.c(4), @scale.Major)
  for _i = 0; _i < 500; _i = _i + 1 {
    let _ = roman_progression_checked(k, [I, V, VI, IV], 4)
  }
}

///|
test "bench_parse_roman_text_1k" {
  for _i = 0; _i < 1000; _i = _i + 1 {
    let _ = parse_roman_text("I V vi IV")
  }
}

///|
test "bench_voice_lead_500" {
  let k = @scale.key(@pitch.c(4), @scale.Major)
  let chords = roman_progression_checked(k, [I, V, VI, IV], 4).unwrap()
  for _i = 0; _i < 500; _i = _i + 1 {
    let _ = voice_lead_pitches(chords)
  }
}
