///|
pub(all) struct PlaybackTimeline {
  events : Array[NoteEvent]
  total_seconds : Double
}

///|
pub fn timeline_from_events_checked(
  events : Array[NoteEvent],
  bpm : Int,
  total_beats : Double,
) -> Result[PlaybackTimeline, TimelineError] {
  if bpm <= 0 {
    return Err(InvalidBpm(bpm))
  }
  let quarter_sec = 60.0 / bpm.to_double()
  let converted : Array[NoteEvent] = []
  for event in events {
    converted.push({
      start: event.start * quarter_sec,
      duration: event.duration * quarter_sec,
      midi_note: event.midi_note,
      velocity: event.velocity,
      channel: event.channel,
    })
  }
  Ok({ events: converted, total_seconds: total_beats * quarter_sec })
}

///|
pub fn timeline_from_simple_score_checked(
  score : @score.SimpleScore,
) -> Result[PlaybackTimeline, TimelineError] {
  let events = match simple_score_to_note_events_checked(score) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  let total_beats = note_events_last_end(events)
  timeline_from_events_checked(events, score.tempo.bpm, total_beats)
}

///|
pub fn timeline_from_score_layout_checked(
  layout : @score.ScoreLayout,
) -> Result[PlaybackTimeline, TimelineError] {
  let events = match score_layout_to_note_events_checked(layout) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  let total_beats = note_events_last_end(events)
  timeline_from_events_checked(events, layout.initial_tempo.bpm, total_beats)
}

///|
pub fn note_events_last_end(events : Array[NoteEvent]) -> Double {
  let mut max_end = 0.0
  for event in events {
    let end = event.end()
    if end > max_end {
      max_end = end
    }
  }
  max_end
}

///|
pub fn PlaybackTimeline::at_second(
  self : PlaybackTimeline,
  second : Double,
) -> Array[NoteEvent] {
  let result : Array[NoteEvent] = []
  for event in self.events {
    if second >= event.start && second < event.end() {
      result.push(event)
    }
  }
  result
}

///|
pub fn PlaybackTimeline::events_between(
  self : PlaybackTimeline,
  start_sec : Double,
  end_sec : Double,
) -> Array[NoteEvent] {
  let result : Array[NoteEvent] = []
  for event in self.events {
    if event.start < end_sec && event.end() > start_sec {
      result.push(event)
    }
  }
  result
}

///|
pub fn PlaybackTimeline::duration(self : PlaybackTimeline) -> Double {
  self.total_seconds
}

///|
pub fn PlaybackTimeline::event_count(self : PlaybackTimeline) -> Int {
  self.events.length()
}

///|
pub fn PlaybackTimeline::is_empty(self : PlaybackTimeline) -> Bool {
  self.events.length() == 0
}

///|
pub fn PlaybackTimeline::last_end(self : PlaybackTimeline) -> Double {
  note_events_last_end(self.events)
}

///|
pub fn PlaybackTimeline::at_second_channel(
  self : PlaybackTimeline,
  second : Double,
  channel : Int,
) -> Array[NoteEvent] {
  let result : Array[NoteEvent] = []
  for event in self.events {
    if event.channel == channel && second >= event.start && second < event.end() {
      result.push(event)
    }
  }
  result
}
