///|
test "bench_convert_50" {
  let dur = @time.rhythm_duration(@time.DurQuarter, 0, None)
  let vel = @score.velocity_checked(100).unwrap()
  let evts = [@score.simple_note_checked(@pitch.c(4), dur, Some(vel)).unwrap()]
  let ch = @score.midi_channel_checked(0).unwrap()
  let track = @score.simple_track_checked(evts, Some(ch), None).unwrap()
  let tempo = @score.tempo_checked(120).unwrap()
  let sig = @time.time_signature(4, 4)
  let score = @score.simple_score_checked([track], tempo, sig).unwrap()
  let opts = default_musicxml_export_options()
  for i = 0; i < 50; i = i + 1 {
    let _ = simple_score_to_musicxml_checked(score, opts)
  }
}
