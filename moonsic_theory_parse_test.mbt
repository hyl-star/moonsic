///|
test "accidental_double_flat_offset" {
  assert_eq(@moonsic.DoubleFlat.semitone_offset(), -2)
}

///|
test "accidental_double_sharp_offset" {
  assert_eq(@moonsic.DoubleSharp.semitone_offset(), 2)
}

///|
test "scale_dorian_c" {
  let s = @moonsic.scale(@moonsic.c(4), @moonsic.Dorian, 1)
  assert_eq(s.length(), 7)
  // C Dorian: C D Eb F G A Bb
  assert_eq(s[0].to_midi(), 60) // C
  assert_eq(s[1].to_midi(), 62) // D
  assert_eq(s[2].to_midi(), 63) // Eb
  assert_eq(s[3].to_midi(), 65) // F
  assert_eq(s[4].to_midi(), 67) // G
  assert_eq(s[5].to_midi(), 69) // A
  assert_eq(s[6].to_midi(), 70) // Bb
}

///|
test "scale_chromatic_c" {
  let s = @moonsic.scale(@moonsic.c(4), @moonsic.Chromatic, 1)
  assert_eq(s.length(), 12)
}

///|
test "chord_half_dim7" {
  let evt = @moonsic.chord_quality(
    @moonsic.b(3),
    @moonsic.HalfDiminished7,
    @moonsic.half(),
  )
  let track = @moonsic.melody([evt])
  let events = track.to_note_events()
  // B half-dim7 = B D F A
  assert_eq(events.length(), 4)
  assert_eq(events[0].midi_note, 59) // B
  assert_eq(events[1].midi_note, 62) // D
  assert_eq(events[2].midi_note, 65) // F
  assert_eq(events[3].midi_note, 69) // A
}

///|
test "chord_sus4" {
  let evt = @moonsic.chord_quality(
    @moonsic.c(4),
    @moonsic.Suspended4,
    @moonsic.quarter(),
  )
  let track = @moonsic.melody([evt])
  let events = track.to_note_events()
  // C sus4 = C F G
  assert_eq(events.length(), 3)
  assert_eq(events[0].midi_note, 60) // C
  assert_eq(events[1].midi_note, 65) // F
  assert_eq(events[2].midi_note, 67) // G
}

// --- interval / scale / chord parse tests ---

///|
test "interval_between_major_third" {
  let iv = @moonsic.interval_between(@moonsic.c(4), @moonsic.e(4))
  assert_eq(iv.number, 3)
  assert_eq(iv.semitones, 4)
  assert_eq(iv.quality.to_string(), "M")
}

///|
test "interval_between_perfect_fifth" {
  let iv = @moonsic.interval_between(@moonsic.c(4), @moonsic.g(4))
  assert_eq(iv.number, 5)
  assert_eq(iv.semitones, 7)
  assert_eq(iv.quality.to_string(), "P")
}

///|
test "interval_between_minor_second" {
  let iv = @moonsic.interval_between(@moonsic.e(4), @moonsic.f(4))
  assert_eq(iv.number, 2)
  assert_eq(iv.semitones, 1)
  assert_eq(iv.quality.to_string(), "m")
}

///|
test "interval_between_unison" {
  let iv = @moonsic.interval_between(@moonsic.c(4), @moonsic.c(4))
  assert_eq(iv.number, 1)
  assert_eq(iv.semitones, 0)
  assert_eq(iv.quality.to_string(), "P")
}

///|
test "interval_between_octave" {
  let iv = @moonsic.interval_between(@moonsic.c(4), @moonsic.c(5))
  assert_eq(iv.number, 8)
  assert_eq(iv.semitones, 12)
  assert_eq(iv.quality.to_string(), "P")
}

///|
test "invert_interval_major_to_minor" {
  let iv = @moonsic.parse_interval("M3").unwrap()
  let inv = @moonsic.invert_interval(iv)
  assert_eq(inv.quality.to_string(), "m")
  assert_eq(inv.number, 6)
  assert_eq(inv.semitones, 8)
}

