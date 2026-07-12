///|
pub fn bench_transform_reverse(iterations : Int) -> String {
  let note = @score.simple_note_checked(
    @pitch.c(4),
    @time.rhythm_duration(@time.DurQuarter, 0, None),
    None,
  ).unwrap()
  let track = @score.simple_track_checked([note, note, note, note], None, None).unwrap()
  let mut total = 0
  for i = 0; i < iterations; i = i + 1 {
    total = total + simple_track_reverse(track).events.length()
  }
  "reverse events: \{total}"
}
