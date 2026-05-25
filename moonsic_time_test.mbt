///|
test "rational_create_ok" {
  let r = @moonsic.rational(1, 2)
  assert_true(r is Ok(_))
  let v = r.unwrap()
  assert_eq(v.numerator, 1)
  assert_eq(v.denominator, 2)
}

///|
test "rational_create_err_zero_denominator" {
  let r = @moonsic.rational(1, 0)
  assert_true(r is Err(_))
}

///|
test "rational_create_err_negative_denominator" {
  let r = @moonsic.rational(1, -1)
  assert_true(r is Err(_))
}

///|
test "rational_auto_reduce" {
  // 2/4 → 1/2
  let r = @moonsic.rational(2, 4).unwrap()
  assert_eq(r.numerator, 1)
  assert_eq(r.denominator, 2)
}

///|
test "rational_auto_reduce_negative" {
  // -2/4 → -1/2
  let r = @moonsic.rational(-2, 4).unwrap()
  assert_eq(r.numerator, -1)
  assert_eq(r.denominator, 2)
}

///|
test "rational_add" {
  // 1/2 + 1/4 = 3/4
  let a = @moonsic.rational(1, 2).unwrap()
  let b = @moonsic.rational(1, 4).unwrap()
  let c = @moonsic.rational_add(a, b)
  assert_eq(c.numerator, 3)
  assert_eq(c.denominator, 4)
}

///|
test "rational_sub" {
  // 3/4 - 1/4 = 1/2
  let a = @moonsic.rational(3, 4).unwrap()
  let b = @moonsic.rational(1, 4).unwrap()
  let c = @moonsic.rational_sub(a, b)
  assert_eq(c.numerator, 1)
  assert_eq(c.denominator, 2)
}

///|
test "rational_mul" {
  // 1/2 * 2/3 = 1/3
  let a = @moonsic.rational(1, 2).unwrap()
  let b = @moonsic.rational(2, 3).unwrap()
  let c = @moonsic.rational_mul(a, b)
  assert_eq(c.numerator, 1)
  assert_eq(c.denominator, 3)
}

///|
test "rational_div" {
  // (1/2) / (1/4) = 2/1
  let a = @moonsic.rational(1, 2).unwrap()
  let b = @moonsic.rational(1, 4).unwrap()
  let c = @moonsic.rational_div(a, b).unwrap()
  assert_eq(c.numerator, 2)
  assert_eq(c.denominator, 1)
}

///|
test "rational_div_by_zero_err" {
  let a = @moonsic.rational(1, 2).unwrap()
  let b = @moonsic.rational(0, 1).unwrap()
  let c = @moonsic.rational_div(a, b)
  assert_true(c is Err(_))
}

///|
test "rational_is_integer_true" {
  // 4/2 = 2
  let r = @moonsic.rational(4, 2).unwrap()
  assert_true(@moonsic.rational_is_integer(r))
}

///|
test "rational_is_integer_false" {
  // 1/2
  let r = @moonsic.rational(1, 2).unwrap()
  assert_false(@moonsic.rational_is_integer(r))
}

///|
test "rational_to_int_ok" {
  let r = @moonsic.rational(4, 2).unwrap()
  let i = @moonsic.rational_to_int(r).unwrap()
  assert_eq(i, 2)
}

///|
test "rational_to_int_err_non_integer" {
  let r = @moonsic.rational(1, 2).unwrap()
  let i = @moonsic.rational_to_int(r)
  assert_true(i is Err(_))
}

///|
test "rational_to_double" {
  // 1/2 = 0.5
  let r = @moonsic.rational(1, 2).unwrap()
  let d = @moonsic.rational_to_double(r)
  assert_true(d > 0.49 && d < 0.51)
}

///|
test "rational_to_double_negative" {
  // -3/4 = -0.75
  let r = @moonsic.rational(-3, 4).unwrap()
  let d = @moonsic.rational_to_double(r)
  assert_true(d < -0.74 && d > -0.76)
}

///|
test "rational_to_string" {
  let r = @moonsic.rational(3, 4).unwrap()
  assert_eq(r.to_string(), "3/4")
}

// --- 节奏时值换算 ---

