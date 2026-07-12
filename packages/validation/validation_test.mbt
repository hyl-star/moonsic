// ============================================================
// v2 validation 包测试 (blackbox)
// ============================================================

// --- helpers ---

///|
fn make_q_note(id_str : String) -> @score.ScoreEvent {
  let id = @score.event_id_checked(id_str).unwrap()
  let dur = @time.rhythm_duration(@time.DurQuarter, 0, None)
  @score.rest_event_checked(id, dur, true).unwrap()
}

///|
fn make_simple_part() -> @score.Part {
  let idx = @score.measure_index_checked(0).unwrap()
  let evt = make_q_note("x")
  let m = @score.measure_checked(
    idx,
    @score.NormalMeasure,
    None,
    None,
    None,
    [evt, evt, evt, evt],
    None,
  ).unwrap()
  let vid = @score.voice_id_checked("vv").unwrap()
  let v = @score.voice_checked(vid, "V", [m]).unwrap()
  let ch = @score.midi_channel_checked(0).unwrap()
  let staffid = @score.staff_id_checked("st").unwrap()
  let s = @score.staff_checked(staffid, "S", @score.Treble, Some(ch), None, [v]).unwrap()
  @score.part_checked(@score.part_id_checked("pp").unwrap(), "P", "", [s]).unwrap()
}

///|
fn sig44() -> @time.TimeSignature {
  @time.time_signature(4, 4)
}

// --- empty report ---

///|
test "empty_report" {
  let r = @validation.empty_validation_report()
  assert_eq(r.issue_count(), 0)
  assert_false(@validation.report_has_errors(r))
}

// --- add issue ---

///|
test "add_issue" {
  let r = @validation.empty_validation_report()
  let iss = @validation.ValidationIssue::{
    severity: @validation.Warning,
    code: @validation.EmptyVoice,
    path: "t",
    message: "m",
  }
  let r2 = @validation.report_add_issue(r, iss)
  assert_eq(@validation.report_issue_count(r2), 1)
  assert_eq(r2.warning_count, 1)
}

// --- has_errors ---

///|
test "has_errors_true" {
  let r = @validation.empty_validation_report()
  let iss = @validation.ValidationIssue::{
    severity: @validation.Error,
    code: @validation.EmptyScore,
    path: "s",
    message: "e",
  }
  assert_true(
    @validation.report_has_errors(@validation.report_add_issue(r, iss)),
  )
}

// --- severity info ---

///|
test "severity_info" {
  let r = @validation.empty_validation_report()
  let iss = @validation.ValidationIssue::{
    severity: @validation.Info,
    code: @validation.MeasureUnderfilled,
    path: "m",
    message: "i",
  }
  let r2 = @validation.report_add_issue(r, iss)
  assert_eq(r2.info_count, 1)
}

// --- measure ok ---

///|
test "validate_measure_ok" {
  let idx = @score.measure_index_checked(0).unwrap()
  let evt = make_q_note("q1")
  let m = @score.measure_checked(
    idx,
    @score.NormalMeasure,
    None,
    None,
    None,
    [evt, evt, evt, evt],
    None,
  ).unwrap()
  let r = @validation.validate_measure(
    m,
    sig44(),
    @validation.strict_validation_options(),
  )
  assert_false(@validation.report_has_errors(r))
}

// --- underfilled ---

///|
test "validate_measure_underfilled" {
  let idx = @score.measure_index_checked(1).unwrap()
  let evt = make_q_note("q2")
  let m = @score.measure_checked(
    idx,
    @score.NormalMeasure,
    None,
    None,
    None,
    [evt],
    None,
  ).unwrap()
  let r = @validation.validate_measure(
    m,
    sig44(),
    @validation.strict_validation_options(),
  )
  assert_true(@validation.report_issue_count(r) > 0)
}

// --- overflow ---

