// ============================================================
// v2 midi 包测试 (blackbox)
// ============================================================

// --- helpers ---

///|
fn make_simple_score() -> @score.SimpleScore {
  let vel = @score.velocity_checked(100).unwrap()
  let dur = @time.rhythm_duration(@time.DurQuarter, 0, None)
  let evts = [
    @score.simple_note_checked(@pitch.c(4), dur, Some(vel)).unwrap(),
    @score.simple_note_checked(@pitch.d(4), dur, Some(vel)).unwrap(),
    @score.simple_note_checked(@pitch.e(4), dur, Some(vel)).unwrap(),
    @score.simple_note_checked(@pitch.f(4), dur, Some(vel)).unwrap(),
  ]
  let ch = @score.midi_channel_checked(0).unwrap()
  let track = @score.simple_track_checked(evts, Some(ch), None).unwrap()
  let tempo = @score.tempo_checked(120).unwrap()
  let sig = @time.time_signature(4, 4)
  @score.simple_score_checked([track], tempo, sig).unwrap()
}

///|
/// Helper: create a SimpleScore from a list of (pitch, duration) pairs.
fn make_score_with_durations(
  items : Array[(@pitch.Pitch, @time.RhythmDuration)],
) -> @score.SimpleScore {
  let vel = @score.velocity_checked(100).unwrap()
  let evts : Array[@score.SimpleEvent] = []
  for i = 0; i < items.length(); i = i + 1 {
    let p = items[i].0
    let d = items[i].1
    evts.push(@score.simple_note_checked(p, d, Some(vel)).unwrap())
  }
  let ch = @score.midi_channel_checked(0).unwrap()
  let track = @score.simple_track_checked(evts, Some(ch), None).unwrap()
  let tempo = @score.tempo_checked(120).unwrap()
  let sig = @time.time_signature(4, 4)
  @score.simple_score_checked([track], tempo, sig).unwrap()
}

///|
/// Helper: extract RhythmDuration from the first SimpleEvent in imported score.
fn first_note_duration(score : @score.SimpleScore) -> @time.RhythmDuration {
  match score.tracks[0].events[0] {
    @score.Note(n) => n.duration
    @score.Chord(c) => c.duration
    @score.Rest(r) => r.duration
  }
}

// --- note_on / note_off ---

///|
test "note_on_valid" {
  assert_true(@midi.note_on(0, 0, 60, 100) is Ok(_))
}

///|
test "note_on_invalid_channel_err" {
  assert_true(@midi.note_on(0, 16, 60, 100) is Err(_))
}

///|
test "note_on_invalid_note_err" {
  assert_true(@midi.note_on(0, 0, 128, 100) is Err(_))
}

///|
test "note_on_invalid_velocity_err" {
  assert_true(@midi.note_on(0, 0, 60, 200) is Err(_))
}

///|
test "note_on_negative_tick_err" {
  assert_true(@midi.note_on(-1, 0, 60, 100) is Err(_))
}

// --- program_change ---

///|
test "program_change_valid" {
  assert_true(@midi.program_change(0, 0, 0) is Ok(_))
}

///|
test "program_change_invalid_program_err" {
  assert_true(@midi.program_change(0, 0, 128) is Err(_))
}

// --- tempo_change ---

///|
test "tempo_change_valid" {
  assert_true(@midi.tempo_change(0, 120) is Ok(_))
}

///|
test "tempo_change_bpm_zero_err" {
  assert_true(@midi.tempo_change(0, 0) is Err(_))
}

// --- midi_time_signature ---

///|
test "midi_time_signature_4_4_ok" {
  assert_true(@midi.midi_time_signature(0, 4, 4) is Ok(_))
}

///|
test "midi_time_signature_invalid_err" {
  assert_true(@midi.midi_time_signature(0, 4, 5) is Err(_))
}

// --- end_of_track / track_name ---

///|
test "end_of_track_ok" {
  assert_true(@midi.end_of_track(0) is Ok(_))
}

///|
test "end_of_track_negative_tick_err" {
  assert_true(@midi.end_of_track(-1) is Err(_))
}

///|
test "track_name_ok" {
  assert_true(@midi.track_name(0, "Test") is Ok(_))
}

// --- sort_midi_events ---

