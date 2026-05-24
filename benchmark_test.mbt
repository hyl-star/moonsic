///|
test "bench_duration_to_ticks_smoke" {
  let result = @moonsic.bench_duration_to_ticks(10000)
  assert_true(result.length() > 0)
  assert_true(result.contains("bench_duration_to_ticks"))
}

///|
test "bench_score_flatten_smoke" {
  let result = @moonsic.bench_score_flatten(500)
  assert_true(result.length() > 0)
  assert_true(result.contains("bench_score_flatten"))
}

///|
test "bench_midi_export_smoke" {
  let result = @moonsic.bench_midi_export(100)
  assert_true(result.length() > 0)
  assert_true(result.contains("bench_midi_export"))
}

///|
test "bench_wav_render_smoke" {
  let result = @moonsic.bench_wav_render(5)
  assert_true(result.length() > 0)
  assert_true(result.contains("bench_wav_render"))
}

///|
test "bench_duration_to_ticks_zero" {
  let result = @moonsic.bench_duration_to_ticks(0)
  assert_true(result.length() > 0)
  assert_true(result.contains("completed 0"))
}

///|
test "bench_score_flatten_zero" {
  let result = @moonsic.bench_score_flatten(0)
  assert_true(result.length() > 0)
  assert_true(result.contains("completed 0"))
}

///|
test "bench_results_contains_iterations" {
  let r1 = @moonsic.bench_midi_export(10)
  let r2 = @moonsic.bench_wav_render(3)
  assert_true(r1.contains("completed 10"))
  assert_true(r2.contains("completed 3"))
}

///|
test "bench_all_four_benchmarks_produce_output" {
  let r1 = @moonsic.bench_duration_to_ticks(1)
  let r2 = @moonsic.bench_score_flatten(1)
  let r3 = @moonsic.bench_midi_export(1)
  let r4 = @moonsic.bench_wav_render(1)
  assert_true(r1.length() > 0)
  assert_true(r2.length() > 0)
  assert_true(r3.length() > 0)
  assert_true(r4.length() > 0)
}