///|
test "validate_measure_overflow" {
  let idx = @score.measure_index_checked(0).unwrap()
  let dur = @time.rhythm_duration(@time.DurWhole, 0, None)
  let id = @score.event_id_checked("ow").unwrap()
  let evts = []
  for j = 0; j < 6; j = j + 1 {
    evts.push(@score.rest_event_checked(id, dur, true).unwrap())
  }
  let m = @score.measure_checked(
    idx,
    @score.NormalMeasure,
    None,
    None,
    None,
    evts,
    None,
  ).unwrap()
  let r = @validation.validate_measure(
    m,
    sig44(),
    @validation.strict_validation_options(),
  )
  assert_true(@validation.report_has_errors(r))
}

// --- pickup ---

///|
test "validate_pickup_ok" {
  let idx = @score.measure_index_checked(0).unwrap()
  let evt = make_q_note("pk")
  let m = @score.measure_checked(
    idx,
    @score.PickupMeasure,
    None,
    None,
    None,
    [evt],
    None,
  ).unwrap()
  let r = @validation.validate_measure(
    m,
    sig44(),
    @validation.strict_validation_options(),
  )
  assert_false(@validation.report_has_errors(r))
}

// --- cadenza ---

///|
test "validate_cadenza_no_check" {
  let idx = @score.measure_index_checked(0).unwrap()
  let dur = @time.rhythm_duration(@time.DurWhole, 0, None)
  let id = @score.event_id_checked("cz").unwrap()
  let evts = []
  for j = 0; j < 10; j = j + 1 {
    evts.push(@score.rest_event_checked(id, dur, true).unwrap())
  }
  let m = @score.measure_checked(
    idx,
    @score.CadenzaMeasure,
    None,
    None,
    None,
    evts,
    None,
  ).unwrap()
  let r = @validation.validate_measure(
    m,
    sig44(),
    @validation.strict_validation_options(),
  )
  assert_false(@validation.report_has_errors(r))
}

// --- voice index increasing ---

///|
test "voice_index_increasing_ok" {
  let idx0 = @score.measure_index_checked(0).unwrap()
  let idx1 = @score.measure_index_checked(1).unwrap()
  let evt = make_q_note("vi")
  let m0 = @score.measure_checked(
    idx0,
    @score.NormalMeasure,
    None,
    None,
    None,
    [evt],
    None,
  ).unwrap()
  let m1 = @score.measure_checked(
    idx1,
    @score.NormalMeasure,
    None,
    None,
    None,
    [evt],
    None,
  ).unwrap()
  let v = @score.voice_checked(@score.voice_id_checked("vv").unwrap(), "V", [
    m0, m1,
  ]).unwrap()
  let r = @validation.validate_voice(
    v,
    sig44(),
    @validation.strict_validation_options(),
  )
  assert_false(@validation.report_has_errors(r))
}

// --- voice index out of order ---

///|
test "voice_index_out_of_order" {
  let idx0 = @score.measure_index_checked(1).unwrap()
  let idx1 = @score.measure_index_checked(0).unwrap()
  let evt = make_q_note("vx")
  let m0 = @score.measure_checked(
    idx0,
    @score.NormalMeasure,
    None,
    None,
    None,
    [evt],
    None,
  ).unwrap()
  let m1 = @score.measure_checked(
    idx1,
    @score.NormalMeasure,
    None,
    None,
    None,
    [evt],
    None,
  ).unwrap()
  let v = @score.voice_checked(@score.voice_id_checked("vx").unwrap(), "VX", [
    m0, m1,
  ]).unwrap()
  let r = @validation.validate_voice(
    v,
    sig44(),
    @validation.strict_validation_options(),
  )
  assert_true(@validation.report_issue_count(r) > 0)
}

// --- empty staff ---

///|
test "empty_staff_err" {
  let sid = @score.staff_id_checked("es").unwrap()
  let ch = @score.midi_channel_checked(0).unwrap()
  let s = @score.staff_checked(sid, "ES", @score.Treble, Some(ch), None, []).unwrap()
  let r = @validation.validate_staff(
    s,
    sig44(),
    @validation.strict_validation_options(),
  )
  assert_true(@validation.report_issue_count(r) > 0)
}

// --- empty part ---

