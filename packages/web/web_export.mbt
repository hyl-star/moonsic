///|
pub fn timeline_to_web_events_checked(
  timeline : @timeline.PlaybackTimeline,
  config : WebPlaybackConfig,
) -> Result[WebEventDocument, WebError] {
  if config.tempo_bpm <= 0 {
    return Err(InvalidTempo(config.tempo_bpm))
  }
  if config.ppq <= 0 {
    return Err(InvalidPpq(config.ppq))
  }
  let raw_events = timeline.events
  let web_events : Array[WebPlaybackEvent] = []
  for event in raw_events {
    if event.midi_note < 0 || event.midi_note > 127 {
      return Err(
        InvalidMidiNote("midi_note \{event.midi_note} out of range 0-127"),
      )
    }
    if event.velocity < 0 || event.velocity > 127 {
      return Err(
        InvalidVelocity("velocity \{event.velocity} out of range 0-127"),
      )
    }
    if event.channel < 0 || event.channel > 15 {
      return Err(InvalidChannel("channel \{event.channel} out of range 0-15"))
    }
    let (time, duration) = convert_time_seconds_to_unit(
      event.start,
      event.duration,
      config,
    )
    web_events.push({
      time,
      duration,
      midi_note: event.midi_note,
      velocity: event.velocity,
      channel: event.channel,
      event_type: "note_on",
    })
    if config.include_note_off {
      web_events.push({
        time: time + duration,
        duration: 0.0,
        midi_note: event.midi_note,
        velocity: 0,
        channel: event.channel,
        event_type: "note_off",
      })
    }
  }
  let sorted = sort_web_events(web_events)
  Ok({
    schema_version: "moonsic.web.v1",
    events: sorted,
    total_seconds: timeline.total_seconds,
  })
}

///|
pub fn note_events_to_web_events(
  events : Array[@timeline.NoteEvent],
  config : WebPlaybackConfig,
) -> WebEventDocument {
  let web_events : Array[WebPlaybackEvent] = []
  for event in events {
    let (time, duration) = convert_time_beats_to_unit(
      event.start,
      event.duration,
      config,
    )
    web_events.push({
      time,
      duration,
      midi_note: event.midi_note,
      velocity: event.velocity,
      channel: event.channel,
      event_type: "note_on",
    })
    if config.include_note_off {
      web_events.push({
        time: time + duration,
        duration: 0.0,
        midi_note: event.midi_note,
        velocity: 0,
        channel: event.channel,
        event_type: "note_off",
      })
    }
  }
  let sorted = sort_web_events(web_events)
  let last_end = note_events_last_end_beats(events)
  let total_seconds = last_end * 60.0 / config.tempo_bpm.to_double()
  { schema_version: "moonsic.web.v1", events: sorted, total_seconds }
}

///|
pub fn web_event_document_to_json(doc : WebEventDocument) -> String {
  @json.json_stringify(web_event_document_to_json_value(doc))
}

///|
pub fn simple_score_to_web_json_checked(
  score : @score.SimpleScore,
  config : WebPlaybackConfig,
) -> Result[String, WebError] {
  let timeline = match @timeline.timeline_from_simple_score_checked(score) {
    Ok(value) => value
    Err(e) => return Err(InvalidEvent(e.to_string()))
  }
  let doc = match timeline_to_web_events_checked(timeline, config) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  Ok(web_event_document_to_json(doc))
}

// ============================================================
// 内部辅助函数
// ============================================================

///|
fn convert_time_seconds_to_unit(
  start_seconds : Double,
  duration_seconds : Double,
  config : WebPlaybackConfig,
) -> (Double, Double) {
  match config.time_unit {
    Seconds => (start_seconds, duration_seconds)
    Beats => {
      let factor = config.tempo_bpm.to_double() / 60.0
      (start_seconds * factor, duration_seconds * factor)
    }
    Ticks => {
      let factor = config.tempo_bpm.to_double() * config.ppq.to_double() / 60.0
      (start_seconds * factor, duration_seconds * factor)
    }
  }
}

///|
fn convert_time_beats_to_unit(
  start_beats : Double,
  duration_beats : Double,
  config : WebPlaybackConfig,
) -> (Double, Double) {
  match config.time_unit {
    Seconds => {
      let quarter_sec = 60.0 / config.tempo_bpm.to_double()
      (start_beats * quarter_sec, duration_beats * quarter_sec)
    }
    Beats => (start_beats, duration_beats)
    Ticks =>
      (
        start_beats * config.ppq.to_double(),
        duration_beats * config.ppq.to_double(),
      )
  }
}

///|
fn sort_web_events(events : Array[WebPlaybackEvent]) -> Array[WebPlaybackEvent] {
  let n = events.length()
  if n <= 1 {
    return events
  }
  for i = 1; i < n; i = i + 1 {
    let key = events[i]
    let mut j = i - 1
    while j >= 0 && events[j].time > key.time {
      events[j + 1] = events[j]
      j = j - 1
    }
    events[j + 1] = key
  }
  events
}

///|
fn note_events_last_end_beats(events : Array[@timeline.NoteEvent]) -> Double {
  let mut max_end = 0.0
  for event in events {
    let end = event.start + event.duration
    if end > max_end {
      max_end = end
    }
  }
  max_end
}

///|
fn web_event_document_to_json_value(doc : WebEventDocument) -> @json.JsonValue {
  let event_values : Array[@json.JsonValue] = []
  for event in doc.events {
    event_values.push(web_event_to_json_value(event))
  }
  @json.json_object([
    @json.json_field("schema_version", @json.json_string(doc.schema_version)),
    @json.json_field("events", @json.json_array(event_values)),
    @json.json_field("total_seconds", @json.json_number(doc.total_seconds)),
  ])
}

///|
fn web_event_to_json_value(event : WebPlaybackEvent) -> @json.JsonValue {
  @json.json_object([
    @json.json_field("time", @json.json_number(event.time)),
    @json.json_field("duration", @json.json_number(event.duration)),
    @json.json_field("midi_note", @json.json_int(event.midi_note)),
    @json.json_field("velocity", @json.json_int(event.velocity)),
    @json.json_field("channel", @json.json_int(event.channel)),
    @json.json_field("event_type", @json.json_string(event.event_type)),
  ])
}
