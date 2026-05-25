///|
test "timeline_from_score_single_note" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let score = @moonsic.score1(t)
  let tl = @moonsic.timeline_from_score(score)
  assert_eq(tl.event_count(), 1)
  assert_true(tl.total_seconds > 0.49 && tl.total_seconds < 0.51)
}

///|
test "timeline_from_score_empty" {
  let score = @moonsic.score([])
  let tl = @moonsic.timeline_from_score(score)
  assert_eq(tl.event_count(), 0)
  assert_eq(tl.duration(), 0.0)
  assert_true(tl.is_empty())
}

///|
test "timeline_at_second_active" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let score = @moonsic.score1(t)
  let tl = @moonsic.timeline_from_score(score)
  // t=0.0 应该捕获到事件
  let active = tl.at_second(0.0)
  assert_eq(active.length(), 1)
  assert_eq(active[0].midi_note, 60)
}

///|
test "timeline_at_second_at_boundary" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let score = @moonsic.score1(t)
  let tl = @moonsic.timeline_from_score(score)
  // t=0.5 是事件结束时刻，在半开区间 [start, end) 中不该被捕获
  let at_exact_end = tl.at_second(0.5)
  assert_eq(at_exact_end.length(), 0)
  // t=0.499 接近结束但仍在区间内
  let at_just_before = tl.at_second(0.499)
  assert_eq(at_just_before.length(), 1)
}

///|
test "timeline_at_second_empty" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let score = @moonsic.score1(t)
  let tl = @moonsic.timeline_from_score(score)
  // 事件在 [0.0, 0.5)，t=1.0 外
  let active = tl.at_second(1.0)
  assert_eq(active.length(), 0)
}

///|
test "timeline_events_between_range" {
  let t = @moonsic.melody([
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.e(4), @moonsic.quarter()),
  ])
  let score = @moonsic.score1(t)
  let tl = @moonsic.timeline_from_score(score)
  // 第二拍: 0.5 ~ 1.0，D4 在此区间
  let between = tl.events_between(0.5, 1.0)
  assert_eq(between.length(), 1)
  assert_eq(between[0].midi_note, 62)
}

///|
test "timeline_events_between_overlap" {
  let t = @moonsic.melody([
    @moonsic.n(@moonsic.c(4), @moonsic.half()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
  ])
  let score = @moonsic.score1(t)
  let tl = @moonsic.timeline_from_score(score)
  // 窗口 0.25 ~ 0.75，C4(half) 覆盖整个范围，D4 从 beat 2 开始（秒=1.0）不覆盖
  let between = tl.events_between(0.25, 0.75)
  assert_eq(between.length(), 1)
  assert_eq(between[0].midi_note, 60)
}

///|
test "timeline_at_second_chord" {
  let evt = @moonsic.major(@moonsic.c(4), @moonsic.quarter())
  let t = @moonsic.melody([evt])
  let score = @moonsic.score1(t)
  let tl = @moonsic.timeline_from_score(score)
  // C major 和弦 3 音在 t=0
  let active = tl.at_second(0.0)
  assert_eq(active.length(), 3)
}

///|
test "timeline_from_score_multi_track" {
  let t1 = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let t2 = @moonsic.track_with_channel(
    [@moonsic.n(@moonsic.e(4), @moonsic.quarter())],
    1,
  )
  let score = @moonsic.score([t1, t2])
  let tl = @moonsic.timeline_from_score(score)
  assert_eq(tl.event_count(), 2)
  // 两个事件都在 t=0
  let active = tl.at_second(0.0)
  assert_eq(active.length(), 2)
}

///|
test "timeline_from_score_custom_tempo" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let score = @moonsic.score_with([t], 60, @moonsic.four_four())
  let tl = @moonsic.timeline_from_score(score)
  // 60bpm: quarter = 1.0s
  assert_true(tl.total_seconds > 0.99 && tl.total_seconds < 1.01)
  // 事件在 t=0
  let active = tl.at_second(0.0)
  assert_eq(active.length(), 1)
}