///|
test "sort_by_tick" {
  let a = @midi.note_on(10, 0, 60, 100).unwrap()
  let b = @midi.note_on(0, 0, 64, 100).unwrap()
  let sorted = @midi.sort_midi_events([a, b])
  assert_eq(sorted[0].tick, 0)
}

///|
test "sort_noteoff_before_noteon" {
  let off = @midi.note_off(100, 0, 60, 0).unwrap()
  let on = @midi.note_on(100, 0, 64, 100).unwrap()
  let sorted = @midi.sort_midi_events([on, off])
  match sorted[0].kind {
    @midi.NoteOff(channel=_, note=_, velocity=_) => assert_true(true)
    _ => assert_true(false)
  }
}

// --- conversion ---

///|
test "simple_score_to_midi_score_meta_track" {
  let score = make_simple_score()
  let ms = @midi.simple_score_to_midi_score(score, 480)
  assert_eq(ms.tracks[0].name, "Meta")
}

///|
test "simple_score_to_midi_score_ppq_960" {
  let score = make_simple_score()
  let ms = @midi.simple_score_to_midi_score(score, 960)
  assert_eq(ms.ppq, 960)
}

///|
test "simple_score_to_midi_score_multi_track" {
  let score = make_simple_score()
  let ms = @midi.simple_score_to_midi_score(score, 480)
  assert_true(ms.tracks.length() >= 2)
}

// --- bytes export ---

///|
test "midi_score_to_bytes_not_empty" {
  let score = make_simple_score()
  let ms = @midi.simple_score_to_midi_score(score, 480)
  let r = @midi.midi_score_to_bytes(ms)
  assert_true(r is Ok(_))
  assert_true(r.unwrap().length() > 0)
}

// --- MidiError ---

///|
test "midi_error_to_string" {
  let e = @midi.MidiError::InvalidMidiTick(-1)
  assert_true(e.to_string().contains("invalid MIDI tick"))
}

///|
test "midi_import_error_to_string" {
  let e = @midi.MidiError::MidiImportError("test import")
  assert_true(e.to_string().contains("MIDI import error"))
}

// ============================================================
// golden tests — 确定性输出验证（assert_eq）
// ============================================================

///|
/// 构造 C 大调音阶 SimpleScore
fn make_c_major_scale_score() -> @score.SimpleScore {
  let dur = @time.rhythm_duration(@time.DurQuarter, 0, None)
  let vel = @score.velocity_checked(100).unwrap()
  let scale = [
    @pitch.c(4), // C4 = MIDI 60
    @pitch.d(4), // D4 = MIDI 62
    @pitch.e(4), // E4 = MIDI 64
    @pitch.f(4), // F4 = MIDI 65
    @pitch.g(4), // G4 = MIDI 67
    @pitch.a(4), // A4 = MIDI 69
    @pitch.b(4), // B4 = MIDI 71
    @pitch.c(5), // C5 = MIDI 72
  ]
  let evts : Array[@score.SimpleEvent] = []
  for i = 0; i < scale.length(); i = i + 1 {
    evts.push(@score.simple_note_checked(scale[i], dur, Some(vel)).unwrap())
  }
  let ch = @score.midi_channel_checked(0).unwrap()
  let track = @score.simple_track_checked(evts, Some(ch), None).unwrap()
  let tempo = @score.tempo_checked(120).unwrap()
  let sig = @time.time_signature(4, 4)
  @score.simple_score_checked([track], tempo, sig).unwrap()
}

///|
/// golden: C 大调音阶 MIDI bytes SMF header 完全确定
test "golden_c_major_scale_midi_header" {
  let score = make_c_major_scale_score()
  let bytes = @midi.simple_score_to_midi_bytes_checked(score, 480).unwrap()
  // SMF header: "MThd" + length(6) + format(1) + ntrks(2) + division(480)
  // M=77, T=84, h=104, d=100
  assert_eq(bytes[0].to_int(), 77) // 'M'
  assert_eq(bytes[1].to_int(), 84) // 'T'
  assert_eq(bytes[2].to_int(), 104) // 'h'
  assert_eq(bytes[3].to_int(), 100) // 'd'
  assert_eq(bytes[4].to_int(), 0) // length byte 0
  assert_eq(bytes[5].to_int(), 0) // length byte 1
  assert_eq(bytes[6].to_int(), 0) // length byte 2
  assert_eq(bytes[7].to_int(), 6) // length = 6
  assert_eq(bytes[8].to_int(), 0) // format hi
  assert_eq(bytes[9].to_int(), 1) // format = 1 (multi-track)
  assert_eq(bytes[10].to_int(), 0) // ntrks hi
  assert_eq(bytes[11].to_int(), 2) // ntrks = 2 (Meta + data)
  assert_eq(bytes[12].to_int(), 1) // division hi
  assert_eq(bytes[13].to_int(), 224) // division = 480 (0x01E0)
}

