// ============================================================
// v2 time 包基础性能基准
// ============================================================

///|
test "bench_rational_ops_5k" {
  for _i = 0; _i < 5000; _i = _i + 1 {
    let a = rational(1, 3).unwrap()
    let b = rational(1, 6).unwrap()
    let _ = rational_add(a, b)
    let _ = rational_mul(a, b)
  }
}

///|
test "bench_ticks_to_seconds_1k" {
  for _i = 0; _i < 1000; _i = _i + 1 {
    let _ = ticks_to_seconds(480, 120.0, 480)
    let _ = ticks_to_seconds(960, 140.0, 960)
  }
}

///|
test "bench_parse_time_sig_1k" {
  for _i = 0; _i < 1000; _i = _i + 1 {
    let _ = parse_time_sig("4/4")
    let _ = parse_time_sig("6/8")
  }
}