///|
test "invert_interval_perfect_stays" {
  let iv = @moonsic.parse_interval("P5").unwrap()
  let inv = @moonsic.invert_interval(iv)
  assert_eq(inv.quality.to_string(), "P")
  assert_eq(inv.number, 4)
  assert_eq(inv.semitones, 5)
}

///|
test "parse_interval_M3" {
  let r = @moonsic.parse_interval("M3")
  let iv = r.unwrap()
  assert_eq(iv.quality.to_string(), "M")
  assert_eq(iv.number, 3)
  assert_eq(iv.semitones, 4)
}

///|
test "parse_interval_P5" {
  let r = @moonsic.parse_interval("P5")
  let iv = r.unwrap()
  assert_eq(iv.quality.to_string(), "P")
  assert_eq(iv.number, 5)
  assert_eq(iv.semitones, 7)
}

///|
test "parse_interval_m7" {
  let r = @moonsic.parse_interval("m7")
  let iv = r.unwrap()
  assert_eq(iv.quality.to_string(), "m")
  assert_eq(iv.number, 7)
  assert_eq(iv.semitones, 10)
}

///|
test "parse_interval_A4" {
  let r = @moonsic.parse_interval("A4")
  let iv = r.unwrap()
  assert_eq(iv.quality.to_string(), "A")
  assert_eq(iv.number, 4)
  assert_eq(iv.semitones, 6)
}

///|
test "parse_interval_d5" {
  let r = @moonsic.parse_interval("d5")
  let iv = r.unwrap()
  assert_eq(iv.quality.to_string(), "d")
  assert_eq(iv.number, 5)
  assert_eq(iv.semitones, 6)
}

///|
test "parse_interval_invalid" {
  let r = @moonsic.parse_interval("X3")
  assert_true(r is Err(_))
}

///|
test "parse_chord_Cmaj" {
  let r = @moonsic.parse_chord("C")
  let chord = r.unwrap()
  let tones = @moonsic.chord_tones(chord)
  assert_eq(tones.length(), 3)
  assert_eq(tones[0].to_string(), "C")
  assert_eq(tones[1].to_string(), "E")
  assert_eq(tones[2].to_string(), "G")
}

///|
test "parse_chord_Cm" {
  let r = @moonsic.parse_chord("Cm")
  let chord = r.unwrap()
  let tones = @moonsic.chord_tones(chord)
  assert_eq(tones.length(), 3)
  assert_eq(tones[0].to_string(), "C")
  assert_eq(tones[1].to_string(), "E")
  assert_eq(tones[2].to_string(), "G")
}

///|
test "parse_chord_Cm7" {
  let r = @moonsic.parse_chord("Cm7")
  let chord = r.unwrap()
  let tones = @moonsic.chord_tones(chord)
  assert_eq(tones.length(), 4)
  assert_eq(tones[0].to_string(), "C")
  assert_eq(tones[1].to_string(), "E")
  assert_eq(tones[2].to_string(), "G")
  assert_eq(tones[3].to_string(), "B")
}

///|
test "parse_chord_G7" {
  let r = @moonsic.parse_chord("G7")
  let chord = r.unwrap()
  let tones = @moonsic.chord_tones(chord)
  assert_eq(tones.length(), 4)
  assert_eq(tones[0].to_string(), "G")
  assert_eq(tones[1].to_string(), "B")
  assert_eq(tones[2].to_string(), "D")
  assert_eq(tones[3].to_string(), "F")
}

///|
test "parse_chord_invalid" {
  let r = @moonsic.parse_chord("H")
  assert_true(r is Err(_))
}

///|
test "chord_tones_Cmaj7" {
  let r = @moonsic.parse_chord("Cmaj7")
  let chord = r.unwrap()
  let tones = @moonsic.chord_tones(chord)
  assert_eq(tones.length(), 4)
  assert_eq(tones[0].to_string(), "C")
  assert_eq(tones[1].to_string(), "E")
  assert_eq(tones[2].to_string(), "G")
  assert_eq(tones[3].to_string(), "B")
}