///|
test "rhythm_duration_quarter_to_ticks" {
  // Quarter at ppq=480 → 480 ticks
  let d = @moonsic.RhythmDuration::{
    unit: @moonsic.DurQuarter,
    dots: 0,
    tuplet: None,
  }
  let ticks = @moonsic.rhythm_duration_to_ticks(d, 480).unwrap()
  assert_eq(ticks, 480)
}

///|
test "rhythm_duration_dotted_eighth_to_ticks" {
  // dotted Eighth at ppq=480 → 360 ticks
  let d = @moonsic.RhythmDuration::{
    unit: @moonsic.DurEighth,
    dots: 1,
    tuplet: None,
  }
  let ticks = @moonsic.rhythm_duration_to_ticks(d, 480).unwrap()
  assert_eq(ticks, 360)
}

///|
test "rhythm_duration_triplet_eighth_to_ticks" {
  // triplet Eighth (3:2 8) at ppq=480 → 160 ticks
  let d = @moonsic.RhythmDuration::{
    unit: @moonsic.DurEighth,
    dots: 0,
    tuplet: Some(@moonsic.TupletRatio::{ actual: 3, normal: 2 }),
  }
  let ticks = @moonsic.rhythm_duration_to_ticks(d, 480).unwrap()
  assert_eq(ticks, 160)
}

///|
test "rhythm_duration_to_ticks_invalid_ppq" {
  let d = @moonsic.RhythmDuration::{
    unit: @moonsic.DurQuarter,
    dots: 0,
    tuplet: None,
  }
  let r = @moonsic.rhythm_duration_to_ticks(d, 0)
  assert_true(r is Err(_))
}

///|
test "rhythm_duration_whole_to_ticks" {
  // Whole at ppq=480 → 1920 ticks
  let d = @moonsic.RhythmDuration::{
    unit: @moonsic.DurWhole,
    dots: 0,
    tuplet: None,
  }
  let ticks = @moonsic.rhythm_duration_to_ticks(d, 480).unwrap()
  assert_eq(ticks, 1920)
}

///|
test "rhythm_duration_half_to_ticks" {
  // Half at ppq=480 → 960 ticks
  let d = @moonsic.RhythmDuration::{
    unit: @moonsic.DurHalf,
    dots: 0,
    tuplet: None,
  }
  let ticks = @moonsic.rhythm_duration_to_ticks(d, 480).unwrap()
  assert_eq(ticks, 960)
}

///|
test "rhythm_duration_sixteenth_to_ticks" {
  // Sixteenth at ppq=480 → 120 ticks
  let d = @moonsic.RhythmDuration::{
    unit: @moonsic.DurSixteenth,
    dots: 0,
    tuplet: None,
  }
  let ticks = @moonsic.rhythm_duration_to_ticks(d, 480).unwrap()
  assert_eq(ticks, 120)
}

///|
test "rhythm_duration_thirtysecond_to_ticks" {
  // ThirtySecond at ppq=480 → 60 ticks
  let d = @moonsic.RhythmDuration::{
    unit: @moonsic.ThirtySecond,
    dots: 0,
    tuplet: None,
  }
  let ticks = @moonsic.rhythm_duration_to_ticks(d, 480).unwrap()
  assert_eq(ticks, 60)
}

///|
test "rhythm_duration_double_dotted_to_ticks" {
  // double-dotted Quarter at ppq=480 → 480 * 7/4 = 840 ticks
  let d = @moonsic.RhythmDuration::{
    unit: @moonsic.DurQuarter,
    dots: 2,
    tuplet: None,
  }
  let ticks = @moonsic.rhythm_duration_to_ticks(d, 480).unwrap()
  assert_eq(ticks, 840)
}

// --- 小节长度 ---

///|
test "bar_length_4_4" {
  // 4/4 bar length → 1920 ticks at ppq=480
  let sig = @moonsic.time_signature(4, 4)
  let ticks = @moonsic.bar_length_ticks(sig, 480).unwrap()
  assert_eq(ticks, 1920)
}

///|
test "bar_length_6_8" {
  // 6/8 bar length → 1440 ticks at ppq=480
  let sig = @moonsic.time_signature(6, 8)
  let ticks = @moonsic.bar_length_ticks(sig, 480).unwrap()
  assert_eq(ticks, 1440)
}

