// ============================================================
// v2 rhythm 包测试
// ============================================================

// --- RhythmTemplate ---

///|
test "rhythm_template_four_quarters" {
  let p = @rhythm.rhythm_template(@rhythm.FourQuarters)
  assert_eq(p.cells.length(), 4)
  assert_true(p.total_beats > 3.9 && p.total_beats < 4.1)
}

///|
test "rhythm_template_waltz" {
  let p = @rhythm.rhythm_template(@rhythm.Waltz)
  assert_eq(p.cells.length(), 3)
}

///|
test "rhythm_template_rest_lead" {
  let p = @rhythm.rhythm_template(@rhythm.RestLead)
  assert_eq(p.cells.length(), 4)
  assert_true(p.cells[0].is_rest)
}

// --- rhythm_pattern_checked ---

///|
test "rhythm_pattern_checked_ok" {
  let d = @time.rhythm_duration(@time.DurQuarter, 0, None)
  let cells = [
    @rhythm.rhythm_cell(d, false, @rhythm.NoAccent, false),
    @rhythm.rhythm_cell(d, false, @rhythm.NoAccent, false),
  ]
  let r = @rhythm.rhythm_pattern_checked(cells)
  assert_true(r is Ok(_))
}

///|
test "rhythm_pattern_checked_empty_err" {
  let r = @rhythm.rhythm_pattern_checked([])
  assert_true(r is Err(_))
}

// --- repeat_pattern_checked ---

///|
test "repeat_pattern_checked_x3" {
  let p = @rhythm.rhythm_template(@rhythm.FourQuarters)
  let r = @rhythm.repeat_pattern_checked(p, 3)
  assert_true(r is Ok(_))
  let phrase = r.unwrap()
  assert_eq(phrase.cells.length(), 12)
}

///|
test "repeat_pattern_checked_zero_err" {
  let p = @rhythm.rhythm_template(@rhythm.FourQuarters)
  assert_true(@rhythm.repeat_pattern_checked(p, 0) is Err(_))
}

// --- join_patterns_checked ---

///|
test "join_patterns_sequential" {
  let a = @rhythm.repeat_pattern_checked(
    @rhythm.rhythm_template(@rhythm.FourQuarters),
    1,
  ).unwrap()
  let b = @rhythm.repeat_pattern_checked(
    @rhythm.rhythm_template(@rhythm.Waltz),
    1,
  ).unwrap()
  let r = @rhythm.join_patterns_checked([a, b], @rhythm.Sequential)
  assert_true(r is Ok(_))
  assert_eq(r.unwrap().cells.length(), 7) // 4 + 3
}

///|
test "join_patterns_empty_err" {
  assert_true(@rhythm.join_patterns_checked([], @rhythm.Sequential) is Err(_))
}

// --- fit_pattern_to_bars ---

///|
test "fit_pattern_strict_exact" {
  let p = @rhythm.repeat_pattern_checked(
    @rhythm.rhythm_template(@rhythm.FourQuarters),
    1,
  ).unwrap()
  let ts = @time.time_signature(4, 4)
  let r = @rhythm.fit_pattern_to_bars_checked(p, ts, 1, @rhythm.Strict)
  assert_true(r is Ok(_))
}

///|
test "fit_pattern_strict_mismatch_err" {
  let p = @rhythm.repeat_pattern_checked(
    @rhythm.rhythm_template(@rhythm.Waltz),
    1,
  ).unwrap()
  let ts = @time.time_signature(4, 4)
  let r = @rhythm.fit_pattern_to_bars_checked(p, ts, 1, @rhythm.Strict)
  assert_true(r is Err(_))
}

///|
test "fit_pattern_pad_rest" {
  let p = @rhythm.repeat_pattern_checked(
    @rhythm.rhythm_template(@rhythm.Waltz),
    1,
  ).unwrap()
  let ts = @time.time_signature(4, 4)
  let r = @rhythm.fit_pattern_to_bars_checked(p, ts, 1, @rhythm.PadRest)
  assert_true(r is Ok(_))
  assert_true(r.unwrap().cells.length() >= 3) // at least original 3
}

///|
test "fit_pattern_truncate" {
  let p = @rhythm.repeat_pattern_checked(
    @rhythm.rhythm_template(@rhythm.FourQuarters),
    2,
  ).unwrap()
  let ts = @time.time_signature(4, 4)
  let r = @rhythm.fit_pattern_to_bars_checked(p, ts, 1, @rhythm.Truncate)
  assert_true(r is Ok(_))
  // Truncated to ~1 bar
  let result = r.unwrap()
  assert_true(result.total_beats <= 4.1)
}

///|
test "fit_pattern_repeat_to_fit" {
  let p = @rhythm.repeat_pattern_checked(
    @rhythm.rhythm_template(@rhythm.Waltz),
    1,
  ).unwrap()
  let ts = @time.time_signature(4, 4)
  let r = @rhythm.fit_pattern_to_bars_checked(p, ts, 2, @rhythm.RepeatToFit)
  assert_true(r is Ok(_))
}

// --- AccentStrength ---

///|
test "accent_marcato_multiplier" {
  assert_true(@rhythm.Marcato.velocity_multiplier() > 1.2)
}

// --- RhythmError ---

///|
test "rhythm_error_to_string" {
  let e = @rhythm.RhythmError::EmptyRhythmPattern("test")
  assert_true(e.to_string().contains("空节奏模板"))
}
