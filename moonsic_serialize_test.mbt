///|
test "score_to_json_basic_structure" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let score = @moonsic.score1(t)
  let json = @moonsic.score_to_json(score)
  assert_true(json.contains("\"schema\":\"moonsic.score\""))
  assert_true(json.contains("\"version\":1"))
  assert_true(json.contains("\"data\""))
  assert_true(json.contains("\"tempo\""))
  assert_true(json.contains("\"time_signature\""))
  assert_true(json.contains("\"tracks\""))
}

///|
test "score_to_json_empty_tracks" {
  let score = @moonsic.score([])
  let json = @moonsic.score_to_json(score)
  assert_true(json.contains("\"tracks\":[]"))
  assert_true(json.contains("\"bpm\":120"))
}

///|
test "score_to_json_multi_track" {
  let t1 = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let t2 = @moonsic.track_with_channel(
    [@moonsic.n(@moonsic.e(4), @moonsic.quarter())],
    1,
  )
  let score = @moonsic.score([t1, t2])
  let json = @moonsic.score_to_json(score)
  assert_true(json.contains("\"channel\":0"))
  assert_true(json.contains("\"channel\":1"))
}

///|
test "score_to_json_with_chord" {
  let evt = @moonsic.major(@moonsic.c(4), @moonsic.quarter())
  let t = @moonsic.melody([evt])
  let score = @moonsic.score1(t)
  let json = @moonsic.score_to_json(score)
  assert_true(json.contains("\"chord\""))
  assert_true(json.contains("\"pitches\""))
}

///|
test "score_to_json_with_rest" {
  let t = @moonsic.melody([
    @moonsic.r(@moonsic.quarter()),
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
  ])
  let score = @moonsic.score1(t)
  let json = @moonsic.score_to_json(score)
  assert_true(json.contains("\"rest\""))
  assert_true(json.contains("\"note\""))
}

///|
test "score_to_json_custom_tempo" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let score = @moonsic.score_with([t], 140, @moonsic.time_signature(3, 4))
  let json = @moonsic.score_to_json(score)
  assert_true(json.contains("\"bpm\":140"))
  assert_true(json.contains("\"numerator\":3"))
  assert_true(json.contains("\"denominator\":4"))
}

///|
test "track_to_json_single_note" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let json = @moonsic.track_to_json(t)
  assert_true(json.contains("\"channel\":0"))
  assert_true(json.contains("\"events\""))
  assert_true(json.contains("\"note\":\"C\""))
  assert_true(json.contains("\"octave\":4"))
}

///|
test "track_to_json_multiple_events" {
  let t = @moonsic.melody([
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.half()),
    @moonsic.r(@moonsic.quarter()),
  ])
  let json = @moonsic.track_to_json(t)
  assert_true(json.contains("\"note\"") && json.contains("\"rest\""))
}

///|
test "track_to_json_empty" {
  let t = @moonsic.track([])
  let json = @moonsic.track_to_json(t)
  assert_true(json.contains("\"events\":[]"))
}

///|
test "note_event_to_json_all_fields" {
  let e : @moonsic.NoteEvent = {
    start: 0.5,
    duration: 1.0,
    midi_note: 60,
    velocity: 100,
    channel: 0,
  }
  let json = @moonsic.note_event_to_json(e)
  assert_true(json.contains("\"start\":0.5"))
  assert_true(json.contains("\"duration\":1"))
  assert_true(json.contains("\"midi_note\":60"))
  assert_true(json.contains("\"velocity\":100"))
  assert_true(json.contains("\"channel\":0"))
}

///|
test "note_event_to_json_minimal" {
  let e : @moonsic.NoteEvent = {
    start: 0.0,
    duration: 0.25,
    midi_note: 69,
    velocity: 64,
    channel: 15,
  }
  let json = @moonsic.note_event_to_json(e)
  assert_true(json.contains("\"midi_note\":69"))
  assert_true(json.contains("\"channel\":15"))
}

///|
test "json_stringify_primitives" {
  let jv_null = @moonsic.JNull
  assert_eq(@moonsic.json_stringify(jv_null), "null")
  let jv_true = @moonsic.JBool(true)
  assert_eq(@moonsic.json_stringify(jv_true), "true")
  let jv_false = @moonsic.JBool(false)
  assert_eq(@moonsic.json_stringify(jv_false), "false")
  let jv_num = @moonsic.JNumber(42.0)
  assert_eq(@moonsic.json_stringify(jv_num), "42")
  let jv_str = @moonsic.JString("hello")
  assert_eq(@moonsic.json_stringify(jv_str), "\"hello\"")
}