///|
test "timeline_at_second_channel_filter" {
  let t1 = @moonsic.track_with_channel(
    [@moonsic.n(@moonsic.c(4), @moonsic.quarter())],
    0,
  )
  let t2 = @moonsic.track_with_channel(
    [@moonsic.n(@moonsic.e(4), @moonsic.quarter())],
    1,
  )
  let score = @moonsic.score([t1, t2])
  let tl = @moonsic.timeline_from_score(score)
  // channel 0
  let ch0 = tl.at_second_channel(0.0, 0)
  assert_eq(ch0.length(), 1)
  assert_eq(ch0[0].midi_note, 60)
  // channel 1
  let ch1 = tl.at_second_channel(0.0, 1)
  assert_eq(ch1.length(), 1)
  assert_eq(ch1[0].midi_note, 64)
  // non-existent channel
  let ch2 = tl.at_second_channel(0.0, 2)
  assert_eq(ch2.length(), 0)
}

///|
test "timeline_duration_beats_conversion" {
  let t = @moonsic.melody([
    @moonsic.n(@moonsic.c(4), @moonsic.half()),
    @moonsic.n(@moonsic.d(4), @moonsic.half()),
  ])
  let score = @moonsic.score_with([t], 120, @moonsic.four_four())
  let tl = @moonsic.timeline_from_score(score)
  // 2 half = 4 beats = 2.0s at 120bpm
  assert_eq(tl.duration(), 2.0)
}

///|
test "timeline_event_start_is_seconds" {
  let t = @moonsic.melody([
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
  ])
  let score = @moonsic.score_with([t], 120, @moonsic.four_four())
  let tl = @moonsic.timeline_from_score(score)
  // C4 在 [0.0, 0.5)，D4 在 [0.5, 1.0)，查询 [0.5, 0.6) 仅覆盖 D4
  let events = tl.events_between(0.5, 0.6)
  assert_eq(events.length(), 1)
  assert_eq(events[0].midi_note, 62)
}

///|
test "timeline_last_end" {
  let t = @moonsic.melody([
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.half()),
  ])
  let score = @moonsic.score_with([t], 120, @moonsic.four_four())
  let tl = @moonsic.timeline_from_score(score)
  // C4 在 0.0 ~ 0.5, D4(half) 在 0.5 ~ 1.5
  assert_true(tl.last_end() > 1.49 && tl.last_end() < 1.51)
}

///|
test "timeline_last_end_empty" {
  let score = @moonsic.score([])
  let tl = @moonsic.timeline_from_score(score)
  assert_eq(tl.last_end(), 0.0)
}

///|
test "timeline_events_between_empty_range" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let score = @moonsic.score1(t)
  let tl = @moonsic.timeline_from_score(score)
  // 事件在 [0, 0.5)，查询 [10, 20) 无交集
  let between = tl.events_between(10.0, 20.0)
  assert_eq(between.length(), 0)
}

///|
test "timeline_to_string" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let score = @moonsic.score1(t)
  let tl = @moonsic.timeline_from_score(score)
  let s = tl.to_string()
  assert_true(s.contains("PlaybackTimeline"))
  assert_true(s.contains("1"))
}

// ============================================================
// score_midi 测试 — MIDI 语义适配层
// ============================================================

///|
test "score_midi_validate_midi_note" {
  assert_true(@moonsic.validate_midi_note(0))
  assert_true(@moonsic.validate_midi_note(60))
  assert_true(@moonsic.validate_midi_note(127))
  assert_false(@moonsic.validate_midi_note(-1))
  assert_false(@moonsic.validate_midi_note(128))
}

///|
test "score_midi_validate_channel" {
  assert_true(@moonsic.validate_channel(0))
  assert_true(@moonsic.validate_channel(15))
  assert_false(@moonsic.validate_channel(-1))
  assert_false(@moonsic.validate_channel(16))
}

///|
test "score_midi_validate_velocity" {
  assert_true(@moonsic.validate_velocity(0))
  assert_true(@moonsic.validate_velocity(127))
  assert_false(@moonsic.validate_velocity(-1))
  assert_false(@moonsic.validate_velocity(128))
}

///|
test "score_midi_validate_program" {
  assert_true(@moonsic.validate_program(0))
  assert_true(@moonsic.validate_program(127))
  assert_false(@moonsic.validate_program(-1))
  assert_false(@moonsic.validate_program(128))
}

