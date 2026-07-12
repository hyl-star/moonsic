///|
test "interval_between_major_third" {
  let interval = @interval.interval_between(@pitch.c(4), @pitch.e(4))
  assert_true(interval.quality is @interval.Major)
  assert_eq(interval.number, 3)
  assert_eq(interval.semitones, 4)
}

///|
test "interval_between_perfect_fifth" {
  let interval = @interval.interval_between(@pitch.c(4), @pitch.g(4))
  assert_true(interval.quality is @interval.Perfect)
  assert_eq(interval.number, 5)
}

///|
test "parse_interval" {
  let interval = @interval.parse_interval("m7").unwrap()
  assert_true(interval.quality is @interval.Minor)
  assert_eq(interval.number, 7)
  assert_eq(interval.semitones, 10)
}

///|
test "parse_interval_err" {
  assert_true(@interval.parse_interval("x5") is Err(_))
}

///|
test "invert_interval" {
  let interval = @interval.parse_interval("M3").unwrap()
  let inv = @interval.invert_interval(interval)
  assert_true(inv.quality is @interval.Minor)
  assert_eq(inv.number, 6)
}