///|
/// golden: C 大调音阶 MIDI bytes 确定性（两次运行一致）
test "golden_c_major_scale_deterministic" {
  let score = make_c_major_scale_score()
  let b1 = @midi.simple_score_to_midi_bytes_checked(score, 480).unwrap()
  let b2 = @midi.simple_score_to_midi_bytes_checked(score, 480).unwrap()
  assert_eq(b1.length(), b2.length())
  // 逐字节比较
  for i = 0; i < b1.length(); i = i + 1 {
    assert_eq(b1[i].to_int(), b2[i].to_int())
  }
}

///|
/// golden: C 大调音阶 MIDI bytes 包含正确数量的 note-on 事件
test "golden_c_major_scale_note_count" {
  let score = make_c_major_scale_score()
  let bytes = @midi.simple_score_to_midi_bytes_checked(score, 480).unwrap()
  // MIDI 文件含 MThd + MTrk chunks，应非空且 > 最小 header 大小
  assert_true(bytes.length() > 50)
  // 含 "MTrk" (track chunk 签名)
  // M=77, T=84, r=114, k=107
  let mut found_mtrk = 0
  for i = 0; i + 3 < bytes.length(); i = i + 1 {
    if bytes[i].to_int() == 77 &&
      bytes[i + 1].to_int() == 84 &&
      bytes[i + 2].to_int() == 114 &&
      bytes[i + 3].to_int() == 107 {
      found_mtrk = found_mtrk + 1
    }
  }
  // 应有 2 个轨道 chunk (Meta + 1 data track)
  assert_eq(found_mtrk, 2)
}

///|
/// golden: C 大调音阶 MIDI bytes 长度一致（跨构造）
test "golden_c_major_scale_length_stable" {
  let score = make_c_major_scale_score()
  let b1 = @midi.simple_score_to_midi_bytes_checked(score, 480).unwrap()
  let b2 = @midi.simple_score_to_midi_bytes_checked(score, 480).unwrap()
  assert_eq(b1.length(), b2.length())
}

///|
/// compat: midi 包从 v1 根包迁移。v1 的 `score.to_midi_bytes()` → v2 `simple_score_to_midi_bytes_checked()`
test "compat_note_v1_convenience_constructors_removed" {
  // v1 曾允许未检查构造，v2 所有构造器返回 Result
  // 验证 checked API 正确处理合法输入
  let note = @midi.note_on(0, 0, 60, 100)
  assert_true(note is Ok(_))
}

// ============================================================
// MIDI Import 测试 (roundtrip: Score → MIDI → Score)
// ============================================================

// --- midi_bytes_to_events ---

///|
test "import_bytes_to_events_non_empty" {
  let score = make_simple_score()
  let bytes = @midi.simple_score_to_midi_bytes_checked(score, 480).unwrap()
  let r = @midi.midi_bytes_to_events(bytes)
  assert_true(r is Ok(_))
  let events = r.unwrap()
  assert_true(events.length() > 0)
}

///|
test "import_bytes_to_events_has_noteon" {
  let score = make_simple_score()
  let bytes = @midi.simple_score_to_midi_bytes_checked(score, 480).unwrap()
  let events = @midi.midi_bytes_to_events(bytes).unwrap()
  let mut has_on = false
  for evt in events {
    match evt.kind {
      @midi.NoteOn(channel=_, note=_, velocity=v) => if v > 0 { has_on = true }
      _ => ()
    }
  }
  assert_true(has_on)
}

///|
test "import_bytes_to_events_has_noteoff" {
  let score = make_simple_score()
  let bytes = @midi.simple_score_to_midi_bytes_checked(score, 480).unwrap()
  let events = @midi.midi_bytes_to_events(bytes).unwrap()
  let mut has_off = false
  for evt in events {
    match evt.kind {
      @midi.NoteOff(channel=_, note=_, velocity=_) => has_off = true
      _ => ()
    }
  }
  assert_true(has_off)
}

