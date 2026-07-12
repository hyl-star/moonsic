///|
test "parse_pitch_json" {
  let json = @parse.parse_to_json("C4", "pitch")
  assert_true(json.contains("\"ok\":true"))
  assert_true(json.contains("\"midi\":60"))
}

///|
test "parse_chord_json" {
  let json = @parse.parse_to_json("Cm", "chord")
  assert_true(json.contains("\"pitches\""))
}

///|
test "parse_scale_json" {
  let json = @parse.parse_to_json("C major", "scale")
  assert_true(json.contains("\"tones\""))
}

///|
test "parse_interval_json" {
  let json = @parse.parse_to_json("P5", "interval")
  assert_true(json.contains("\"semitones\":7"))
}

///|
test "parse_error_json" {
  let json = @parse.parse_to_json("bad", "pitch")
  assert_true(json.contains("\"ok\":false"))
}