///|
test "json_stringify_object_and_array" {
  let obj = @moonsic.JObject([
    @moonsic.JsonField::{ key: "a", value: @moonsic.JNumber(1.0) },
    @moonsic.JsonField::{ key: "b", value: @moonsic.JString("x") },
  ])
  let s_obj = @moonsic.json_stringify(obj)
  assert_eq(s_obj, "{\"a\":1,\"b\":\"x\"}")

  let arr = @moonsic.JArray([@moonsic.JNumber(1.0), @moonsic.JBool(true)])
  let s_arr = @moonsic.json_stringify(arr)
  assert_eq(s_arr, "[1,true]")
}

///|
test "json_stringify_newline_and_tab" {
  let jv = @moonsic.JString("line1\nline2\tindent")
  let s = @moonsic.json_stringify(jv)
  // roundtrip 验证转义正确性
  let parsed = @moonsic.json_parse(s)
  assert_true(parsed is Ok(_))
  // 验证解析后包含 "line1\nline2" 的字面量
  match parsed {
    Ok(@moonsic.JString(inner)) =>
      assert_true(inner.contains("line1") && inner.contains("line2"))
    _ => assert_true(false)
  }
}

///|
test "json_parse_object" {
  let r = @moonsic.json_parse("{\"a\":1,\"b\":true}")
  assert_true(r is Ok(_))
}

///|
test "json_parse_array" {
  let r = @moonsic.json_parse("[1,true,\"hello\"]")
  assert_true(r is Ok(_))
}

///|
test "json_parse_invalid" {
  let r = @moonsic.json_parse("{invalid}")
  assert_true(r is Err(_))
}

///|
test "json_parse_roundtrip" {
  let jv = @moonsic.JObject([
    @moonsic.JsonField::{ key: "schema", value: @moonsic.JString("test") },
    @moonsic.JsonField::{ key: "version", value: @moonsic.JNumber(1.0) },
  ])
  let json_str = @moonsic.json_stringify(jv)
  let parsed = @moonsic.json_parse(json_str).unwrap()
  let back = @moonsic.json_stringify(parsed)
  assert_eq(json_str, back)
}

///|
test "json_parse_empty_string_err" {
  let r = @moonsic.json_parse("")
  assert_true(r is Err(_))
}

///|
test "score_from_json_string_roundtrip" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let score = @moonsic.score1(t)
  let json = @moonsic.score_to_json(score)
  let r = @moonsic.score_from_json_string(json)
  assert_true(r is Ok(_))
  let s2 = r.unwrap()
  assert_eq(s2.track_count(), 1)
  assert_eq(s2.tracks[0].event_count(), 1)
  assert_eq(s2.tempo.bpm, 120)
}

///|
test "score_from_json_string_invalid_schema" {
  let json = "{\"schema\":\"other.v1\",\"version\":1,\"data\":{}}"
  let r = @moonsic.score_from_json_string(json)
  assert_true(r is Err(@moonsic.JsonDecodeError(_)))
}

///|
test "score_from_json_string_unsupported_version" {
  let json = "{\"schema\":\"moonsic.score\",\"version\":99,\"data\":{}}"
  let r = @moonsic.score_from_json_string(json)
  assert_true(r is Err(@moonsic.JsonDecodeError(_)))
}

///|
test "score_from_json_string_invalid_json_error_variant" {
  let r = @moonsic.score_from_json_string("{")
  assert_true(r is Err(@moonsic.JsonParseError(_)))
}

///|
test "json_parse_number_exponent" {
  let r = @moonsic.json_parse("1.25e2")
  assert_true(r is Ok(@moonsic.JNumber(125.0)))
}

///|
test "score_from_json_string_roundtrip_with_chord" {
  let t = @moonsic.melody([@moonsic.major(@moonsic.c(4), @moonsic.half())])
  let score = @moonsic.score1(t)
  let json = @moonsic.score_to_json(score)
  let r = @moonsic.score_from_json_string(json)
  assert_true(r is Ok(_))
  let s2 = r.unwrap()
  assert_eq(s2.track_count(), 1)
  assert_eq(s2.tracks[0].event_count(), 1)
}

///|
test "score_from_json_string_empty" {
  let score = @moonsic.score([])
  let json = @moonsic.score_to_json(score)
  let r = @moonsic.score_from_json_string(json)
  assert_true(r is Ok(_))
  let s2 = r.unwrap()
  assert_eq(s2.track_count(), 0)
}

