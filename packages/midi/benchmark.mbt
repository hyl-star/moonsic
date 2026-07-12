// ============================================================
// v2 midi 包基准
// ============================================================

///|
test "bench_midi_note_on_1k" {
  for i = 0; i < 1000; i = i + 1 {
    let _ = note_on(0, 0, 60, 100)
  }
}

///|
test "bench_midi_export_50" {
  let vel = @score.velocity_checked(100).unwrap()
  let dur = @time.rhythm_duration(@time.DurQuarter, 0, None)
  let evts = [@score.simple_note_checked(@pitch.c(4), dur, Some(vel)).unwrap()]
  let ch = @score.midi_channel_checked(0).unwrap()
  let track = @score.simple_track_checked(evts, Some(ch), None).unwrap()
  let tempo = @score.tempo_checked(120).unwrap()
  let sig = @time.time_signature(4, 4)
  let score = @score.simple_score_checked([track], tempo, sig).unwrap()
  for i = 0; i < 50; i = i + 1 {
    let ms = simple_score_to_midi_score(score, 480)
    let _ = midi_score_to_bytes(ms)
  }
}
