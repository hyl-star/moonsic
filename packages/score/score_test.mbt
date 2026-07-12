// ============================================================
// v2 score 包测试
// ============================================================

// --- Tempo / PPQ / Velocity ---

///|
test "tempo_120_ok" {
  let r = @score.tempo_checked(120)
  assert_true(r is Ok(_))
}

///|
test "tempo_zero_err" {
  assert_true(@score.tempo_checked(0) is Err(_))
}

///|
test "tempo_negative_err" {
  assert_true(@score.tempo_checked(-1) is Err(_))
}

///|
test "ppq_480_ok" {
  assert_true(@score.ppq_checked(480) is Ok(_))
}

///|
test "ppq_zero_err" {
  assert_true(@score.ppq_checked(0) is Err(_))
}

///|
test "velocity_100_ok" {
  assert_true(@score.velocity_checked(100) is Ok(_))
}

///|
test "velocity_128_err" {
  assert_true(@score.velocity_checked(128) is Err(_))
}

///|
test "midi_channel_9_ok" {
  assert_true(@score.midi_channel_checked(9) is Ok(_))
}

///|
test "midi_channel_16_err" {
  assert_true(@score.midi_channel_checked(16) is Err(_))
}

///|
test "midi_program_0_ok" {
  assert_true(@score.midi_program_checked(0) is Ok(_))
}

///|
test "midi_program_128_err" {
  assert_true(@score.midi_program_checked(128) is Err(_))
}

// --- ScoreEvent ---

///|
test "note_event_ok" {
  let id = @score.event_id_checked("n1").unwrap()
  let vel = @score.velocity_checked(100).unwrap()
  let r = @score.note_event_checked(
    id,
    @pitch.c(4),
    @time.rhythm_duration(@time.DurQuarter, 0, None),
    Some(vel),
    @score.NoTie,
    [],
    [],
  )
  assert_true(r is Ok(_))
}

///|
test "rest_event_ok" {
  let id = @score.event_id_checked("r1").unwrap()
  let r = @score.rest_event_checked(
    id,
    @time.rhythm_duration(@time.DurQuarter, 0, None),
    true,
  )
  assert_true(r is Ok(_))
}

///|
test "chord_event_ok" {
  let id = @score.event_id_checked("c1").unwrap()
  let vel = @score.velocity_checked(100).unwrap()
  let r = @score.chord_event_checked(
    id,
    [@pitch.c(4), @pitch.e(4), @pitch.g(4)],
    @time.rhythm_duration(@time.DurHalf, 0, None),
    Some(vel),
    @score.NoTie,
    [],
    [],
  )
  assert_true(r is Ok(_))
}

///|
test "chord_event_empty_pitches_err" {
  let id = @score.event_id_checked("c2").unwrap()
  let vel = @score.velocity_checked(100).unwrap()
  let r = @score.chord_event_checked(
    id,
    [],
    @time.rhythm_duration(@time.DurHalf, 0, None),
    Some(vel),
    @score.NoTie,
    [],
    [],
  )
  assert_true(r is Err(_))
}

///|
test "direction_event_ok" {
  let id = @score.event_id_checked("d1").unwrap()
  let rat = @time.rational(1, 4).unwrap()
  let r = @score.direction_event_checked(id, rat, @score.WordsDir)
  assert_true(r is Ok(_))
}

///|
test "spacer_event_ok" {
  let id = @score.event_id_checked("s1").unwrap()
  let r = @score.spacer_event_checked(
    id,
    @time.rhythm_duration(@time.DurQuarter, 0, None),
  )
  assert_true(r is Ok(_))
}

// --- SimpleScore ---

///|
test "simple_note_ok" {
  let vel = @score.velocity_checked(100).unwrap()
  let r = @score.simple_note_checked(
    @pitch.c(4),
    @time.rhythm_duration(@time.DurQuarter, 0, None),
    Some(vel),
  )
  assert_true(r is Ok(_))
}

///|
test "simple_rest_ok" {
  let r = @score.simple_rest_checked(
    @time.rhythm_duration(@time.DurQuarter, 0, None),
  )
  assert_true(r is Ok(_))
}

///|
test "simple_chord_empty_err" {
  let vel = @score.velocity_checked(100).unwrap()
  let r = @score.simple_chord_checked(
    [],
    @time.rhythm_duration(@time.DurQuarter, 0, None),
    Some(vel),
  )
  assert_true(r is Err(_))
}

///|
test "simple_track_ok" {
  let vel = @score.velocity_checked(100).unwrap()
  let evt = @score.simple_note_checked(
    @pitch.c(4),
    @time.rhythm_duration(@time.DurQuarter, 0, None),
    Some(vel),
  ).unwrap()
  let ch = @score.midi_channel_checked(0).unwrap()
  let r = @score.simple_track_checked([evt], Some(ch), None)
  assert_true(r is Ok(_))
}