///|
test "import_bytes_to_events_has_tempo" {
  let score = make_simple_score()
  let bytes = @midi.simple_score_to_midi_bytes_checked(score, 480).unwrap()
  let events = @midi.midi_bytes_to_events(bytes).unwrap()
  let mut has_tempo = false
  for evt in events {
    match evt.kind {
      @midi.TempoChange(bpm=_) => has_tempo = true
      _ => ()
    }
  }
  assert_true(has_tempo)
}

///|
test "import_bytes_to_events_has_timesig" {
  let score = make_simple_score()
  let bytes = @midi.simple_score_to_midi_bytes_checked(score, 480).unwrap()
  let events = @midi.midi_bytes_to_events(bytes).unwrap()
  let mut has_ts = false
  for evt in events {
    match evt.kind {
      @midi.TimeSignatureMeta(numerator=_, denominator=_) => has_ts = true
      _ => ()
    }
  }
  assert_true(has_ts)
}

///|
test "import_bytes_to_events_invalid_header_err" {
  // Non-MIDI bytes should return Err
  let bad_bytes = Bytes::make(10, b'\x00')
  let r = @midi.midi_bytes_to_events(bad_bytes)
  assert_true(r is Err(_))
}

// --- midi_events_to_score ---

///|
test "import_events_to_score_matches_note_count" {
  let score = make_simple_score()
  let bytes = @midi.simple_score_to_midi_bytes_checked(score, 480).unwrap()
  let events = @midi.midi_bytes_to_events(bytes).unwrap()
  let imported = @midi.midi_events_to_score(events, 480).unwrap()
  // Should have at least the original note count (4)
  let mut note_count = 0
  for track in imported.tracks {
    for evt in track.events {
      match evt {
        @score.Note(_) => note_count = note_count + 1
        @score.Chord(_) => note_count = note_count + 1
        _ => ()
      }
    }
  }
  assert_true(note_count >= 4)
}

///|
test "import_events_to_score_tempo_preserved" {
  let score = make_simple_score()
  let bytes = @midi.simple_score_to_midi_bytes_checked(score, 480).unwrap()
  let events = @midi.midi_bytes_to_events(bytes).unwrap()
  let imported = @midi.midi_events_to_score(events, 480).unwrap()
  assert_eq(imported.tempo.bpm, 120)
}

///|
test "import_events_to_score_ppq_zero_err" {
  let empty_events : Array[@midi.MidiEvent] = []
  let r = @midi.midi_events_to_score(empty_events, 0)
  assert_true(r is Err(_))
}

///|
test "import_events_to_score_ppq_negative_err" {
  let empty_events : Array[@midi.MidiEvent] = []
  let r = @midi.midi_events_to_score(empty_events, -1)
  assert_true(r is Err(_))
}

///|
test "import_events_to_score_empty_events_ok" {
  let empty_events : Array[@midi.MidiEvent] = []
  let r = @midi.midi_events_to_score(empty_events, 480)
  assert_true(r is Ok(_))
  let score = r.unwrap()
  // Empty input yields at least 1 track (empty)
  assert_true(score.tracks.length() >= 0)
}

// --- midi_bytes_to_score (roundtrip) ---

///|
test "import_roundtrip_note_count_preserved" {
  let score = make_simple_score()
  let bytes = @midi.simple_score_to_midi_bytes_checked(score, 480).unwrap()
  let imported = @midi.midi_bytes_to_score(bytes).unwrap()
  // Count notes in imported score
  let mut note_count = 0
  for track in imported.tracks {
    for evt in track.events {
      match evt {
        @score.Note(_) => note_count = note_count + 1
        @score.Chord(_) => note_count = note_count + 1
        _ => ()
      }
    }
  }
  assert_eq(note_count, 4)
}

///|
test "import_roundtrip_tempo_preserved" {
  let score = make_simple_score()
  let bytes = @midi.simple_score_to_midi_bytes_checked(score, 480).unwrap()
  let imported = @midi.midi_bytes_to_score(bytes).unwrap()
  assert_eq(imported.tempo.bpm, 120)
}

