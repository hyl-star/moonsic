///|
pub fn bench_basic_beat(iterations : Int) -> String {
  let mut total = 0
  for i = 0; i < iterations; i = i + 1 {
    total = total + basic_beat_checked(4).unwrap().tracks.length()
  }
  "basic beat tracks: \{total}"
}
