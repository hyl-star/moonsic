// ============================================================
// v2 pitch 包基础测试
// ============================================================

///|
test "c4_midi_60" {
  assert_eq(c(4).to_midi(), 60)
}

///|
test "a4_midi_69" {
  assert_eq(a(4).to_midi(), 69)
}

///|
test "midi_to_pitch_60" {
  let r = midi_to_pitch_checked(60)
  assert_true(r is Ok(_))
  let p = r.unwrap()
  assert_eq(p.to_midi(), 60)
}

///|
test "midi_to_pitch_minus_1_err" {
  let r = midi_to_pitch_checked(-1)
  assert_true(r is Err(_))
}

///|
test "midi_to_pitch_128_err" {
  let r = midi_to_pitch_checked(128)
  assert_true(r is Err(_))
}

///|
test "midi_to_pitch_0" {
  let r = midi_to_pitch_checked(0)
  assert_true(r is Ok(_))
  assert_eq(r.unwrap().to_midi(), 0)
}

///|
test "midi_to_pitch_127" {
  let r = midi_to_pitch_checked(127)
  assert_true(r is Ok(_))
  assert_eq(r.unwrap().to_midi(), 127)
}

///|
test "parse_pitch_C4" {
  let r = parse_pitch("C4")
  assert_true(r is Ok(_))
  assert_eq(r.unwrap().to_midi(), 60)
}

///|
test "parse_pitch_F_sharp_3" {
  let r = parse_pitch("F#3")
  assert_true(r is Ok(_))
  assert_eq(r.unwrap().to_midi(), 54)
}

///|
test "parse_pitch_Bb5" {
  let r = parse_pitch("Bb5")
  assert_true(r is Ok(_))
  assert_eq(r.unwrap().to_midi(), 82)
}

///|
test "parse_pitch_C_negative_2_err" {
  let r = parse_pitch("C-2")
  assert_true(r is Err(_))
}

///|
test "parse_pitch_H4_err" {
  let r = parse_pitch("H4")
  assert_true(r is Err(_))
}

///|
test "parse_pitch_empty_err" {
  let r = parse_pitch("")
  assert_true(r is Err(_))
}

///|
test "parse_pitch_C10_midi_out_of_range" {
  let r = parse_pitch("C10")
  assert_true(r is Err(_))
  match r {
    Err(@pitch.PitchError::MidiOutOfRange(n)) => assert_true(n > 127)
    _ => abort("expected MidiOutOfRange")
  }
}

///|
test "parse_pitch_G9_midi_127" {
  let r = parse_pitch("G9")
  assert_true(r is Ok(_))
  assert_eq(r.unwrap().to_midi(), 127)
}

///|
test "parse_pitch_G_sharp_9_midi_128_err" {
  let r = parse_pitch("G#9")
  assert_true(r is Err(_))
}

///|
test "midi_to_pitch_checked_128_exact" {
  let r = midi_to_pitch_checked(128)
  match r {
    Err(@pitch.PitchError::MidiOutOfRange(128)) => ()
    _ => abort("expected MidiOutOfRange(128)")
  }
}

///|
test "midi_to_pitch_checked_minus_1_exact" {
  let r = midi_to_pitch_checked(-1)
  match r {
    Err(@pitch.PitchError::MidiOutOfRange(-1)) => ()
    _ => abort("expected MidiOutOfRange(-1)")
  }
}

///|
test "frequency_to_nearest_zero_exact_invalid_frequency" {
  let r = frequency_to_nearest_midi_checked(0.0)
  match r {
    Err(@pitch.PitchError::InvalidFrequency(0.0)) => ()
    _ => abort("expected InvalidFrequency(0.0)")
  }
}

///|
test "frequency_a4_440" {
  let r = pitch_to_frequency_checked(a(4))
  assert_true(r is Ok(_))
  let f = r.unwrap()
  assert_true(f > 439.0 && f < 441.0)
}

///|
test "frequency_c4" {
  let r = pitch_to_frequency_checked(c(4))
  assert_true(r is Ok(_))
  let f = r.unwrap()
  assert_true(f > 260.0 && f < 263.0)
}

///|
test "pitch_equal_same" {
  assert_true(pitch_equal(c(4), c(4)))
}

///|
test "pitch_equal_different" {
  assert_false(pitch_equal(c(4), d(4)))
}

///|
test "enharmonic_equal_cs4_db4" {
  assert_true(enharmonic_equal(cs(4), db(4)))
}

///|
test "pitch_to_string_C4" {
  assert_eq(c(4).to_string(), "C4")
}

///|
test "pitch_to_string_F_sharp_3" {
  assert_eq(fs(3).to_string(), "F#3")
}

///|
test "is_valid_midi_60" {
  assert_true(is_valid_midi_note(60))
}

///|
test "is_valid_midi_minus_1" {
  assert_false(is_valid_midi_note(-1))
}

///|
test "is_valid_midi_128" {
  assert_false(is_valid_midi_note(128))
}

///|
test "pitch_transpose_up_octave" {
  let p = c(4).transpose(12)
  assert_eq(p.to_midi(), 72)
}

///|
test "transpose_checked_ok" {
  let r = c(3).transpose_checked(12)
  assert_true(r is Ok(_))
}

///|
test "frequency_to_nearest_440" {
  let r = frequency_to_nearest_midi_checked(440.0)
  assert_true(r is Ok(_))
  assert_eq(r.unwrap(), 69)
}

///|
test "frequency_to_nearest_zero_err" {
  let r = frequency_to_nearest_midi_checked(-1.0)
  assert_true(r is Err(_))
}

///|
test "parse_pitch_class_C_sharp" {
  let r = parse_pitch_class("C#")
  assert_true(r is Ok(_))
}

///|
test "parse_pitch_class_H_err" {
  let r = parse_pitch_class("H")
  assert_true(r is Err(_))
}

///|
test "parse_pitch_class_with_octave_err" {
  let r = parse_pitch_class("C4")
  assert_true(r is Err(_))
}

///|
test "pitch_error_to_string" {
  let e = @pitch.PitchError::InvalidPitch("test")
  assert_true(e.to_string().contains("无效音高"))
}

///|
test "pitch_error_midi_out_of_range" {
  let e = @pitch.PitchError::MidiOutOfRange(128)
  assert_true(e.to_string().contains("MIDI 越界"))
}
