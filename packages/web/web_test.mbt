// ============================================================
// 基础事件转换测试
// ============================================================

///|
fn single_c4_note() -> @timeline.NoteEvent {
  @timeline.NoteEvent::{
    start: 0.0,
    duration: 1.0,
    midi_note: 60,
    velocity: 100,
    channel: 0,
  }
}

///|
fn make_timeline(
  events : Array[@timeline.NoteEvent],
  bpm : Int,
) -> @timeline.PlaybackTimeline {
  @timeline.timeline_from_events_checked(events, bpm, 4.0).unwrap()
}

///|
test "timeline_to_web_events_c4" {
  let timeline = make_timeline([single_c4_note()], 120)
  let config = @web.default_web_playback_config()
  let doc = @web.timeline_to_web_events_checked(timeline, config).unwrap()
  assert_eq(doc.events.length(), 1)
  assert_eq(doc.events[0].midi_note, 60)
  assert_eq(doc.events[0].event_type, "note_on")
  assert_eq(doc.schema_version, "moonsic.web.v1")
}

///|
test "empty_timeline" {
  let timeline = make_timeline([], 120)
  let config = @web.default_web_playback_config()
  let doc = @web.timeline_to_web_events_checked(timeline, config).unwrap()
  assert_eq(doc.events.length(), 0)
  assert_eq(doc.total_seconds, timeline.total_seconds)
}

///|
test "deterministic_order" {
  let events = [
    @timeline.NoteEvent::{
      start: 3.0,
      duration: 1.0,
      midi_note: 67,
      velocity: 100,
      channel: 0,
    },
    @timeline.NoteEvent::{
      start: 1.0,
      duration: 1.0,
      midi_note: 64,
      velocity: 100,
      channel: 0,
    },
    @timeline.NoteEvent::{
      start: 2.0,
      duration: 1.0,
      midi_note: 65,
      velocity: 100,
      channel: 0,
    },
  ]
  let timeline = make_timeline(events, 120)
  let config = @web.default_web_playback_config()
  let doc = @web.timeline_to_web_events_checked(timeline, config).unwrap()
  assert_eq(doc.events.length(), 3)
  assert_eq(doc.events[0].midi_note, 64)
  assert_eq(doc.events[1].midi_note, 65)
  assert_eq(doc.events[2].midi_note, 67)
}

// ============================================================
// JSON 输出测试
// ============================================================

///|
test "web_event_document_to_json" {
  let timeline = make_timeline([single_c4_note()], 120)
  let config = @web.default_web_playback_config()
  let doc = @web.timeline_to_web_events_checked(timeline, config).unwrap()
  let json = @web.web_event_document_to_json(doc)
  assert_true(json.contains("schema_version"))
  assert_true(json.contains("moonsic.web.v1"))
  assert_true(json.contains("events"))
  assert_true(json.contains("midi_note"))
  assert_true(json.contains("\"midi_note\":60"))
  assert_true(json.contains("event_type"))
  assert_true(json.contains("note_on"))
  assert_true(json.contains("total_seconds"))
}

// ============================================================
// Note events 转 Web events 测试
// ============================================================

///|
test "note_events_to_web_events_basic" {
  let events = [single_c4_note()]
  let config = @web.default_web_playback_config()
  let doc = @web.note_events_to_web_events(events, config)
  assert_eq(doc.events.length(), 1)
  assert_eq(doc.events[0].midi_note, 60)
}

///|
test "note_events_to_web_events_empty" {
  let events : Array[@timeline.NoteEvent] = []
  let config = @web.default_web_playback_config()
  let doc = @web.note_events_to_web_events(events, config)
  assert_eq(doc.events.length(), 0)
}

// ============================================================
// 错误路径测试
// ============================================================