///|
test "bar_length_3_4" {
  // 3/4 bar length → 1440 ticks at ppq=480
  let sig = @moonsic.time_signature(3, 4)
  let ticks = @moonsic.bar_length_ticks(sig, 480).unwrap()
  assert_eq(ticks, 1440)
}

///|
test "bar_length_invalid_ppq" {
  let sig = @moonsic.time_signature(4, 4)
  let r = @moonsic.bar_length_ticks(sig, 0)
  assert_true(r is Err(_))
}

///|
test "bar_length_invalid_time_sig" {
  // 5/3 is invalid (denominator 3 not a power of two)
  let r = @moonsic.parse_time_sig("5/3")
  assert_true(r is Err(_))
}

// --- BPM/Tick/秒 换算 ---

///|
test "bpm_to_microseconds_per_quarter_120" {
  // 120bpm → 500000 microseconds/quarter
  let us = @moonsic.bpm_to_microseconds_per_quarter(120.0).unwrap()
  assert_eq(us, 500000)
}

///|
test "bpm_to_microseconds_per_quarter_60" {
  // 60bpm → 1000000 microseconds/quarter
  let us = @moonsic.bpm_to_microseconds_per_quarter(60.0).unwrap()
  assert_eq(us, 1000000)
}

///|
test "bpm_to_microseconds_per_quarter_invalid" {
  // BPM <= 0
  let r = @moonsic.bpm_to_microseconds_per_quarter(0.0)
  assert_true(r is Err(_))
  let r2 = @moonsic.bpm_to_microseconds_per_quarter(-1.0)
  assert_true(r2 is Err(_))
}

///|
test "ticks_to_seconds_120bpm" {
  // 120bpm 480 ticks → 0.5s
  let sec = @moonsic.ticks_to_seconds(480, 120.0, 480).unwrap()
  assert_true(sec > 0.49 && sec < 0.51)
}

///|
test "ticks_to_seconds_60bpm" {
  // 60bpm 480 ticks → 1.0s
  let sec = @moonsic.ticks_to_seconds(480, 60.0, 480).unwrap()
  assert_true(sec > 0.99 && sec < 1.01)
}

///|
test "ticks_to_seconds_invalid_ppq" {
  let r = @moonsic.ticks_to_seconds(480, 120.0, 0)
  assert_true(r is Err(_))
}

///|
test "ticks_to_seconds_invalid_bpm" {
  let r = @moonsic.ticks_to_seconds(480, 0.0, 480)
  assert_true(r is Err(_))
}

///|
test "seconds_to_ticks_120bpm" {
  // 0.5s at 120bpm ppq=480 → 480 ticks
  let ticks = @moonsic.seconds_to_ticks(0.5, 120.0, 480)
  assert_eq(ticks, 480)
}

///|
test "seconds_to_ticks_60bpm" {
  // 1.0s at 60bpm ppq=480 → 480 ticks
  let ticks = @moonsic.seconds_to_ticks(1.0, 60.0, 480)
  assert_eq(ticks, 480)
}

///|
test "ticks_to_quarter_beats_480_ppq" {
  // 480 ticks / 480 ppq = 1 quarter beat
  let r = @moonsic.ticks_to_quarter_beats(480, 480)
  assert_eq(r.numerator, 1)
  assert_eq(r.denominator, 1)
}

///|
test "ticks_to_quarter_beats_240_ppq" {
  // 240 ticks / 480 ppq = 1/2 quarter beat
  let r = @moonsic.ticks_to_quarter_beats(240, 480)
  assert_eq(r.numerator, 1)
  assert_eq(r.denominator, 2)
}

// --- 解析：拍号 ---

///|
test "parse_time_sig_4_4_ok" {
  let r = @moonsic.parse_time_sig("4/4")
  assert_true(r is Ok(_))
  let sig = r.unwrap()
  assert_eq(sig.numerator, 4)
  assert_eq(sig.denominator, 4)
}

///|
test "parse_time_sig_6_8_ok" {
  let r = @moonsic.parse_time_sig("6/8")
  assert_true(r is Ok(_))
  let sig = r.unwrap()
  assert_eq(sig.numerator, 6)
  assert_eq(sig.denominator, 8)
}

///|
test "parse_time_sig_3_4_ok" {
  let r = @moonsic.parse_time_sig("3/4")
  assert_true(r is Ok(_))
  let sig = r.unwrap()
  assert_eq(sig.numerator, 3)
  assert_eq(sig.denominator, 4)
}

