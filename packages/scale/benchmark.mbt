// ============================================================
// v2 scale 包基础性能基准
// ============================================================

///|
test "bench_build_scale_1k" {
  for _i = 0; _i < 1000; _i = _i + 1 {
    let _ = build_scale(@pitch.C, Major)
    let _ = build_scale(@pitch.A, NaturalMinor)
  }
}

///|
test "bench_parse_scale_100" {
  for _i = 0; _i < 100; _i = _i + 1 {
    let _ = parse_scale("C major")
    let _ = parse_scale("F# major")
  }
}

///|
test "bench_key_degree_1k" {
  let k = key(@pitch.c(4), Major)
  for _i = 0; _i < 1000; _i = _i + 1 {
    let _ = k.key_degree_checked(1, 4)
    let _ = k.key_degree_checked(5, 4)
  }
}
