///|
pub fn bench_interval_between(iterations : Int) -> String {
  let mut total = 0
  for i = 0; i < iterations; i = i + 1 {
    total = total + interval_between(@pitch.c(4), @pitch.g(4)).semitones
  }
  "interval semitones: \{total}"
}