///|
test "empty_part_err" {
  let p = @score.part_checked(
    @score.part_id_checked("ep").unwrap(),
    "EP",
    "E",
    [],
  ).unwrap()
  let r = @validation.validate_part(
    p,
    sig44(),
    @validation.strict_validation_options(),
  )
  assert_true(@validation.report_issue_count(r) > 0)
}

// --- score empty parts ---

///|
test "score_empty_parts_err" {
  let sid = @score.score_id_checked("sl1").unwrap()
  let tempo = @score.tempo_checked(120).unwrap()
  let ppq = @score.ppq_checked(480).unwrap()
  let meta = @score.score_metadata_checked("", "", "", "", []).unwrap()
  let layout = @score.score_layout_checked(
    sid,
    "Song",
    "",
    ppq,
    tempo,
    sig44(),
    [],
    [],
    [],
    [],
    [],
    [],
    meta,
  ).unwrap()
  let r = @validation.validate_score_layout(
    layout,
    @validation.strict_validation_options(),
  )
  assert_true(@validation.report_has_errors(r))
}

// --- full layout ok ---

///|
test "layout_with_part_passes" {
  let sid = @score.score_id_checked("sl5").unwrap()
  let tempo = @score.tempo_checked(120).unwrap()
  let ppq = @score.ppq_checked(480).unwrap()
  let meta = @score.score_metadata_checked("", "", "", "", []).unwrap()
  let p = make_simple_part()
  let layout = @score.score_layout_checked(
    sid,
    "Song",
    "",
    ppq,
    tempo,
    sig44(),
    [p],
    [],
    [],
    [],
    [],
    [],
    meta,
  ).unwrap()
  let r = @validation.validate_score_layout(
    layout,
    @validation.strict_validation_options(),
  )
  assert_false(@validation.report_has_errors(r))
}

// --- section/repeat with parts ok ---

///|
test "section_with_part_passes" {
  let sid = @score.score_id_checked("sl6").unwrap()
  let p = make_simple_part()
  let tempo = @score.tempo_checked(120).unwrap()
  let ppq = @score.ppq_checked(480).unwrap()
  let meta = @score.score_metadata_checked("", "", "", "", []).unwrap()
  let start = @score.measure_index_checked(0).unwrap()
  let end = @score.measure_index_checked(0).unwrap()
  let sec = @score.section_checked("A", @score.Verse, start, end).unwrap()
  let layout = @score.score_layout_checked(
    sid,
    "Song",
    "",
    ppq,
    tempo,
    sig44(),
    [p],
    [sec],
    [],
    [],
    [],
    [],
    meta,
  ).unwrap()
  assert_false(
    @validation.report_has_errors(
      @validation.validate_score_layout(
        layout,
        @validation.strict_validation_options(),
      ),
    ),
  )
}

// --- text report ---

///|
test "report_text_output" {
  let r = @validation.empty_validation_report()
  let iss = @validation.ValidationIssue::{
    severity: @validation.Warning,
    code: @validation.EmptyVoice,
    path: "v",
    message: "test",
  }
  let r2 = @validation.report_add_issue(r, iss)
  assert_true(@validation.validation_report_to_text(r2).contains("EmptyVoice"))
}

// --- json report ---

///|
test "report_json_output" {
  assert_true(
    @validation.validation_report_to_json(@validation.empty_validation_report()).contains(
      "error_count",
    ),
  )
}

// --- profiles ---

///|
test "editing_profile_loose" {
  assert_false(@validation.editing_validation_options().strict_measure_capacity)
}

///|
test "strict_profile_tight" {
  assert_true(@validation.strict_validation_options().strict_measure_capacity)
}

// --- bench ---

///|
test "bench_validate_measure_1k" {
  let idx = @score.measure_index_checked(0).unwrap()
  let evt = make_q_note("b1")
  let m = @score.measure_checked(
    idx,
    @score.NormalMeasure,
    None,
    None,
    None,
    [evt, evt, evt, evt],
    None,
  ).unwrap()
  let opts = @validation.strict_validation_options()
  for i = 0; i < 1000; i = i + 1 {
    let _ = @validation.validate_measure(m, sig44(), opts)
  }
}