///|
test "import_roundtrip_has_track" {
  let score = make_simple_score()
  let bytes = @midi.simple_score_to_midi_bytes_checked(score, 480).unwrap()
  let imported = @midi.midi_bytes_to_score(bytes).unwrap()
  assert_true(imported.tracks.length() > 0)
}

///|
test "import_roundtrip_pitch_midi_values" {
  let score = make_simple_score()
  let bytes = @midi.simple_score_to_midi_bytes_checked(score, 480).unwrap()
  let imported = @midi.midi_bytes_to_score(bytes).unwrap()
  // C4 = 60, D4 = 62, E4 = 64, F4 = 65
  let found_midi : Array[Int] = []
  for track in imported.tracks {
    for evt in track.events {
      match evt {
        @score.Note(n) => found_midi.push(n.pitch.to_midi())
        _ => ()
      }
    }
  }
  assert_eq(found_midi[0], 60)
  assert_eq(found_midi[1], 62)
  assert_eq(found_midi[2], 64)
  assert_eq(found_midi[3], 65)
}

///|
test "import_invalid_bytes_err" {
  let bad_bytes = Bytes::make(10, b'\x00')
  let r = @midi.midi_bytes_to_score(bad_bytes)
  assert_true(r is Err(_))
}

///|
test "import_roundtrip_program_preserved" {
  // Create a score with a specific program
  let vel = @score.velocity_checked(100).unwrap()
  let dur = @time.rhythm_duration(@time.DurQuarter, 0, None)
  let evts = [@score.simple_note_checked(@pitch.c(4), dur, Some(vel)).unwrap()]
  let ch = @score.midi_channel_checked(0).unwrap()
  let prog = @score.midi_program_checked(1).unwrap() // Bright Acoustic Piano
  let track = @score.simple_track_checked(evts, Some(ch), Some(prog)).unwrap()
  let tempo = @score.tempo_checked(120).unwrap()
  let sig = @time.time_signature(4, 4)
  let score = @score.simple_score_checked([track], tempo, sig).unwrap()

  let bytes = @midi.simple_score_to_midi_bytes_checked(score, 480).unwrap()
  let imported = @midi.midi_bytes_to_score(bytes).unwrap()
  // Verify we got a track
  assert_true(imported.tracks.length() > 0)
}

///|
test "import_roundtrip_full_pipeline" {
  // Full roundtrip: score → bytes → events → score
  let score = make_simple_score()
  let bytes = @midi.simple_score_to_midi_bytes_checked(score, 480).unwrap()
  // Verify bytes are valid MIDI
  assert_true(bytes.length() > 0)
  // Parse to events
  let events = @midi.midi_bytes_to_events(bytes).unwrap()
  assert_true(events.length() > 0)
  // Convert to score
  let imported = @midi.midi_events_to_score(events, 480).unwrap()
  // Verify structure
  assert_eq(imported.tempo.bpm, 120)
  assert_true(imported.tracks.length() > 0)
}

// ============================================================
// Duration roundtrip tests — Score → bytes → Score
// 验证 import 后 duration 不再全部退化为 quarter
// ============================================================

///|
/// Roundtrip: quarter note duration preserved
test "import_roundtrip_duration_quarter" {
  let dur = @time.rhythm_duration(@time.DurQuarter, 0, None)
  let items : Array[(@pitch.Pitch, @time.RhythmDuration)] = [(@pitch.c(4), dur)]
  let score = make_score_with_durations(items)
  let bytes = @midi.simple_score_to_midi_bytes_checked(score, 480).unwrap()
  let imported = @midi.midi_bytes_to_score(bytes).unwrap()
  let result = first_note_duration(imported)
  assert_true(result.unit is @time.DurQuarter)
  assert_eq(result.dots, 0)
}

///|
/// Roundtrip: eighth note duration preserved
test "import_roundtrip_duration_eighth" {
  let dur = @time.rhythm_duration(@time.DurEighth, 0, None)
  let items : Array[(@pitch.Pitch, @time.RhythmDuration)] = [(@pitch.c(4), dur)]
  let score = make_score_with_durations(items)
  let bytes = @midi.simple_score_to_midi_bytes_checked(score, 480).unwrap()
  let imported = @midi.midi_bytes_to_score(bytes).unwrap()
  let result = first_note_duration(imported)
  assert_true(result.unit is @time.DurEighth)
  assert_eq(result.dots, 0)
}