///|
test "simple_score_ok" {
  let vel = @score.velocity_checked(100).unwrap()
  let evt = @score.simple_note_checked(
    @pitch.c(4),
    @time.rhythm_duration(@time.DurQuarter, 0, None),
    Some(vel),
  ).unwrap()
  let ch = @score.midi_channel_checked(0).unwrap()
  let track = @score.simple_track_checked([evt], Some(ch), None).unwrap()
  let tempo = @score.tempo_checked(120).unwrap()
  let sig = @time.time_signature(4, 4)
  let r = @score.simple_score_checked([track], tempo, sig)
  assert_true(r is Ok(_))
}

///|
test "simple_score_empty_tracks_err" {
  let tempo = @score.tempo_checked(120).unwrap()
  let sig = @time.time_signature(4, 4)
  assert_true(@score.simple_score_checked([], tempo, sig) is Err(_))
}

// --- MeasureIndex / ScorePath ---

///|
test "measure_index_negative_err" {
  assert_true(@score.measure_index_checked(-1) is Err(_))
}

///|
test "measure_index_zero_ok" {
  assert_true(@score.measure_index_checked(0) is Ok(_))
}

///|
test "score_path_negative_err" {
  assert_true(@score.score_path_checked(-1, 0, 0, 0, 0) is Err(_))
}

// --- Section / Repeat / Ending ---

///|
test "section_ok" {
  let start = @score.measure_index_checked(0).unwrap()
  let end = @score.measure_index_checked(7).unwrap()
  let r = @score.section_checked("Chorus", @score.Chorus, start, end)
  assert_true(r is Ok(_))
}

///|
test "section_end_before_start_err" {
  let start = @score.measure_index_checked(7).unwrap()
  let end = @score.measure_index_checked(0).unwrap()
  assert_true(@score.section_checked("", @score.Chorus, start, end) is Err(_))
}

///|
test "repeat_mark_count_zero_err" {
  let m = @score.measure_index_checked(0).unwrap()
  assert_true(
    @score.repeat_mark_checked(@score.RepeatStart, m, None, 0) is Err(_),
  )
}

///|
test "repeat_mark_ok" {
  let m = @score.measure_index_checked(0).unwrap()
  let r = @score.repeat_mark_checked(@score.RepeatBoth, m, None, 2)
  assert_true(r is Ok(_))
}

///|
test "ending_bracket_zero_err" {
  let start = @score.measure_index_checked(0).unwrap()
  let end = @score.measure_index_checked(3).unwrap()
  assert_true(
    @score.ending_bracket_checked(0, start, end, @score.FirstEnding) is Err(_),
  )
}

// --- Part / Staff / Voice / Layout ---

///|
test "part_ok" {
  let pid = @score.part_id_checked("p1").unwrap()
  let r = @score.part_checked(pid, "Piano", "Pno", [])
  assert_true(r is Ok(_))
}

///|
test "part_empty_name_err" {
  let pid = @score.part_id_checked("p1").unwrap()
  assert_true(@score.part_checked(pid, "", "", []) is Err(_))
}

///|
test "staff_ok" {
  let sid = @score.staff_id_checked("s1").unwrap()
  let ch = @score.midi_channel_checked(0).unwrap()
  let r = @score.staff_checked(sid, "Treble", @score.Treble, Some(ch), None, [])
  assert_true(r is Ok(_))
}

///|
test "voice_ok" {
  let vid = @score.voice_id_checked("v1").unwrap()
  let r = @score.voice_checked(vid, "Soprano", [])
  assert_true(r is Ok(_))
}

///|
test "score_layout_ok" {
  let sid = @score.score_id_checked("layout-1").unwrap()
  let tempo = @score.tempo_checked(120).unwrap()
  let ppq = @score.ppq_checked(480).unwrap()
  let sig = @time.time_signature(4, 4)
  let meta = @score.score_metadata_checked("", "", "", "", []).unwrap()
  let r = @score.score_layout_checked(
    sid,
    "Song",
    "",
    ppq,
    tempo,
    sig,
    [],
    [],
    [],
    [],
    [],
    [],
    meta,
  )
  assert_true(r is Ok(_))
}

// --- ScoreError ---

///|
test "score_error_to_string" {
  let e = @score.ScoreError::InvalidMeasure("test")
  assert_true(e.to_string().contains("无效小节"))
}

///|
test "score_error_invalid_tempo" {
  let e = @score.ScoreError::InvalidTempo("test")
  assert_true(e.to_string().contains("无效速度"))
}
