// ============================================================
// v2 score 包基础性能基准
// ============================================================

///|
test "bench_tempo_checked_1k" {
  for _i = 0; _i < 1000; _i = _i + 1 {
    let _ = tempo_checked(120)
  }
}

///|
test "bench_event_construct_100" {
  let id = event_id_checked("n1").unwrap()
  let vel = velocity_checked(100).unwrap()
  let dur = @time.rhythm_duration(@time.DurQuarter, 0, None)
  for _i = 0; _i < 100; _i = _i + 1 {
    let _ = note_event_checked(id, @pitch.c(4), dur, Some(vel), NoTie, [], [])
  }
}

///|
test "bench_layout_construct_50" {
  let sid = score_id_checked("b1").unwrap()
  let pid = part_id_checked("bp1").unwrap()
  let vid = voice_id_checked("bv1").unwrap()
  let tempo = tempo_checked(120).unwrap()
  let ppq = ppq_checked(480).unwrap()
  let sig = @time.time_signature(4, 4)
  for _i = 0; _i < 50; _i = _i + 1 {
    let _p = part_checked(pid, "P", "P", [])
    let _v = voice_checked(vid, "V", [])
    let _l = score_layout_checked(
      sid,
      "T",
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
      { copyright: "", lyricist: "", arranger: "", source: "", tags: [] },
    )
  }
}
