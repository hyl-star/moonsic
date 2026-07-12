///|
pub fn bench_motif_transpose(iterations : Int) -> String {
  let m = motif_checked(
    [1, 2, 3, 4],
    @rhythm.rhythm_template(@rhythm.FourQuarters),
  ).unwrap()
  let mut total = 0
  for i = 0; i < iterations; i = i + 1 {
    total = total +
      transform_motif_checked(m, TransposeDegrees(1)).unwrap().events.length()
  }
  "motif events: \{total}"
}