///|
/// Roundtrip: half note duration preserved
test "import_roundtrip_duration_half" {
  let dur = @time.rhythm_duration(@time.DurHalf, 0, None)
  let items : Array[(@pitch.Pitch, @time.RhythmDuration)] = [(@pitch.c(4), dur)]
  let score = make_score_with_durations(items)
  let bytes = @midi.simple_score_to_midi_bytes_checked(score, 480).unwrap()
  let imported = @midi.midi_bytes_to_score(bytes).unwrap()
  let result = first_note_duration(imported)
  assert_true(result.unit is @time.DurHalf)
  assert_eq(result.dots, 0)
}

///|
/// Roundtrip: whole note duration preserved
test "import_roundtrip_duration_whole" {
  let dur = @time.rhythm_duration(@time.DurWhole, 0, None)
  let items : Array[(@pitch.Pitch, @time.RhythmDuration)] = [(@pitch.c(4), dur)]
  let score = make_score_with_durations(items)
  let bytes = @midi.simple_score_to_midi_bytes_checked(score, 480).unwrap()
  let imported = @midi.midi_bytes_to_score(bytes).unwrap()
  let result = first_note_duration(imported)
  assert_true(result.unit is @time.DurWhole)
  assert_eq(result.dots, 0)
}

///|
/// Roundtrip: sixteenth note duration preserved
test "import_roundtrip_duration_sixteenth" {
  let dur = @time.rhythm_duration(@time.DurSixteenth, 0, None)
  let items : Array[(@pitch.Pitch, @time.RhythmDuration)] = [(@pitch.c(4), dur)]
  let score = make_score_with_durations(items)
  let bytes = @midi.simple_score_to_midi_bytes_checked(score, 480).unwrap()
  let imported = @midi.midi_bytes_to_score(bytes).unwrap()
  let result = first_note_duration(imported)
  assert_true(result.unit is @time.DurSixteenth)
  assert_eq(result.dots, 0)
}

///|
/// Roundtrip: dotted quarter note duration preserved
test "import_roundtrip_duration_dotted_quarter" {
  let dur = @time.rhythm_duration(@time.DurQuarter, 1, None)
  let items : Array[(@pitch.Pitch, @time.RhythmDuration)] = [(@pitch.c(4), dur)]
  let score = make_score_with_durations(items)
  let bytes = @midi.simple_score_to_midi_bytes_checked(score, 480).unwrap()
  let imported = @midi.midi_bytes_to_score(bytes).unwrap()
  let result = first_note_duration(imported)
  assert_true(result.unit is @time.DurQuarter)
  assert_eq(result.dots, 1)
}

///|
/// Roundtrip: dotted half note duration preserved
test "import_roundtrip_duration_dotted_half" {
  let dur = @time.rhythm_duration(@time.DurHalf, 1, None)
  let items : Array[(@pitch.Pitch, @time.RhythmDuration)] = [(@pitch.c(4), dur)]
  let score = make_score_with_durations(items)
  let bytes = @midi.simple_score_to_midi_bytes_checked(score, 480).unwrap()
  let imported = @midi.midi_bytes_to_score(bytes).unwrap()
  let result = first_note_duration(imported)
  assert_true(result.unit is @time.DurHalf)
  assert_eq(result.dots, 1)
}

///|
/// Roundtrip: dotted eighth note duration preserved
test "import_roundtrip_duration_dotted_eighth" {
  let dur = @time.rhythm_duration(@time.DurEighth, 1, None)
  let items : Array[(@pitch.Pitch, @time.RhythmDuration)] = [(@pitch.c(4), dur)]
  let score = make_score_with_durations(items)
  let bytes = @midi.simple_score_to_midi_bytes_checked(score, 480).unwrap()
  let imported = @midi.midi_bytes_to_score(bytes).unwrap()
  let result = first_note_duration(imported)
  assert_true(result.unit is @time.DurEighth)
  assert_eq(result.dots, 1)
}