///|
test "parse_time_sig_5_3_err" {
  // denominator 3 not valid
  let r = @moonsic.parse_time_sig("5/3")
  assert_true(r is Err(_))
}

///|
test "parse_time_sig_empty_err" {
  let r = @moonsic.parse_time_sig("")
  assert_true(r is Err(_))
}

///|
test "parse_time_sig_no_slash_err" {
  let r = @moonsic.parse_time_sig("44")
  assert_true(r is Err(_))
}

///|
test "parse_time_sig_negative_err" {
  // -4/4 not valid
  let r = @moonsic.parse_time_sig("-4/4")
  assert_true(r is Err(_))
}

// --- 解析：时值单位 ---

///|
test "parse_dur_unit_q_ok" {
  let r = @moonsic.parse_dur_unit("q")
  assert_true(r is Ok(_))
  let d = r.unwrap()
  // d.unit is Quarter
  assert_eq(d.dots, 0)
  assert_true(d.tuplet is None(_))
}

///|
test "parse_dur_unit_q_dotted_ok" {
  let r = @moonsic.parse_dur_unit("q.")
  assert_true(r is Ok(_))
  let d = r.unwrap()
  assert_eq(d.dots, 1)
  assert_true(d.tuplet is None(_))
}

///|
test "parse_dur_unit_8_dotted_ok" {
  let r = @moonsic.parse_dur_unit("8.")
  assert_true(r is Ok(_))
  let d = r.unwrap()
  assert_eq(d.dots, 1)
}

///|
test "parse_dur_unit_triplet_ok" {
  let r = @moonsic.parse_dur_unit("3:2 8")
  assert_true(r is Ok(_))
  let d = r.unwrap()
  assert_eq(d.dots, 0)
  match d.tuplet {
    Some(ratio) => {
      assert_eq(ratio.actual, 3)
      assert_eq(ratio.normal, 2)
    }
    None => assert_true(false)
  }
}

///|
test "parse_dur_unit_whole_ok" {
  let r = @moonsic.parse_dur_unit("w")
  assert_true(r is Ok(_))
}

///|
test "parse_dur_unit_half_ok" {
  let r = @moonsic.parse_dur_unit("h")
  assert_true(r is Ok(_))
}

///|
test "parse_dur_unit_h_dotted_ok" {
  // "h." should be dotted half
  let r = @moonsic.parse_dur_unit("h.")
  assert_true(r is Ok(_))
  let d = r.unwrap()
  assert_eq(d.dots, 1)
}

///|
test "parse_dur_unit_empty_err" {
  let r = @moonsic.parse_dur_unit("")
  assert_true(r is Err(_))
}

///|
test "parse_dur_unit_invalid_err" {
  let r = @moonsic.parse_dur_unit("x")
  assert_true(r is Err(_))
}

///|
test "parse_dur_unit_triplet_invalid_err" {
  // missing space
  let r = @moonsic.parse_dur_unit("3:28")
  assert_true(r is Err(_))
}

///|
test "parse_dur_unit_double_dotted_ok" {
  // "q.." should be double-dotted quarter
  let r = @moonsic.parse_dur_unit("q..")
  assert_true(r is Ok(_))
  let d = r.unwrap()
  assert_eq(d.dots, 2)
}

///|
test "parse_dur_unit_w_dotted_ok" {
  // "w." should be dotted whole
  let r = @moonsic.parse_dur_unit("w.")
  assert_true(r is Ok(_))
  let d = r.unwrap()
  assert_eq(d.dots, 1)
}

// --- 解析：速度 ---

///|
test "parse_tempo_120_ok" {
  let r = @moonsic.parse_tempo("120")
  assert_true(r is Ok(_))
  let bpm = r.unwrap()
  assert_true(bpm > 119.9 && bpm < 120.1)
}

///|
test "parse_tempo_120bpm_ok" {
  let r = @moonsic.parse_tempo("120bpm")
  assert_true(r is Ok(_))
  let bpm = r.unwrap()
  assert_true(bpm > 119.9 && bpm < 120.1)
}

