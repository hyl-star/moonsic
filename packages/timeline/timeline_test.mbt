///|
fn q() -> @time.RhythmDuration {
  @time.rhythm_duration(@time.DurQuarter, 0, None)
}

///|
fn simple_score() -> @score.SimpleScore {
  let n = @score.simple_note_checked(
    @pitch.c(4),
    q(),
    Some(@score.velocity_checked(90).unwrap()),
  ).unwrap()
  let r = @score.simple_rest_checked(q()).unwrap()
  let ch = @score.simple_chord_checked(
    [@pitch.e(4), @pitch.g(4)],
    q(),
    Some(@score.velocity_checked(80).unwrap()),
  ).unwrap()
  let track = @score.simple_track_checked(
    [n, r, ch],
    Some(@score.midi_channel_checked(1).unwrap()),
    None,
  ).unwrap()
  @score.simple_score_checked(
    [track],
    @score.tempo_checked(120).unwrap(),
    @time.time_signature(4, 4),
  ).unwrap()
}

///|
test "note_event_end" {
  let event = @timeline.NoteEvent::{
    start: 1.0,
    duration: 2.0,
    midi_note: 60,
    velocity: 90,
    channel: 0,
  }
  assert_eq(event.end(), 3.0)
}

///|
test "simple_score_to_note_events" {
  let events = @timeline.simple_score_to_note_events_checked(simple_score()).unwrap()
  assert_eq(events.length(), 3)
  assert_eq(events[0].midi_note, 60)
  assert_eq(events[0].channel, 1)
  assert_eq(events[1].start, 2.0)
}

///|
test "timeline_from_simple_score" {
  let timeline = @timeline.timeline_from_simple_score_checked(simple_score()).unwrap()
  assert_eq(timeline.event_count(), 3)
  assert_eq(timeline.duration(), 1.5)
}

///|
test "timeline_at_second" {
  let timeline = @timeline.timeline_from_simple_score_checked(simple_score()).unwrap()
  assert_eq(timeline.at_second(0.25).length(), 1)
}

///|
test "browser_js" {
  let events = @timeline.simple_score_to_note_events_checked(simple_score()).unwrap()
  let js = @timeline.note_events_to_browser_js(events)
  assert_true(js.contains("window.MOONSIC_DEMO_EVENTS"))
}

///|
test "invalid_bpm" {
  assert_true(@timeline.timeline_from_events_checked([], 0, 0.0) is Err(_))
}