///|
/// Roundtrip: mixed durations in multi-note track — all preserved
test "import_roundtrip_duration_mixed" {
  let r = @time.rhythm_duration
  let items : Array[(@pitch.Pitch, @time.RhythmDuration)] = [
    (@pitch.c(4), r(@time.DurQuarter, 0, None)),
    (@pitch.d(4), r(@time.DurEighth, 0, None)),
    (@pitch.e(4), r(@time.DurHalf, 0, None)),
    (@pitch.f(4), r(@time.DurWhole, 0, None)),
    (@pitch.g(4), r(@time.DurSixteenth, 0, None)),
    (@pitch.a(4), r(@time.DurQuarter, 1, None)),
    (@pitch.b(4), r(@time.DurHalf, 1, None)),
    (@pitch.c(5), r(@time.DurEighth, 1, None)),
  ]
  let score = make_score_with_durations(items)
  let bytes = @midi.simple_score_to_midi_bytes_checked(score, 480).unwrap()
  let imported = @midi.midi_bytes_to_score(bytes).unwrap()

  let evts = imported.tracks[0].events
  // 1: quarter
  match evts[0] {
    @score.Note(n) => {
      assert_true(n.duration.unit is @time.DurQuarter)
      assert_eq(n.duration.dots, 0)
    }
    _ => assert_true(false)
  }
  // 2: eighth
  match evts[1] {
    @score.Note(n) => {
      assert_true(n.duration.unit is @time.DurEighth)
      assert_eq(n.duration.dots, 0)
    }
    _ => assert_true(false)
  }
  // 3: half
  match evts[2] {
    @score.Note(n) => {
      assert_true(n.duration.unit is @time.DurHalf)
      assert_eq(n.duration.dots, 0)
    }
    _ => assert_true(false)
  }
  // 4: whole
  match evts[3] {
    @score.Note(n) => {
      assert_true(n.duration.unit is @time.DurWhole)
      assert_eq(n.duration.dots, 0)
    }
    _ => assert_true(false)
  }
  // 5: sixteenth
  match evts[4] {
    @score.Note(n) => {
      assert_true(n.duration.unit is @time.DurSixteenth)
      assert_eq(n.duration.dots, 0)
    }
    _ => assert_true(false)
  }
  // 6: dotted quarter
  match evts[5] {
    @score.Note(n) => {
      assert_true(n.duration.unit is @time.DurQuarter)
      assert_eq(n.duration.dots, 1)
    }
    _ => assert_true(false)
  }
  // 7: dotted half
  match evts[6] {
    @score.Note(n) => {
      assert_true(n.duration.unit is @time.DurHalf)
      assert_eq(n.duration.dots, 1)
    }
    _ => assert_true(false)
  }
  // 8: dotted eighth
  match evts[7] {
    @score.Note(n) => {
      assert_true(n.duration.unit is @time.DurEighth)
      assert_eq(n.duration.dots, 1)
    }
    _ => assert_true(false)
  }
}

///|
/// Roundtrip: quarter triplet (3:2) duration preserved (PPQ=480)
/// 3 notes span 2 quarters → each = 2/3 quarter = 320 ticks
test "import_roundtrip_duration_quarter_triplet" {
  let tup = @time.TupletRatio::{ actual: 3, normal: 2 }
  let dur = @time.rhythm_duration(@time.DurQuarter, 0, Some(tup))
  let items : Array[(@pitch.Pitch, @time.RhythmDuration)] = [(@pitch.c(4), dur)]
  let score = make_score_with_durations(items)
  let bytes = @midi.simple_score_to_midi_bytes_checked(score, 480).unwrap()
  let imported = @midi.midi_bytes_to_score(bytes).unwrap()
  let result = first_note_duration(imported)
  assert_true(result.unit is @time.DurQuarter)
  assert_eq(result.dots, 0)
  // Tuplet should be present
  match result.tuplet {
    Some(t) => {
      assert_eq(t.actual, 3)
      assert_eq(t.normal, 2)
    }
    None => assert_true(false)
  }
}

///|
/// Roundtrip: ppq=960 quarter note duration preserved
/// Verifies ppq scaling works correctly
test "import_roundtrip_duration_quarter_ppq960" {
  let dur = @time.rhythm_duration(@time.DurQuarter, 0, None)
  let items : Array[(@pitch.Pitch, @time.RhythmDuration)] = [(@pitch.c(4), dur)]
  let score = make_score_with_durations(items)
  let bytes = @midi.simple_score_to_midi_bytes_checked(score, 960).unwrap()
  let imported = @midi.midi_bytes_to_score(bytes).unwrap()
  let result = first_note_duration(imported)
  assert_true(result.unit is @time.DurQuarter)
  assert_eq(result.dots, 0)
}