///|
test "score_from_json_string_multi_track" {
  let t1 = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let t2 = @moonsic.track_with_channel(
    [@moonsic.n(@moonsic.e(4), @moonsic.half())],
    2,
  )
  let score = @moonsic.score([t1, t2])
  let json = @moonsic.score_to_json(score)
  let r = @moonsic.score_from_json_string(json)
  assert_true(r is Ok(_))
  let s2 = r.unwrap()
  assert_eq(s2.track_count(), 2)
}

///|
test "parse_to_json_pitch" {
  let json = @moonsic.parse_to_json("C4", "pitch")
  assert_true(json.contains("\"ok\":true"))
  assert_true(json.contains("\"note\":\"C\""))
  assert_true(json.contains("\"octave\":4"))
}

///|
test "parse_to_json_chord" {
  let json = @moonsic.parse_to_json("Cm7", "chord")
  assert_true(json.contains("\"ok\":true"))
  assert_true(json.contains("\"pitches\""))
}

///|
test "parse_to_json_interval" {
  let json = @moonsic.parse_to_json("M3", "interval")
  assert_true(json.contains("\"ok\":true"))
  assert_true(json.contains("\"M\""))
  assert_true(json.contains("\"semitones\":4"))
}

///|
test "parse_to_json_error" {
  let json = @moonsic.parse_to_json("H#13", "pitch")
  assert_true(json.contains("\"ok\":false"))
}

///|
test "parse_to_json_unsupported_kind" {
  let json = @moonsic.parse_to_json("test", "unknown")
  assert_true(json.contains("\"ok\":false"))
  assert_true(json.contains("\"error\":\"UnsupportedKind\""))
  assert_true(json.contains("\"message\""))
}

///|
test "pitch_to_json_string_C4" {
  let p = @moonsic.pitch(@moonsic.C, @moonsic.Natural, 4)
  let json = @moonsic.pitch_to_json_string(p)
  assert_true(json.contains("\"note\":\"C\""))
  assert_true(json.contains("\"octave\":4"))
}

///|
test "duration_to_json_string_quarter" {
  let json = @moonsic.duration_to_json_string(@moonsic.Quarter)
  assert_true(json.contains("\"kind\":\"quarter\""))
}

///|
test "duration_to_json_string_dotted" {
  let json = @moonsic.duration_to_json_string(@moonsic.dotted(@moonsic.Half))
  assert_true(json.contains("\"kind\":\"half\""))
  assert_true(json.contains("\"dots\":1"))
}

///|
test "json_stringify_empty_object" {
  let jv = @moonsic.JObject([])
  assert_eq(@moonsic.json_stringify(jv), "{}")
}

///|
test "json_stringify_empty_array" {
  let jv = @moonsic.JArray([])
  assert_eq(@moonsic.json_stringify(jv), "[]")
}

///|
test "json_parse_nested_object" {
  let r = @moonsic.json_parse("{\"a\":{\"b\":[1,2]}}")
  assert_true(r is Ok(_))
}

///|
test "json_parse_decimal_number" {
  let r = @moonsic.json_parse("3.14")
  assert_true(r is Ok(_))
}

///|
test "json_parse_negative_number" {
  let r = @moonsic.json_parse("-42")
  assert_true(r is Ok(_))
}

///|
test "chord_to_json_string_C_major" {
  let c = @moonsic.chord(
    [
      @moonsic.pitch(@moonsic.C, @moonsic.Natural, 4),
      @moonsic.pitch(@moonsic.E, @moonsic.Natural, 4),
      @moonsic.pitch(@moonsic.G, @moonsic.Natural, 4),
    ],
    @moonsic.Quarter,
  )
  let json = @moonsic.chord_to_json_string(c)
  assert_true(json.contains("\"pitches\""))
  assert_true(json.contains("\"velocity\":100"))
}

///|
test "json_parse_trailing_garbage_err" {
  let r = @moonsic.json_parse("42 {}")
  assert_true(r is Err(_))
}

///|
test "parse_chord_trailing_suffix_err" {
  let r = @moonsic.parse_chord("Cgarbage")
  assert_true(r is Err(_))
}

///|
test "midi_to_pitch_checked_boundaries" {
  assert_true(@moonsic.midi_to_pitch_checked(-1) is Err(_))
  assert_true(@moonsic.midi_to_pitch_checked(128) is Err(_))
  assert_eq(@moonsic.midi_to_pitch_checked(127).unwrap().to_midi(), 127)
}