///|
test "parse_scale_C_major" {
  let r = @moonsic.parse_scale("C major")
  let scale = r.unwrap()
  assert_eq(scale.tones.length(), 7)
  assert_eq(scale.root.to_string(), "C")
  assert_eq(scale.tones[0].to_string(), "C")
  assert_eq(scale.tones[1].to_string(), "D")
  assert_eq(scale.tones[2].to_string(), "E")
  assert_eq(scale.tones[3].to_string(), "F")
  assert_eq(scale.tones[4].to_string(), "G")
  assert_eq(scale.tones[5].to_string(), "A")
  assert_eq(scale.tones[6].to_string(), "B")
}

///|
test "parse_scale_A_minor" {
  let r = @moonsic.parse_scale("A minor")
  let scale = r.unwrap()
  assert_eq(scale.tones.length(), 7)
  assert_eq(scale.root.to_string(), "A")
  assert_eq(scale.tones[0].to_string(), "A")
  assert_eq(scale.tones[1].to_string(), "B")
  assert_eq(scale.tones[2].to_string(), "C")
  assert_eq(scale.tones[3].to_string(), "D")
  assert_eq(scale.tones[4].to_string(), "E")
  assert_eq(scale.tones[5].to_string(), "F")
  assert_eq(scale.tones[6].to_string(), "G")
}

///|
test "parse_scale_D_dorian" {
  let r = @moonsic.parse_scale("D dorian")
  let scale = r.unwrap()
  assert_eq(scale.tones.length(), 7)
  assert_eq(scale.root.to_string(), "D")
  assert_eq(scale.tones[0].to_string(), "D")
  assert_eq(scale.tones[1].to_string(), "E")
  assert_eq(scale.tones[2].to_string(), "F")
  assert_eq(scale.tones[3].to_string(), "G")
  assert_eq(scale.tones[4].to_string(), "A")
  assert_eq(scale.tones[5].to_string(), "B")
  assert_eq(scale.tones[6].to_string(), "C")
}

///|
test "parse_scale_invalid" {
  let r = @moonsic.parse_scale("X lydian")
  assert_true(r is Err(_))
}

///|
test "build_scale_F_major" {
  let scale = @moonsic.build_scale(@moonsic.F, @moonsic.Major)
  assert_eq(scale.tones.length(), 7)
  assert_eq(scale.root.to_string(), "F")
  assert_eq(scale.tones[0].to_string(), "F")
  assert_eq(scale.tones[1].to_string(), "G")
  assert_eq(scale.tones[2].to_string(), "A")
  assert_eq(scale.tones[3].to_string(), "B")
  assert_eq(scale.tones[4].to_string(), "C")
  assert_eq(scale.tones[5].to_string(), "D")
  assert_eq(scale.tones[6].to_string(), "E")
}

///|
test "theory_error_to_string_InvalidPitch" {
  let e = @moonsic.InvalidPitch("bad")
  assert_true(e.to_string().contains("无效音高"))
}

///|
test "theory_error_to_string_ParseError" {
  let e = @moonsic.ParseError("oops")
  assert_true(e.to_string().contains("解析错误"))
}

///|
test "parse_chord_F_sharp_dim" {
  let r = @moonsic.parse_chord("F#dim")
  let chord = r.unwrap()
  let tones = @moonsic.chord_tones(chord)
  assert_eq(tones.length(), 3)
  assert_eq(tones[0].to_string(), "F")
  assert_eq(tones[1].to_string(), "A")
  assert_eq(tones[2].to_string(), "C")
}

///|
test "parse_chord_Dm7" {
  let r = @moonsic.parse_chord("Dm7")
  let chord = r.unwrap()
  let tones = @moonsic.chord_tones(chord)
  assert_eq(tones.length(), 4)
  assert_eq(tones[0].to_string(), "D")
  assert_eq(tones[1].to_string(), "F")
  assert_eq(tones[2].to_string(), "A")
  assert_eq(tones[3].to_string(), "C")
}

// ============================================================
// parse_pitch / parse_pitch_class / FFI JSON 测试
// ============================================================

///|
test "parse_pitch_C4_ok" {
  let r = @moonsic.parse_pitch("C4")
  assert_true(r is Ok(_))
  let p = r.unwrap()
  assert_eq(p.to_midi(), 60)
  assert_eq(p.to_string(), "C4")
}