///|
test "invalid_tempo" {
  let timeline = make_timeline([single_c4_note()], 120)
  let config = @web.WebPlaybackConfig::{
    tempo_bpm: 0,
    ppq: 480,
    include_note_off: false,
    time_unit: @web.Seconds,
  }
  assert_true(
    @web.timeline_to_web_events_checked(timeline, config)
    is Err(@web.InvalidTempo(0)),
  )
}

///|
test "invalid_ppq" {
  let timeline = make_timeline([single_c4_note()], 120)
  let config = @web.WebPlaybackConfig::{
    tempo_bpm: 120,
    ppq: 0,
    include_note_off: false,
    time_unit: @web.Seconds,
  }
  assert_true(
    @web.timeline_to_web_events_checked(timeline, config)
    is Err(@web.InvalidPpq(0)),
  )
}

///|
test "invalid_midi_note" {
  let event = @timeline.NoteEvent::{
    start: 0.0,
    duration: 1.0,
    midi_note: 128,
    velocity: 100,
    channel: 0,
  }
  let timeline = make_timeline([event], 120)
  let config = @web.default_web_playback_config()
  assert_true(
    @web.timeline_to_web_events_checked(timeline, config)
    is Err(@web.InvalidMidiNote(_)),
  )
}

///|
test "invalid_velocity" {
  let event = @timeline.NoteEvent::{
    start: 0.0,
    duration: 1.0,
    midi_note: 60,
    velocity: 128,
    channel: 0,
  }
  let timeline = make_timeline([event], 120)
  let config = @web.default_web_playback_config()
  assert_true(
    @web.timeline_to_web_events_checked(timeline, config)
    is Err(@web.InvalidVelocity(_)),
  )
}

///|
test "invalid_channel" {
  let event = @timeline.NoteEvent::{
    start: 0.0,
    duration: 1.0,
    midi_note: 60,
    velocity: 100,
    channel: 16,
  }
  let timeline = make_timeline([event], 120)
  let config = @web.default_web_playback_config()
  assert_true(
    @web.timeline_to_web_events_checked(timeline, config)
    is Err(@web.InvalidChannel(_)),
  )
}

///|
test "negative_tempo_rejected" {
  let timeline = make_timeline([single_c4_note()], 120)
  let config = @web.WebPlaybackConfig::{
    tempo_bpm: -1,
    ppq: 480,
    include_note_off: false,
    time_unit: @web.Seconds,
  }
  assert_true(
    @web.timeline_to_web_events_checked(timeline, config)
    is Err(@web.InvalidTempo(-1)),
  )
}

///|
test "negative_ppq_rejected" {
  let timeline = make_timeline([single_c4_note()], 120)
  let config = @web.WebPlaybackConfig::{
    tempo_bpm: 120,
    ppq: -1,
    include_note_off: false,
    time_unit: @web.Seconds,
  }
  assert_true(
    @web.timeline_to_web_events_checked(timeline, config)
    is Err(@web.InvalidPpq(-1)),
  )
}

// ============================================================
// include_note_off 测试
// ============================================================

///|
test "include_note_off" {
  let timeline = make_timeline([single_c4_note()], 120)
  let config = @web.WebPlaybackConfig::{
    tempo_bpm: 120,
    ppq: 480,
    include_note_off: true,
    time_unit: @web.Seconds,
  }
  let doc = @web.timeline_to_web_events_checked(timeline, config).unwrap()
  assert_eq(doc.events.length(), 2)
  assert_eq(doc.events[0].event_type, "note_on")
  assert_eq(doc.events[1].event_type, "note_off")
  assert_eq(doc.events[1].midi_note, 60)
  assert_eq(doc.events[1].velocity, 0)
  assert_eq(doc.events[1].duration, 0.0)
}

// ============================================================
// 时间单位转换测试
// ============================================================