///|
test "score_midi_note_on_ok" {
  let r = @moonsic.note_on(0, 0, 60, 100)
  assert_true(r is Ok(_))
  let e = r.unwrap()
  assert_eq(e.tick, 0)
}

///|
test "score_midi_note_on_invalid_note" {
  let r = @moonsic.note_on(0, 0, 128, 100)
  assert_true(r is Err(_))
}

///|
test "score_midi_note_on_invalid_channel" {
  let r = @moonsic.note_on(0, 16, 60, 100)
  assert_true(r is Err(_))
}

///|
test "score_midi_program_change_ok" {
  let r = @moonsic.program_change(0, 0, 40)
  assert_true(r is Ok(_))
  let e = r.unwrap()
  assert_eq(e.tick, 0)
}

///|
test "score_midi_program_change_invalid" {
  let r = @moonsic.program_change(0, 0, 128)
  assert_true(r is Err(_))
}

///|
test "score_midi_control_change_ok" {
  let r = @moonsic.control_change(0, 0, 7, 100)
  assert_true(r is Ok(_))
  let e = r.unwrap()
  assert_eq(e.tick, 0)
}

///|
test "score_midi_control_change_invalid_ctrl" {
  let r = @moonsic.control_change(0, 0, 128, 100)
  assert_true(r is Err(_))
}

///|
test "score_midi_to_score_basic" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let s = @moonsic.score1(t)
  let ms = @moonsic.score_to_midi_score(s, 480)
  assert_eq(ms.tracks.length(), 2)
  assert_eq(ms.ppq, 480)
  let music = ms.tracks[1]
  assert_true(music.events.length() >= 4)
}

///|
test "score_midi_to_score_with_instrument" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let t2 = @moonsic.instrument(t, @moonsic.violin())
  let s = @moonsic.score1(t2)
  let ms = @moonsic.score_to_midi_score(s, 480)
  assert_eq(ms.tracks.length(), 2)
  assert_eq(ms.tracks[1].program, 40)
}

///|
test "score_midi_sort_events_by_tick" {
  let e1 = @moonsic.note_on(480, 0, 60, 100).unwrap()
  let e2 = @moonsic.note_on(0, 0, 60, 100).unwrap()
  let sorted = @moonsic.sort_midi_events([e1, e2])
  assert_eq(sorted[0].tick, 0)
  assert_eq(sorted[1].tick, 480)
}

///|
test "score_midi_sort_events_same_tick_priority" {
  let e1 = @moonsic.note_on(0, 0, 60, 100).unwrap()
  let e2 = @moonsic.tempo_change(0, 120).unwrap()
  let e3 = @moonsic.track_name(0, "Test").unwrap()
  let sorted = @moonsic.sort_midi_events([e1, e2, e3])
  assert_eq(sorted.length(), 3)
  assert_eq(sorted[0].tick, 0)
  assert_eq(sorted[1].tick, 0)
  assert_eq(sorted[2].tick, 0)
}

///|
test "score_midi_to_bytes_not_empty" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let s = @moonsic.score1(t)
  let ms = @moonsic.score_to_midi_score(s, 480)
  let bytes = @moonsic.midi_score_to_bytes(ms)
  assert_true(bytes.length() > 0)
}

///|
test "score_midi_roundtrip" {
  let t = @moonsic.melody([
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
  ])
  let s = @moonsic.score1(t)
  let bytes = @moonsic.score_to_midi_bytes(s, 480)
  let file = @midi.parse(bytes)
  assert_eq(file.tracks.length(), 2)
  assert_eq(file.division, (480).to_uint16())
}

///|
test "score_midi_to_score_two_tracks" {
  let t1 = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let t2 = @moonsic.melody([@moonsic.n(@moonsic.e(4), @moonsic.quarter())])
  let s = @moonsic.score([t1, t2])
  let ms = @moonsic.score_to_midi_score(s, 480)
  assert_eq(ms.tracks.length(), 3)
}

///|
test "score_midi_tempo_change_event" {
  let r = @moonsic.tempo_change(0, 140)
  assert_true(r is Ok(_))
  let e = r.unwrap()
  assert_eq(e.tick, 0)
}