///|
test "parse_pitch_F_sharp_3_ok" {
  let r = @moonsic.parse_pitch("F#3")
  assert_true(r is Ok(_))
  let p = r.unwrap()
  assert_eq(p.to_midi(), 54)
}

///|
test "parse_pitch_Bb5_ok" {
  let r = @moonsic.parse_pitch("Bb5")
  assert_true(r is Ok(_))
  let p = r.unwrap()
  assert_eq(p.to_midi(), 82)
}

///|
test "parse_pitch_H_sharp_13_err" {
  let r = @moonsic.parse_pitch("H#13")
  assert_true(r is Err(_))
}

///|
test "parse_pitch_empty_err" {
  let r = @moonsic.parse_pitch("")
  assert_true(r is Err(_))
}

///|
test "parse_pitch_invalid_note_err" {
  let r = @moonsic.parse_pitch("X9")
  assert_true(r is Err(_))
}

///|
test "parse_pitch_class_C_sharp_ok" {
  let r = @moonsic.parse_pitch_class("C#")
  assert_true(r is Ok(_))
  let pc = r.unwrap()
  // PitchClass "C#" = C (accidental not stored in PitchClass)
  assert_eq(pc.base_semitone(), 0)
}

///|
test "parse_pitch_class_H_err" {
  let r = @moonsic.parse_pitch_class("H")
  assert_true(r is Err(_))
}

///|
test "parse_pitch_class_C_ok" {
  let r = @moonsic.parse_pitch_class("C")
  assert_true(r is Ok(_))
  assert_eq(r.unwrap().base_semitone(), 0)
}

///|
test "parse_pitch_class_Db_ok" {
  let r = @moonsic.parse_pitch_class("Db")
  assert_true(r is Ok(_))
  // "Db" → PitchClass D
  assert_eq(r.unwrap().base_semitone(), 2)
}

///|
test "parse_pitch_class_empty_err" {
  let r = @moonsic.parse_pitch_class("")
  assert_true(r is Err(_))
}

///|
test "parse_pitch_class_with_octave_err" {
  let r = @moonsic.parse_pitch_class("C4")
  assert_true(r is Err(_))
}

///|
test "ffi_parse_pitch_to_midi_C4" {
  let json = @moonsic.ffi_parse_pitch_to_midi("C4")
  assert_true(json.contains("60"))
  assert_true(json.contains("true"))
}

///|
test "ffi_parse_pitch_to_midi_X9_error" {
  let json = @moonsic.ffi_parse_pitch_to_midi("X9")
  assert_true(json.contains("error"))
  assert_true(json.contains("false"))
}

///|
test "ffi_parse_chord_tones_Cm7" {
  let json = @moonsic.ffi_parse_chord_tones("Cm7")
  assert_true(json.contains("Eb"))
  assert_true(json.contains("true"))
}

///|
test "ffi_parse_chord_tones_invalid" {
  let json = @moonsic.ffi_parse_chord_tones("H#dim")
  assert_true(json.contains("error"))
}

///|
test "ffi_build_scale_C_major" {
  let json = @moonsic.ffi_build_scale("C major")
  assert_true(json.contains("\"C\""))
  assert_true(json.contains("\"D\""))
  assert_true(json.contains("\"E\""))
  assert_true(json.contains("true"))
}

///|
test "ffi_build_scale_invalid" {
  let json = @moonsic.ffi_build_scale("X blarg")
  assert_true(json.contains("error"))
}

///|
test "parse_pitch_multi_octave_C10" {
  let r = @moonsic.parse_pitch("C10")
  assert_true(r is Ok(_))
  let p = r.unwrap()
  assert_eq(p.to_midi(), 132)
}

///|
test "parse_pitch_class_double_accidental_err" {
  let r = @moonsic.parse_pitch_class("C##")
  assert_true(r is Err(_))
}

// ============================================================
// 节奏与时间模块测试 — Rational + DurUnit + 换算 + 解析
// ============================================================

// --- Rational 基础 ---
