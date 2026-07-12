// ============================================================
// v2 time 包测试
// ============================================================

// --- TimeError ---

///|
test "time_error_to_string" {
  let e = TimeError::InvalidRational("test")
  assert_true(e.to_string().contains("无效有理数"))
}

///|
test "time_error_invalid_tick" {
  let e = TimeError::InvalidTick("test")
  assert_true(e.to_string().contains("无效 tick"))
}

// --- TimeSignature ---

///|
test "time_sig_4_4" {
  let ts = time_signature(4, 4)
  assert_eq(ts.numerator, 4)
  assert_eq(ts.denominator, 4)
  assert_eq(ts.to_string(), "4/4")
}

///|
test "time_sig_measure_beats" {
  let ts = time_signature(4, 4)
  assert_true(ts.measure_beats() > 3.9 && ts.measure_beats() < 4.1)
}

///|
test "is_valid_time_sig_4_4" {
  assert_true(is_valid_time_signature(4, 4))
}

///|
test "is_valid_time_sig_0_4" {
  assert_false(is_valid_time_signature(0, 4))
}

///|
test "is_valid_time_sig_4_3" {
  assert_false(is_valid_time_signature(4, 3))
}

// --- Rational ---

///|
test "rational_1_2" {
  let r = rational(1, 2).unwrap()
  assert_eq(r.numerator, 1)
  assert_eq(r.denominator, 2)
}

///|
test "rational_reduce" {
  let r = rational(2, 4).unwrap()
  assert_eq(r.numerator, 1)
  assert_eq(r.denominator, 2)
}

///|
test "rational_zero_den_err" {
  assert_true(rational(1, 0) is Err(_))
}

///|
test "rational_add" {
  let a = rational(1, 3).unwrap()
  let b = rational(1, 6).unwrap()
  let r = rational_add(a, b)
  assert_eq(r.numerator, 1)
  assert_eq(r.denominator, 2)
}

///|
test "rational_mul" {
  let a = rational(2, 3).unwrap()
  let b = rational(3, 4).unwrap()
  let r = rational_mul(a, b)
  assert_eq(r.numerator, 1)
  assert_eq(r.denominator, 2)
}

///|
test "rational_to_double" {
  let r = rational(1, 2).unwrap()
  assert_true(rational_to_double(r) > 0.49 && rational_to_double(r) < 0.51)
}

// --- RhythmDuration ---

///|
test "quarter_ticks_480" {
  let dur : RhythmDuration = { unit: DurQuarter, dots: 0, tuplet: None }
  assert_eq(rhythm_duration_to_ticks(dur, 480).unwrap(), 480)
}

///|
test "half_ticks_480" {
  let dur : RhythmDuration = { unit: DurHalf, dots: 0, tuplet: None }
  assert_eq(rhythm_duration_to_ticks(dur, 480).unwrap(), 960)
}

///|
test "dotted_quarter_ticks" {
  let dur : RhythmDuration = { unit: DurQuarter, dots: 1, tuplet: None }
  assert_eq(rhythm_duration_to_ticks(dur, 480).unwrap(), 720)
}

///|
test "bar_length_4_4" {
  let ts = time_signature(4, 4)
  assert_eq(bar_length_ticks(ts, 480).unwrap(), 1920)
}

///|
test "bar_length_3_4" {
  let ts = time_signature(3, 4)
  assert_eq(bar_length_ticks(ts, 480).unwrap(), 1440)
}

///|
test "bpm_to_microseconds_120" {
  let us = bpm_to_microseconds_per_quarter(120.0).unwrap()
  assert_eq(us, 500000)
}

///|
test "ticks_to_seconds_quarter_120bpm" {
  let sec = ticks_to_seconds(480, 120.0, 480).unwrap()
  assert_true(sec > 0.49 && sec < 0.51)
}

///|
test "seconds_to_ticks_checked_ok" {
  let r = seconds_to_ticks_checked(0.5, 120.0, 480)
  assert_true(r is Ok(_))
}

///|
test "seconds_to_ticks_checked_negative_err" {
  let r = seconds_to_ticks_checked(-0.5, 120.0, 480)
  assert_true(r is Err(_))
}

// --- Position ---

///|
test "position_to_ticks_bar_1" {
  let pos : BarPosition = {
    bar: 1,
    beat: rational(0, 1).unwrap(),
    offset: rational(0, 1).unwrap(),
  }
  let ts = time_signature(4, 4)
  assert_eq(position_to_ticks(pos, ts, 480).unwrap(), 1920)
}

///|
test "ticks_to_position_1920" {
  let ts = time_signature(4, 4)
  let pos = ticks_to_position(1920, ts, 480).unwrap()
  assert_eq(pos.bar, 1)
}

// --- TimeMap ---

///|
test "make_time_map_ok" {
  let ts = time_signature(4, 4)
  let tm = make_time_map(480, ts, 120.0)
  assert_true(tm is Ok(_))
}

///|
test "tempo_at_tick_default" {
  let ts = time_signature(4, 4)
  let tm = make_time_map(480, ts, 120.0).unwrap()
  let bpm = tempo_at_tick(tm, 0)
  assert_true(bpm > 119.0 && bpm < 121.0)
}

///|
test "make_time_map_bad_ppq_err" {
  let ts = time_signature(4, 4)
  assert_true(make_time_map(0, ts, 120.0) is Err(_))
}

// --- Parse ---

///|
test "parse_time_sig_4_4" {
  let ts = parse_time_sig("4/4").unwrap()
  assert_eq(ts.numerator, 4)
  assert_eq(ts.denominator, 4)
}

///|
test "parse_time_sig_6_8" {
  let ts = parse_time_sig("6/8").unwrap()
  assert_eq(ts.numerator, 6)
  assert_eq(ts.denominator, 8)
}

///|
test "parse_time_sig_invalid_err" {
  assert_true(parse_time_sig("x/y") is Err(_))
}

///|
test "parse_dur_unit_quarter" {
  let d = parse_dur_unit("q").unwrap()
  assert_eq(d.dots, 0)
}

///|
test "parse_dur_unit_dotted" {
  let d = parse_dur_unit("q..").unwrap()
  assert_eq(d.dots, 2)
}

///|
test "parse_dur_unit_invalid_err" {
  assert_true(parse_dur_unit("x") is Err(_))
}

///|
test "parse_tempo_120" {
  let bpm = parse_tempo("120").unwrap()
  assert_true(bpm > 119.0 && bpm < 121.0)
}

///|
test "parse_tempo_120bpm" {
  let bpm = parse_tempo("120bpm").unwrap()
  assert_true(bpm > 119.0 && bpm < 121.0)
}

///|
test "parse_tempo_zero_err" {
  assert_true(parse_tempo("0") is Err(_))
}

// --- FFI ---

///|
test "ffi_duration_ticks_json_quarter" {
  let result = ffi_duration_ticks_json("{\"duration\":\"q\",\"ppq\":480}")
  assert_true(result.contains("ok\":true"))
  assert_true(result.contains("480"))
}

///|
test "ffi_ticks_to_seconds_json" {
  let result = ffi_ticks_to_seconds_json(
    "{\"ticks\":480,\"bpm\":120.0,\"ppq\":480}",
  )
  assert_true(result.contains("ok\":true"))
}

///|
test "ffi_bar_length_json" {
  let result = ffi_bar_length_json("{\"sig\":\"4/4\",\"ppq\":480}")
  assert_true(result.contains("1920"))
}

///|
test "ffi_parse_time_sig" {
  let result = ffi_parse_time_sig("3/4")
  assert_true(result.contains("num\":3"))
  assert_true(result.contains("den\":4"))
}