///|
test "score_midi_tempo_change_invalid_bpm" {
  let r = @moonsic.tempo_change(0, 0)
  assert_true(r is Err(_))
}

///|
test "score_midi_end_of_track" {
  let r = @moonsic.end_of_track(960)
  assert_true(r is Ok(_))
  let e = r.unwrap()
  assert_eq(e.tick, 960)
}

///|
test "score_midi_multi_note_score" {
  let t = @moonsic.melody([
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.e(4), @moonsic.half()),
  ])
  let s = @moonsic.score1(t)
  let ms = @moonsic.score_to_midi_score(s, 480)
  let music = ms.tracks[1]
  assert_eq(music.events.length(), 8)
}

///|
test "score_midi_chord_expands" {
  let t = @moonsic.melody([@moonsic.major(@moonsic.c(4), @moonsic.quarter())])
  let s = @moonsic.score1(t)
  let ms = @moonsic.score_to_midi_score(s, 480)
  let music = ms.tracks[1]
  assert_eq(music.events.length(), 8)
}

///|
test "score_midi_bytes_with_instrument" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let t2 = @moonsic.instrument(t, @moonsic.acoustic_grand_piano())
  let s = @moonsic.score1(t2)
  let bytes = @moonsic.score_to_midi_bytes(s, 480)
  let file = @midi.parse(bytes)
  assert_eq(file.tracks.length(), 2)
}

// ============================================================
// 曲谱布局模块测试 — Measure/Voice/Staff/Part/ScoreLayout
// ============================================================

// --- Measure 构造 ---

///|
test "make_measure_valid" {
  let sig = @moonsic.four_four()
  let events = [@moonsic.n(@moonsic.c(4), @moonsic.quarter())]
  let r = @moonsic.make_measure(0, Some(sig), events)
  assert_true(r is Ok(_))
  let m = r.unwrap()
  assert_eq(m.index, 0)
  assert_eq(m.event_count(), 1)
}

///|
test "make_measure_negative_index_err" {
  let sig = @moonsic.four_four()
  let r = @moonsic.make_measure(-1, Some(sig), [])
  assert_true(r is Err(_))
}

///|
test "make_measure_invalid_time_sig_err" {
  let bad_sig = @moonsic.time_signature(5, 3)
  let r = @moonsic.make_measure(0, Some(bad_sig), [])
  assert_true(r is Err(_))
}

///|
test "empty_measure_creates_basic" {
  let m = @moonsic.empty_measure(3)
  assert_eq(m.index, 3)
  assert_eq(m.event_count(), 0)
}

// --- Voice 构造 ---

///|
test "make_voice_valid" {
  let m = @moonsic.empty_measure(0)
  let r = @moonsic.make_voice("RH", [m])
  assert_true(r is Ok(_))
  let v = r.unwrap()
  assert_eq(@moonsic.voice_measure_count(v), 1)
}

///|
test "make_voice_empty_name_err" {
  let r = @moonsic.make_voice("", [])
  assert_true(r is Err(_))
}

///|
test "voice_add_measure_adds_one" {
  let v = @moonsic.empty_voice("RH")
  let m = @moonsic.empty_measure(0)
  let r = @moonsic.voice_add_measure(v, m)
  assert_true(r is Ok(_))
  let v2 = r.unwrap()
  assert_eq(@moonsic.voice_measure_count(v2), 1)
}

///|
test "empty_voice_creates_with_name" {
  let v = @moonsic.empty_voice("Bass")
  assert_eq(@moonsic.voice_measure_count(v), 0)
}

// --- Staff 构造 ---

///|
test "make_staff_valid" {
  let v = @moonsic.empty_voice("RH")
  let r = @moonsic.make_staff("Piano", Some(0), Some(0), Some("Grand Piano"), [
    v,
  ])
  assert_true(r is Ok(_))
  let s = r.unwrap()
  assert_eq(s.name, "Piano")
}

///|
test "make_staff_invalid_channel_err" {
  let r = @moonsic.make_staff("Piano", Some(16), None, None, [])
  assert_true(r is Err(_))
}

