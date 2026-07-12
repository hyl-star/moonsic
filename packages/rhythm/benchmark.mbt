// ============================================================
// v2 rhythm 包基础性能基准
// ============================================================

///|
test "bench_rhythm_template_1k" {
  for _i = 0; _i < 1000; _i = _i + 1 {
    let _ = rhythm_template(FourQuarters)
    let _ = rhythm_template(EighthFlow)
  }
}

///|
test "bench_repeat_pattern_500" {
  let p = rhythm_template(FourQuarters)
  for _i = 0; _i < 500; _i = _i + 1 {
    let _ = repeat_pattern_checked(p, 4)
  }
}

///|
test "bench_fit_pattern_500" {
  let p = repeat_pattern_checked(rhythm_template(FourQuarters), 2).unwrap()
  let ts = @time.time_signature(4, 4)
  for _i = 0; _i < 500; _i = _i + 1 {
    let _ = fit_pattern_to_bars_checked(p, ts, 2, Strict)
  }
}
