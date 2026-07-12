// ============================================================
// v2 pitch 包基础性能基准
// ============================================================

///|
test "bench_pitch_construct_10k" {
  for _i = 0; _i < 10000; _i = _i + 1 {
    let _ = c(4)
    let _ = d(4)
    let _ = e(4)
    let _ = f(4)
  }
}

///|
test "bench_to_midi_10k" {
  for _i = 0; _i < 10000; _i = _i + 1 {
    let _ = c(4).to_midi()
    let _ = fs(4).to_midi()
    let _ = bb(3).to_midi()
  }
}

///|
test "bench_parse_pitch_1k" {
  for _i = 0; _i < 1000; _i = _i + 1 {
    let _ = parse_pitch("C4")
    let _ = parse_pitch("F#3")
    let _ = parse_pitch("Bb5")
  }
}