///|
test "make_staff_invalid_program_err" {
  let r = @moonsic.make_staff("Piano", None, Some(128), None, [])
  assert_true(r is Err(_))
}

///|
test "staff_add_voice_adds_one" {
  let s = @moonsic.empty_staff("Piano")
  let v = @moonsic.empty_voice("RH")
  let r = @moonsic.staff_add_voice(s, v)
  assert_true(r is Ok(_))
}

// --- Part 构造 ---

///|
test "make_part_valid" {
  let s = @moonsic.empty_staff("Piano")
  let r = @moonsic.make_part("Keyboard", [s])
  assert_true(r is Ok(_))
}

///|
test "part_add_staff_adds_one" {
  let p = @moonsic.empty_part("Keyboard")
  let s = @moonsic.empty_staff("Piano")
  let r = @moonsic.part_add_staff(p, s)
  assert_true(r is Ok(_))
  let p2 = r.unwrap()
  assert_eq(p2.staves.length(), 1)
}

// --- ScoreLayout 构造 ---

///|
test "make_score_layout_valid" {
  let r = @moonsic.make_score_layout("My Song", 480, [])
  assert_true(r is Ok(_))
  let sl = r.unwrap()
  assert_eq(sl.title, "My Song")
  assert_eq(sl.ppq, 480)
}

///|
test "make_score_layout_invalid_ppq_zero_err" {
  let r = @moonsic.make_score_layout("Bad", 0, [])
  assert_true(r is Err(_))
}

///|
test "empty_score_layout_creates_basic" {
  let r = @moonsic.empty_score_layout("Empty", 480)
  assert_true(r is Ok(_))
  let sl = r.unwrap()
  assert_eq(sl.title, "Empty")
  assert_eq(@moonsic.score_layout_measure_count(sl), 0)
}

///|
test "layout_add_part_works" {
  let r = @moonsic.empty_score_layout("Song", 480)
  let sl = r.unwrap()
  let p = @moonsic.empty_part("Piano")
  let sl2 = @moonsic.layout_add_part(sl, p)
  assert_eq(sl2.parts.length(), 1)
}

// --- 校验 ---

///|
test "validate_measure_under_capacity_ok" {
  let sig = @moonsic.four_four()
  let events = [
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
  ]
  let r = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let vr = @moonsic.validate_measure(r, sig, 480)
  assert_true(vr is Ok(_))
}

///|
test "validate_measure_overflow_err" {
  // 4/4 at ppq=480 has 1920 ticks. Whole(1920) + Half(960) = 2880 > 1920
  let sig = @moonsic.four_four()
  let events = [
    @moonsic.n(@moonsic.c(4), @moonsic.whole()),
    @moonsic.n(@moonsic.d(4), @moonsic.half()),
  ]
  let r = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let vr = @moonsic.validate_measure(r, sig, 480)
  assert_true(vr is Err(_))
}

///|
test "validate_measure_at_capacity_ok" {
  let sig = @moonsic.four_four()
  let events = [
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.e(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.f(4), @moonsic.quarter()),
  ]
  let r = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let vr = @moonsic.validate_measure(r, sig, 480)
  assert_true(vr is Ok(_))
}

///|
test "validate_measure_overflow_3_4" {
  let sig = @moonsic.time_signature(3, 4)
  // 3/4 at ppq=480 has 1440 ticks. Half(960) + Q(480) + Q(480) = 1920 > 1440
  let events = [
    @moonsic.n(@moonsic.c(4), @moonsic.half()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.e(4), @moonsic.quarter()),
  ]
  let r = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let vr = @moonsic.validate_measure(r, sig, 480)
  assert_true(vr is Err(_))
}

///|
test "validate_measure_invalid_ppq_err" {
  let sig = @moonsic.four_four()
  let events = [@moonsic.n(@moonsic.c(4), @moonsic.quarter())]
  let r = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let vr = @moonsic.validate_measure(r, sig, 0)
  assert_true(vr is Err(_))
}

