///|
fn one_event() -> @timeline.NoteEvent {
  @timeline.NoteEvent::{
    start: 0.0,
    duration: 0.05,
    midi_note: 60,
    velocity: 100,
    channel: 0,
  }
}

///|
test "default_config" {
  let config = @wav.default_wav_render_config()
  assert_eq(config.sample_rate, 44100)
}

///|
test "invalid_sample_rate" {
  assert_true(@wav.wav_render_config_checked(0, 0.8, 0.1) is Err(_))
}

///|
test "render_wav_bytes_non_empty" {
  let bytes = @wav.note_events_to_wav_bytes_checked(
    [one_event()],
    @wav.default_wav_render_config(),
  ).unwrap()
  assert_true(bytes.length() > 44)
}

///|
test "render_empty_wav_has_header" {
  let bytes = @wav.note_events_to_wav_bytes_checked(
    [],
    @wav.default_wav_render_config(),
  ).unwrap()
  assert_true(bytes.length() >= 44)
}

///|
test "small_sample_rate" {
  let config = @wav.wav_render_config_checked(8000, 0.8, 0.01).unwrap()
  let bytes = @wav.note_events_to_wav_bytes_checked([one_event()], config).unwrap()
  assert_true(bytes.length() > 44)
}
