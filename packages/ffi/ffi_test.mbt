///|
test "ffi_parse_to_json" {
  let out = @ffi.ffi_parse_to_json("C4", "pitch")
  assert_true(out.contains("\"ok\":true"))
  assert_true(out.contains("\"midi\":60"))
}

///|
test "ffi_generate_melody_json" {
  let out = @ffi.ffi_generate_melody_json(
    "{\"scale\":\"C major\",\"rhythm_kind\":\"FourQuarters\",\"tempo\":120}",
  )
  assert_true(out.contains("\"ok\":true"))
  assert_true(out.contains("\"tracks\""))
}

///|
test "ffi_generate_game_loop_json" {
  let out = @ffi.ffi_generate_game_loop_json(
    "{\"scale\":\"C major\",\"progression\":[1,5,6,4],\"bars\":1}",
  )
  assert_true(out.contains("\"ok\":true"))
  assert_true(out.contains("\"tracks\""))
}

///|
test "ffi_simple_score_exports" {
  let generated = @ffi.ffi_generate_melody_json(
    "{\"scale\":\"C major\",\"rhythm_kind\":\"FourQuarters\"}",
  )
  let root = @json.json_parse(generated).unwrap()
  let fields = @json.json_as_object(root).unwrap()
  let score_json = @json.json_stringify(
    @json.json_lookup(fields, "data").unwrap(),
  )
  let xml_out = @ffi.ffi_simple_score_to_musicxml_json(score_json)
  assert_true(xml_out.contains("\"ok\":true"))
  assert_true(xml_out.contains("score-partwise"))
  let midi_out = @ffi.ffi_simple_score_to_midi_json(score_json)
  assert_true(midi_out.contains("\"byte_length\""))
}