///|
test "validate_score_layout_full_ok" {
  let sig = @moonsic.four_four()
  let events = [
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
  ]
  let m = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let v = @moonsic.make_voice("RH", [m]).unwrap()
  let s = @moonsic.make_staff("Piano", Some(0), Some(0), None, [v]).unwrap()
  let p = @moonsic.make_part("Keyboard", [s]).unwrap()
  let sl = @moonsic.make_score_layout("Test", 480, [p]).unwrap()
  let vr = @moonsic.validate_score_layout(sl)
  assert_true(vr is Ok(_))
}

///|
test "validate_score_layout_overflow_fail" {
  let sig = @moonsic.four_four()
  let events = [
    @moonsic.n(@moonsic.c(4), @moonsic.whole()),
    @moonsic.n(@moonsic.d(4), @moonsic.half()),
  ]
  let m = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let v = @moonsic.make_voice("RH", [m]).unwrap()
  let s = @moonsic.make_staff("Piano", Some(0), None, None, [v]).unwrap()
  let p = @moonsic.make_part("Keyboard", [s]).unwrap()
  let sl = @moonsic.make_score_layout("Test", 480, [p]).unwrap()
  let vr = @moonsic.validate_score_layout(sl)
  assert_true(vr is Err(_))
}

// --- 查询 ---

///|
test "measure_beat_duration_two_halves" {
  let sig = @moonsic.four_four()
  let events = [
    @moonsic.n(@moonsic.c(4), @moonsic.half()),
    @moonsic.n(@moonsic.d(4), @moonsic.half()),
  ]
  let m = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let dur = @moonsic.measure_beat_duration(m)
  assert_true(dur > 3.99 && dur < 4.01)
}

///|
test "measure_tick_duration_quarter" {
  let sig = @moonsic.four_four()
  let events = [@moonsic.n(@moonsic.c(4), @moonsic.quarter())]
  let m = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let ticks = @moonsic.measure_tick_duration(m, 480)
  assert_eq(ticks, 480)
}

///|
test "voice_measure_count_three" {
  let m0 = @moonsic.empty_measure(0)
  let m1 = @moonsic.empty_measure(1)
  let m2 = @moonsic.empty_measure(2)
  let v = @moonsic.make_voice("RH", [m0, m1, m2]).unwrap()
  assert_eq(@moonsic.voice_measure_count(v), 3)
}

///|
test "staff_measure_count_max_voice" {
  let m0 = @moonsic.empty_measure(0)
  let m1 = @moonsic.empty_measure(1)
  let v0 = @moonsic.make_voice("RH", [m0]).unwrap()
  let v1 = @moonsic.make_voice("LH", [m0, m1]).unwrap()
  let s = @moonsic.make_staff("Piano", None, None, None, [v0, v1]).unwrap()
  assert_eq(@moonsic.staff_measure_count(s), 2)
}

///|
test "score_layout_measure_count_multi_part" {
  let m = @moonsic.empty_measure(0)
  let v = @moonsic.make_voice("RH", [m]).unwrap()
  let s = @moonsic.make_staff("Piano", None, None, None, [v]).unwrap()
  let p = @moonsic.make_part("Keyboard", [s]).unwrap()
  let sl = @moonsic.make_score_layout("Song", 480, [p]).unwrap()
  assert_eq(@moonsic.score_layout_measure_count(sl), 1)
}

///|
test "score_layout_measure_count_empty" {
  let sl = @moonsic.empty_score_layout("Empty", 480).unwrap()
  assert_eq(@moonsic.score_layout_measure_count(sl), 0)
}

// --- 转换 ---

///|
test "staff_to_track_single_voice" {
  let sig = @moonsic.four_four()
  let events = [
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
  ]
  let m = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let v = @moonsic.make_voice("RH", [m]).unwrap()
  let s = @moonsic.make_staff("Piano", Some(0), Some(0), None, [v]).unwrap()
  let track = @moonsic.staff_to_track(s)
  assert_eq(track.channel, 0)
  assert_eq(track.program, 0)
  assert_eq(track.events.length(), 2)
}

///|
test "staff_to_track_default_channel_no_voices" {
  let s = @moonsic.empty_staff("Empty")
  let track = @moonsic.staff_to_track(s)
  assert_eq(track.channel, 0)
  assert_eq(track.program, -1)
  assert_eq(track.events.length(), 0)
}