///|
test "parse_tempo_120_BPM_ok" {
  // case insensitive
  let r = @moonsic.parse_tempo("120BPM")
  assert_true(r is Ok(_))
  let bpm = r.unwrap()
  assert_true(bpm > 119.9 && bpm < 120.1)
}

///|
test "parse_tempo_negative_err" {
  let r = @moonsic.parse_tempo("-120bpm")
  assert_true(r is Err(_))
}

///|
test "parse_tempo_zero_err" {
  let r = @moonsic.parse_tempo("0")
  assert_true(r is Err(_))
}

///|
test "parse_tempo_empty_err" {
  let r = @moonsic.parse_tempo("")
  assert_true(r is Err(_))
}

///|
test "parse_tempo_invalid_err" {
  let r = @moonsic.parse_tempo("abc")
  assert_true(r is Err(_))
}

// --- DurUnit 转字符串 ---

///|
test "dur_unit_to_string" {
  assert_eq(@moonsic.DurQuarter.to_string(), "q")
  assert_eq(@moonsic.DurEighth.to_string(), "8")
  assert_eq(@moonsic.DurWhole.to_string(), "w")
  assert_eq(@moonsic.DurSixteenth.to_string(), "16")
}

// --- TimeError to_string ---

///|
test "time_error_to_string" {
  let e = @moonsic.TimeParseError("test")
  assert_true(e.to_string().contains("解析错误"))
  let e2 = @moonsic.InvalidTempo("bad")
  assert_true(e2.to_string().contains("无效速度"))
}

// --- rhythm_duration_to_fraction ---

///|
test "rhythm_duration_to_fraction_quarter" {
  let d = @moonsic.RhythmDuration::{
    unit: @moonsic.DurQuarter,
    dots: 0,
    tuplet: None,
  }
  let frac = @moonsic.rhythm_duration_to_fraction(d)
  assert_eq(frac.numerator, 1)
  assert_eq(frac.denominator, 1)
}

///|
test "rhythm_duration_to_fraction_dotted_eighth" {
  let d = @moonsic.RhythmDuration::{
    unit: @moonsic.DurEighth,
    dots: 1,
    tuplet: None,
  }
  let frac = @moonsic.rhythm_duration_to_fraction(d)
  assert_eq(frac.numerator, 3)
  assert_eq(frac.denominator, 4)
}

///|
test "rhythm_duration_to_fraction_triplet_eighth" {
  let d = @moonsic.RhythmDuration::{
    unit: @moonsic.DurEighth,
    dots: 0,
    tuplet: Some(@moonsic.TupletRatio::{ actual: 3, normal: 2 }),
  }
  let frac = @moonsic.rhythm_duration_to_fraction(d)
  assert_eq(frac.numerator, 1)
  assert_eq(frac.denominator, 3)
}

// ============================================================
// Position 互转测试
// ============================================================

///|
test "position_to_ticks_bar1_beat0_4_4" {
  let pos = @moonsic.BarPosition::{
    bar: 1,
    beat: @moonsic.rational(0, 1).unwrap(),
    offset: @moonsic.rational(0, 1).unwrap(),
  }
  let sig = @moonsic.time_signature(4, 4)
  let ticks = @moonsic.position_to_ticks(pos, sig, 480).unwrap()
  assert_eq(ticks, 1920)
}

///|
test "position_to_ticks_bar0_beat2_4_4" {
  let pos = @moonsic.BarPosition::{
    bar: 0,
    beat: @moonsic.rational(2, 1).unwrap(),
    offset: @moonsic.rational(0, 1).unwrap(),
  }
  let sig = @moonsic.time_signature(4, 4)
  let ticks = @moonsic.position_to_ticks(pos, sig, 480).unwrap()
  assert_eq(ticks, 960)
}

///|
test "ticks_to_position_1920_4_4" {
  let sig = @moonsic.time_signature(4, 4)
  let pos = @moonsic.ticks_to_position(1920, sig, 480).unwrap()
  assert_eq(pos.bar, 1)
  assert_eq(pos.beat.numerator, 0)
  assert_eq(pos.offset.numerator, 0)
}

///|
test "ticks_to_position_960_4_4" {
  let sig = @moonsic.time_signature(4, 4)
  let pos = @moonsic.ticks_to_position(960, sig, 480).unwrap()
  assert_eq(pos.bar, 0)
  assert_eq(pos.beat.numerator, 2)
  assert_eq(pos.offset.numerator, 0)
}

