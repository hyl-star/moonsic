///|
fn rhythm() -> @rhythm.RhythmPattern {
  @rhythm.rhythm_template(@rhythm.FourQuarters)
}

///|
test "motif_checked" {
  let motif = @motif.motif_checked([1, 2, 3, 4], rhythm()).unwrap()
  assert_eq(motif.events.length(), 4)
  assert_eq(motif.total_beats, 4.0)
}

///|
test "motif_length_mismatch" {
  assert_true(@motif.motif_checked([1, 2], rhythm()) is Err(_))
}

///|
test "motif_transpose" {
  let m = @motif.motif_checked([1, 2, 3, 4], rhythm()).unwrap()
  let shifted = @motif.transform_motif_checked(m, @motif.TransposeDegrees(1)).unwrap()
  assert_eq(shifted.events[0].degree, 2)
}

///|
test "motif_retrograde" {
  let m = @motif.motif_checked([1, 2, 3, 4], rhythm()).unwrap()
  let reversed = @motif.transform_motif_checked(m, @motif.Retrograde).unwrap()
  assert_eq(reversed.events[0].degree, 4)
}

///|
test "motif_to_track" {
  let m = @motif.motif_checked([1, 2, 3, 4], rhythm()).unwrap()
  let track = @motif.motif_to_track_checked(
    m,
    @scale.key(@pitch.c(4), @scale.Major),
    4,
  ).unwrap()
  assert_eq(track.events.length(), 4)
}

///|
test "motif_variation_repeat" {
  let m = @motif.motif_checked([1, 2, 3, 4], rhythm()).unwrap()
  let varied = @motif.vary_motif_checked(m, @motif.ExactRepeat).unwrap()
  assert_eq(varied.events.length(), 8)
}