///|
test "staff_to_track_multi_voice_interleave" {
  let sig = @moonsic.four_four()
  let events_rh = [@moonsic.n(@moonsic.c(4), @moonsic.quarter())]
  let events_lh = [@moonsic.n(@moonsic.c(3), @moonsic.quarter())]
  let m0 = @moonsic.make_measure(0, Some(sig), events_rh).unwrap()
  let m1 = @moonsic.make_measure(0, Some(sig), events_lh).unwrap()
  let v_rh = @moonsic.make_voice("RH", [m0]).unwrap()
  let v_lh = @moonsic.make_voice("LH", [m1]).unwrap()
  let s = @moonsic.make_staff("Piano", Some(0), None, None, [v_rh, v_lh]).unwrap()
  let track = @moonsic.staff_to_track(s)
  assert_eq(track.events.length(), 2)
}

///|
test "score_layout_to_score_multi_part" {
  let sig = @moonsic.four_four()
  let events = [@moonsic.n(@moonsic.c(4), @moonsic.quarter())]
  let m = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let v = @moonsic.make_voice("RH", [m]).unwrap()
  let s = @moonsic.make_staff("Piano", Some(0), Some(0), None, [v]).unwrap()
  let p = @moonsic.make_part("Keyboard", [s]).unwrap()
  let sl = @moonsic.make_score_layout("Song", 480, [p]).unwrap()
  let score = @moonsic.score_layout_to_score(sl)
  assert_eq(score.track_count(), 1)
  assert_eq(score.tracks[0].event_count(), 1)
}

// --- 错误路径测试 ---

///|
test "make_staff_empty_name_err" {
  let r = @moonsic.make_staff("", None, None, None, [])
  assert_true(r is Err(_))
}

///|
test "make_staff_channel_negative_err" {
  let r = @moonsic.make_staff("Piano", Some(-1), None, None, [])
  assert_true(r is Err(_))
}

///|
test "make_staff_program_negative_err" {
  let r = @moonsic.make_staff("Piano", None, Some(-1), None, [])
  assert_true(r is Err(_))
}

///|
test "validate_voice_empty_name_err" {
  let v = @moonsic.empty_voice("")
  let vr = @moonsic.validate_voice(v, @moonsic.four_four(), 480)
  assert_true(vr is Err(_))
}

///|
test "validate_staff_valid_ok" {
  let sig = @moonsic.four_four()
  let m = @moonsic.empty_measure(0)
  let v = @moonsic.make_voice("RH", [m]).unwrap()
  let s = @moonsic.make_staff("Piano", Some(0), None, None, [v]).unwrap()
  let vr = @moonsic.validate_staff(s, sig, 480)
  assert_true(vr is Ok(_))
}

///|
test "validate_part_valid_ok" {
  let sig = @moonsic.four_four()
  let m = @moonsic.empty_measure(0)
  let v = @moonsic.make_voice("RH", [m]).unwrap()
  let s = @moonsic.make_staff("Piano", Some(0), None, None, [v]).unwrap()
  let p = @moonsic.make_part("Keyboard", [s]).unwrap()
  let vr = @moonsic.validate_part(p, sig, 480)
  assert_true(vr is Ok(_))
}

///|
test "validate_part_empty_name_err" {
  let p = @moonsic.empty_part("")
  let vr = @moonsic.validate_part(p, @moonsic.four_four(), 480)
  assert_true(vr is Err(_))
}

// --- ScoreError to_string ---

///|
test "score_error_invalid_measure_to_string" {
  let e = @moonsic.LayoutInvalidMeasure("bad measure")
  assert_true(e.to_string().contains("无效小节"))
}

///|
test "score_error_measure_overflow_to_string" {
  let e = @moonsic.LayoutMeasureOverflow("bar 3 overflow")
  assert_true(e.to_string().contains("小节溢出"))
}

///|
test "score_error_invalid_ppq_to_string" {
  let e = @moonsic.ScoreError::InvalidPPQ(0)
  assert_true(e.to_string().contains("无效 PPQ"))
}

///|
test "score_error_invalid_channel_to_string" {
  let e = @moonsic.LayoutInvalidChannel(16)
  assert_true(e.to_string().contains("无效通道"))
}

