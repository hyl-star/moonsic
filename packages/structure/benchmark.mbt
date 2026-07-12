///|
pub fn bench_arrange(iterations : Int) -> String {
  let event = @score.simple_rest_checked(
    @time.rhythm_duration(@time.DurQuarter, 0, None),
  ).unwrap()
  let track = @score.simple_track_checked([event], None, None).unwrap()
  let sec = section("bench", [track]).unwrap()
  let mut total = 0
  for i = 0; i < iterations; i = i + 1 {
    total = total +
      arrange_checked(
        [sec, sec],
        @score.tempo_checked(120).unwrap(),
        @time.time_signature(4, 4),
      ).unwrap().tracks[0].events.length()
  }
  "arranged events: \{total}"
}