///|
test "build_scale_spelled_F_sharp_major" {
  let s = @moonsic.build_scale_spelled(
    @moonsic.F,
    @moonsic.Sharp,
    @moonsic.Major,
  )
  assert_eq(s.root.to_string(), "F")
  assert_eq(s.root_accidental.to_string(), "#")
  assert_eq(s.spelled_tones.length(), 7)
  assert_eq(s.spelled_tones[0].to_string(), "F#4")
  assert_eq(s.spelled_tones[1].to_string(), "G#4")
  assert_eq(s.spelled_tones[6].to_string(), "E#5")
}

///|
test "rhythm_duration_to_fraction_checked_invalid_dots" {
  let d = @moonsic.RhythmDuration::{
    unit: @moonsic.DurQuarter,
    dots: 4,
    tuplet: None,
  }
  assert_true(@moonsic.rhythm_duration_to_fraction_checked(d) is Err(_))
  assert_true(@moonsic.rhythm_duration_to_ticks(d, 480) is Err(_))
}

///|
test "json_stringify_escapes_string_content" {
  let json = @moonsic.json_stringify(@moonsic.JString("a\"b\\c\n"))
  assert_eq(json, "\"a\\\"b\\\\c\\n\"")
  let parsed = @moonsic.json_parse(json).unwrap()
  assert_true(parsed is @moonsic.JString(_))
}

///|
test "to_midi_bytes_with_ppq_checked_invalid_ppq" {
  let s = @moonsic.score1(@moonsic.melody([]))
  let r = s.to_midi_bytes_with_ppq_checked(0)
  assert_true(r is Err(_))
}

///|
test "parse_scale_trailing_suffix_err" {
  let r = @moonsic.parse_scale("C majorxxx")
  assert_true(r is Err(@moonsic.InvalidScale(_)))
}

///|
test "degree_checked_rejects_non_positive_degree" {
  let root = @moonsic.pitch(@moonsic.C, @moonsic.Natural, 4)
  let r = @moonsic.degree_checked(root, @moonsic.Major, 0)
  assert_true(r is Err(@moonsic.InvalidInterval(_)))
}

///|
test "midi_event_constructors_return_specific_error" {
  let r = @moonsic.note_on(0, 16, 60, 64)
  assert_true(r is Err(@moonsic.InvalidMidiChannel(16)))
  let r2 = @moonsic.note_off(0, 0, 128, 64)
  assert_true(r2 is Err(@moonsic.InvalidMidiNote(128)))
}

///|
test "parse_to_json_error_escapes_message" {
  let json = @moonsic.parse_to_json("X\"4", "pitch")
  assert_true(json.contains("\"ok\":false"))
  assert_true(json.contains("\"error\":\"InvalidPitch\""))
  assert_true(json.contains("\\\""))
  let parsed = @moonsic.json_parse(json)
  assert_true(parsed is Ok(_))
}

///|
test "ffi_error_json_has_message_and_is_parseable" {
  let json = @moonsic.ffi_parse_pitch_to_midi("X\"4")
  assert_true(json.contains("\"error\":\"InvalidPitch\""))
  assert_true(json.contains("\"message\""))
  assert_true(json.contains("\\\""))
  assert_true(@moonsic.json_parse(json) is Ok(_))
}

///|
test "parse_pitch_supports_midi_zero_spelling" {
  let p = @moonsic.parse_pitch("C-1").unwrap()
  assert_eq(p.to_midi(), 0)
}

///|
test "parse_pitch_rejects_below_midi_zero" {
  let r = @moonsic.parse_pitch("Cb-1")
  assert_true(r is Err(@moonsic.MidiOutOfRange(_)))
}

///|
test "strict_time_ffi_json_inputs" {
  let ticks = @moonsic.ffi_duration_ticks_json(
    "{\"duration\":\"q\",\"ppq\":480}",
  )
  assert_true(ticks.contains("\"ok\":true"))
  assert_true(ticks.contains("\"ticks\":480"))
  let seconds = @moonsic.ffi_ticks_to_seconds_json(
    "{\"ticks\":480,\"bpm\":120.0,\"ppq\":480}",
  )
  assert_true(seconds.contains("\"ok\":true"))
  assert_true(seconds.contains("\"seconds\":0.5"))
  let bar = @moonsic.ffi_bar_length_json("{\"sig\":\"4/4\",\"ppq\":480}")
  assert_true(bar.contains("\"ok\":true"))
  assert_true(bar.contains("\"ticks\":1920"))
}

///|
test "strict_time_ffi_json_error_is_parseable" {
  let json = @moonsic.ffi_duration_ticks_json(
    "{\"duration\":\"x\",\"ppq\":480}",
  )
  assert_true(json.contains("\"ok\":false"))
  assert_true(json.contains("\"message\""))
  assert_true(@moonsic.json_parse(json) is Ok(_))
}