///|
test "position_to_ticks_invalid_sig_err" {
  let pos = @moonsic.BarPosition::{
    bar: 0,
    beat: @moonsic.rational(0, 1).unwrap(),
    offset: @moonsic.rational(0, 1).unwrap(),
  }
  // 5/3 是非法拍号
  let sig = @moonsic.time_signature(5, 3)
  let r = @moonsic.position_to_ticks(pos, sig, 480)
  assert_true(r is Err(_))
}

///|
test "ticks_to_position_negative_tick_err" {
  let sig = @moonsic.time_signature(4, 4)
  let r = @moonsic.ticks_to_position(-1, sig, 480)
  assert_true(r is Err(_))
}

///|
test "position_to_ticks_invalid_ppq_err" {
  let pos = @moonsic.BarPosition::{
    bar: 0,
    beat: @moonsic.rational(0, 1).unwrap(),
    offset: @moonsic.rational(0, 1).unwrap(),
  }
  let sig = @moonsic.time_signature(4, 4)
  let r = @moonsic.position_to_ticks(pos, sig, 0)
  assert_true(r is Err(_))
}

// ============================================================
// TimeMap 测试
// ============================================================

///|
test "make_time_map_ok" {
  let sig = @moonsic.time_signature(4, 4)
  let tm = @moonsic.make_time_map(480, sig, 120.0).unwrap()
  assert_eq(tm.ppq, 480)
  assert_eq(tm.sig_num, 4)
  assert_eq(tm.sig_den, 4)
  assert_true(tm.tempo_bpm > 119.9 && tm.tempo_bpm < 120.1)
}

///|
test "make_time_map_invalid_ppq_err" {
  let sig = @moonsic.time_signature(4, 4)
  let r = @moonsic.make_time_map(0, sig, 120.0)
  assert_true(r is Err(_))
}

///|
test "make_time_map_invalid_sig_err" {
  let sig = @moonsic.time_signature(5, 3)
  let r = @moonsic.make_time_map(480, sig, 120.0)
  assert_true(r is Err(_))
}

///|
test "make_time_map_invalid_bpm_err" {
  let sig = @moonsic.time_signature(4, 4)
  let r = @moonsic.make_time_map(480, sig, 0.0)
  assert_true(r is Err(_))
}

///|
test "tempo_at_tick_before_change_initial" {
  let sig = @moonsic.time_signature(4, 4)
  let tm = @moonsic.make_time_map(480, sig, 120.0).unwrap()
  let bpm = @moonsic.tempo_at_tick(tm, 0)
  assert_true(bpm > 119.9 && bpm < 120.1)
}

///|
test "tempo_at_tick_at_change_value" {
  let sig = @moonsic.time_signature(4, 4)
  let tm = @moonsic.make_time_map(480, sig, 120.0).unwrap()
  let ch = @moonsic.TempoChange::{ at_tick: 480, tempo_bpm: 140.0 }
  let tm2 = @moonsic.add_tempo_change(tm, ch)
  // Before change (tick 479): still 120
  let bpm_before = @moonsic.tempo_at_tick(tm2, 479)
  assert_true(bpm_before > 119.9 && bpm_before < 120.1)
  // At change (tick 480): becomes 140
  let bpm_at = @moonsic.tempo_at_tick(tm2, 480)
  assert_true(bpm_at > 139.9 && bpm_at < 140.1)
  // After change (tick 960): stays 140
  let bpm_after = @moonsic.tempo_at_tick(tm2, 960)
  assert_true(bpm_after > 139.9 && bpm_after < 140.1)
}

///|
test "signature_at_bar_default_sig" {
  let sig = @moonsic.time_signature(4, 4)
  let tm = @moonsic.make_time_map(480, sig, 120.0).unwrap()
  let (num, den) = @moonsic.signature_at_bar(tm, 0)
  assert_eq(num, 4)
  assert_eq(den, 4)
}

///|
test "add_tempo_change_returns_timemap" {
  let sig = @moonsic.time_signature(4, 4)
  let tm = @moonsic.make_time_map(480, sig, 120.0).unwrap()
  let ch = @moonsic.TempoChange::{ at_tick: 960, tempo_bpm: 100.0 }
  let tm2 = @moonsic.add_tempo_change(tm, ch)
  assert_eq(tm2.tempo_changes.length(), 1)
  assert_eq(tm2.tempo_changes[0].at_tick, 960)
}