///|
test "score_error_invalid_program_to_string" {
  let e = @moonsic.LayoutInvalidProgram(128)
  assert_true(e.to_string().contains("无效乐器"))
}

///|
test "score_error_invalid_voice_to_string" {
  let e = @moonsic.LayoutInvalidVoice("bad")
  assert_true(e.to_string().contains("无效声部"))
}

///|
test "score_error_invalid_staff_to_string" {
  let e = @moonsic.LayoutInvalidStaff("bad")
  assert_true(e.to_string().contains("无效五线谱"))
}

///|
test "score_error_invalid_part_to_string" {
  let e = @moonsic.LayoutInvalidPart("bad")
  assert_true(e.to_string().contains("无效声部组"))
}

///|
test "score_error_invalid_score_layout_to_string" {
  let e = @moonsic.InvalidScoreLayout("bad")
  assert_true(e.to_string().contains("无效曲谱布局"))
}

// --- track_to_voice 反推 ---

///|
test "track_to_voice_basic" {
  let t = @moonsic.melody([
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
  ])
  let r = @moonsic.track_to_voice(t, "Melody", 480, @moonsic.four_four())
  assert_true(r is Ok(_))
  let v = r.unwrap()
  assert_eq(@moonsic.voice_measure_count(v), 1)
}

///|
test "track_to_voice_measure_split" {
  let t = @moonsic.melody([
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.e(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.f(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.g(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.a(4), @moonsic.quarter()),
  ])
  let r = @moonsic.track_to_voice(t, "Melody", 480, @moonsic.four_four())
  assert_true(r is Ok(_))
  let v = r.unwrap()
  assert_eq(@moonsic.voice_measure_count(v), 2)
}

///|
test "track_to_voice_invalid_ppq_err" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let r = @moonsic.track_to_voice(t, "Bad", 0, @moonsic.four_four())
  assert_true(r is Err(_))
}

///|
test "track_to_voice_invalid_time_sig_err" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let bad_sig = @moonsic.time_signature(5, 3)
  let r = @moonsic.track_to_voice(t, "Bad", 480, bad_sig)
  assert_true(r is Err(_))
}

// --- track_to_staff 反推 ---

///|
test "track_to_staff_basic" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let r = @moonsic.track_to_staff(t, "Piano", 480, @moonsic.four_four())
  assert_true(r is Ok(_))
}

///|
test "track_to_staff_no_program" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let r = @moonsic.track_to_staff(t, "Melody", 480, @moonsic.four_four())
  assert_true(r is Ok(_))
}

// --- 边界值测试 ---

///|
test "make_measure_none_signature_ok" {
  let r = @moonsic.make_measure(0, None, [])
  assert_true(r is Ok(_))
  let m = r.unwrap()
  assert_eq(m.index, 0)
  assert_eq(m.event_count(), 0)
}

///|
test "measure_beat_duration_with_rest" {
  let sig = @moonsic.four_four()
  let events = [
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.r(@moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.half()),
  ]
  let m = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let dur = @moonsic.measure_beat_duration(m)
  assert_true(dur > 3.99 && dur < 4.01)
}

///|
test "staff_to_track_preserves_chord" {
  let sig = @moonsic.four_four()
  let events = [@moonsic.major(@moonsic.c(4), @moonsic.quarter())]
  let m = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let v = @moonsic.make_voice("RH", [m]).unwrap()
  let s = @moonsic.make_staff("Piano", Some(0), None, None, [v]).unwrap()
  let track = @moonsic.staff_to_track(s)
  assert_eq(track.events.length(), 1)
}

///|
test "score_layout_to_score_empty" {
  let sl = @moonsic.empty_score_layout("Empty", 480).unwrap()
  let score = @moonsic.score_layout_to_score(sl)
  assert_eq(score.track_count(), 0)
}

///|
test "make_score_layout_invalid_ppq_negative_err" {
  let r = @moonsic.make_score_layout("Bad", -1, [])
  assert_true(r is Err(_))
}

///|
test "make_part_empty_name_err" {
  let r = @moonsic.make_part("", [])
  assert_true(r is Err(_))
}

// ============================================================
// serialize 模块测试 — JSON 序列化/反序列化
// ============================================================