///|
test "time_unit_beats" {
  let event = @timeline.NoteEvent::{
    start: 1.0,
    duration: 2.0,
    midi_note: 60,
    velocity: 100,
    channel: 0,
  }
  let timeline = make_timeline([event], 60)
  let config = @web.WebPlaybackConfig::{
    tempo_bpm: 60,
    ppq: 480,
    include_note_off: false,
    time_unit: @web.Beats,
  }
  let doc = @web.timeline_to_web_events_checked(timeline, config).unwrap()
  // 60 BPM, 1 second = 1 beat, so start=1.0s → 1.0 beats
  assert_eq(doc.events[0].time, 1.0)
  assert_eq(doc.events[0].duration, 2.0)
}

///|
test "time_unit_ticks" {
  let event = @timeline.NoteEvent::{
    start: 1.0,
    duration: 0.5,
    midi_note: 60,
    velocity: 100,
    channel: 0,
  }
  let timeline = make_timeline([event], 120)
  let config = @web.WebPlaybackConfig::{
    tempo_bpm: 120,
    ppq: 480,
    include_note_off: false,
    time_unit: @web.Ticks,
  }
  let doc = @web.timeline_to_web_events_checked(timeline, config).unwrap()
  // 120 BPM, quarter_sec=0.5. start=1.0 beat → 0.5s → 480 ticks.
  // duration=0.5 beat → 0.25s → 240 ticks.
  assert_eq(doc.events[0].time, 480.0)
  assert_eq(doc.events[0].duration, 240.0)
}

///|
test "note_events_time_unit_beats" {
  let events = [single_c4_note()]
  let config = @web.WebPlaybackConfig::{
    tempo_bpm: 120,
    ppq: 480,
    include_note_off: false,
    time_unit: @web.Beats,
  }
  let doc = @web.note_events_to_web_events(events, config)
  assert_eq(doc.events[0].time, 0.0)
  assert_eq(doc.events[0].duration, 1.0)
}

///|
test "note_events_time_unit_seconds" {
  let events = [
    @timeline.NoteEvent::{
      start: 0.0,
      duration: 2.0,
      midi_note: 60,
      velocity: 100,
      channel: 0,
    },
  ]
  let config = @web.WebPlaybackConfig::{
    tempo_bpm: 60,
    ppq: 480,
    include_note_off: false,
    time_unit: @web.Seconds,
  }
  let doc = @web.note_events_to_web_events(events, config)
  // 60 BPM = 1 beat/sec, so 2 beats → 2 seconds
  assert_eq(doc.events[0].time, 0.0)
  assert_eq(doc.events[0].duration, 2.0)
}

// ============================================================
// 默认配置测试
// ============================================================

///|
test "default_config" {
  let config = @web.default_web_playback_config()
  assert_eq(config.tempo_bpm, 120)
  assert_eq(config.ppq, 480)
  assert_eq(config.include_note_off, false)
  assert_true(config.time_unit is @web.Seconds)
}

// ============================================================
// WebError to_string 测试
// ============================================================

///|
test "web_error_to_string" {
  assert_true(@web.InvalidTempo(0).to_string().contains("invalid tempo"))
  assert_true(@web.InvalidPpq(-1).to_string().contains("invalid PPQ"))
  assert_true(@web.InvalidMidiNote("test").to_string().contains("invalid MIDI"))
}

// ============================================================
// WebTimeUnit to_string 测试
// ============================================================

///|
test "web_time_unit_to_string" {
  assert_eq(@web.Seconds.to_string(), "seconds")
  assert_eq(@web.Ticks.to_string(), "ticks")
  assert_eq(@web.Beats.to_string(), "beats")
}

// ============================================================
// Document 结构测试
// ============================================================

///|
test "document_structure" {
  let timeline = make_timeline([single_c4_note()], 120)
  let config = @web.default_web_playback_config()
  let doc = @web.timeline_to_web_events_checked(timeline, config).unwrap()
  assert_eq(doc.schema_version, "moonsic.web.v1")
  assert_eq(doc.events.length(), 1)
  assert_true(doc.total_seconds > 0.0)
}