///|
test "add_sig_change_updates_signature_at_bar" {
  let sig = @moonsic.time_signature(4, 4)
  let tm = @moonsic.make_time_map(480, sig, 120.0).unwrap()
  let ch = @moonsic.TimeSigChange::{ at_bar: 4, sig_num: 3, sig_den: 4 }
  let tm2 = @moonsic.add_sig_change(tm, ch)
  // Before bar 4: still 4/4
  let (n1, d1) = @moonsic.signature_at_bar(tm2, 3)
  assert_eq(n1, 4)
  assert_eq(d1, 4)
  // At bar 4: becomes 3/4
  let (n2, d2) = @moonsic.signature_at_bar(tm2, 4)
  assert_eq(n2, 3)
  assert_eq(d2, 4)
}

///|
test "ticks_to_seconds_timemap_basic" {
  let sig = @moonsic.time_signature(4, 4)
  let tm = @moonsic.make_time_map(480, sig, 120.0).unwrap()
  // 480 ticks at 120 bpm ppq=480 → 0.5 seconds
  let sec = @moonsic.ticks_to_seconds_timemap(480, tm).unwrap()
  assert_true(sec > 0.49 && sec < 0.51)
}

///|
test "ticks_to_seconds_timemap_multi_tempo" {
  let sig = @moonsic.time_signature(4, 4)
  let tm = @moonsic.make_time_map(480, sig, 120.0).unwrap()
  let ch = @moonsic.TempoChange::{ at_tick: 480, tempo_bpm: 60.0 }
  let tm2 = @moonsic.add_tempo_change(tm, ch)
  // Segment 1: 0..480 at 120 bpm → 0.5s
  // Segment 2: 480..960 at 60 bpm → 1.0s
  // Total: 1.5s
  let sec = @moonsic.ticks_to_seconds_timemap(960, tm2).unwrap()
  assert_true(sec > 1.49 && sec < 1.51)
}

///|
test "ticks_to_seconds_timemap_negative_target_err" {
  let sig = @moonsic.time_signature(4, 4)
  let tm = @moonsic.make_time_map(480, sig, 120.0).unwrap()
  let r = @moonsic.ticks_to_seconds_timemap(-1, tm)
  assert_true(r is Err(_))
}

// ============================================================
// FFI JSON 测试
// ============================================================

///|
test "ffi_parse_time_sig_4_4" {
  let json = @moonsic.ffi_parse_time_sig("4/4")
  assert_true(json.contains("4"))
  assert_true(json.contains("true"))
}

///|
test "ffi_duration_ticks_q_480" {
  let json = @moonsic.ffi_duration_ticks("q", 480)
  assert_true(json.contains("480"))
  assert_true(json.contains("true"))
}

///|
test "ffi_parse_tempo_120bpm" {
  let json = @moonsic.ffi_parse_tempo("120bpm")
  assert_true(json.contains("120"))
  assert_true(json.contains("true"))
}

///|
test "ffi_parse_time_sig_5_3_error" {
  let json = @moonsic.ffi_parse_time_sig("5/3")
  assert_true(json.contains("error"))
  assert_true(json.contains("false"))
}

///|
test "ffi_bar_length_4_4_480" {
  let json = @moonsic.ffi_bar_length("4/4", 480)
  assert_true(json.contains("1920"))
  assert_true(json.contains("true"))
}

///|
test "ffi_ticks_to_seconds_480_120_480" {
  let json = @moonsic.ffi_ticks_to_seconds(480, 120.0, 480)
  assert_true(json.contains("0.5"))
  assert_true(json.contains("true"))
}

///|
test "ffi_duration_ticks_invalid_err" {
  let json = @moonsic.ffi_duration_ticks("x", 480)
  assert_true(json.contains("error"))
  assert_true(json.contains("false"))
}

///|
test "ffi_parse_tempo_invalid_err" {
  let json = @moonsic.ffi_parse_tempo("-120bpm")
  assert_true(json.contains("error"))
  assert_true(json.contains("false"))
}

// ============================================================
// 播放时间线测试 — PlaybackTimeline
// ============================================================
