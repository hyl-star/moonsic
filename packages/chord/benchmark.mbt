// ============================================================
// v2 chord 包基础性能基准
// ============================================================

///|
test "bench_chord_pitches_1k" {
  for _i = 0; _i < 1000; _i = _i + 1 {
    let _ = chord_pitches(@pitch.c(4), MajorTriad)
    let _ = chord_pitches(@pitch.a(3), MinorSeventh)
  }
}

///|
test "bench_parse_chord_100" {
  for _i = 0; _i < 100; _i = _i + 1 {
    let _ = parse_chord("Cmaj7")
    let _ = parse_chord("Am7")
    let _ = parse_chord("G7")
  }
}
