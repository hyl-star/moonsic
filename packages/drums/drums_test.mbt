///|
test "drum_note_checked" {
  let event = @drums.drum_note_checked(
    @drums.KICK,
    @time.rhythm_duration(@time.DurQuarter, 0, None),
    100,
  ).unwrap()
  match event {
    @score.Note(note) => assert_eq(note.pitch.to_midi(), 36)
    _ => abort("expected note")
  }
}

///|
test "drum_note_invalid" {
  assert_true(
    @drums.drum_note_checked(
      200,
      @time.rhythm_duration(@time.DurQuarter, 0, None),
      100,
    )
    is Err(_),
  )
}

///|
test "basic_beat" {
  let score = @drums.basic_beat_checked(1).unwrap()
  assert_eq(score.tracks.length(), 3)
  assert_eq(score.tracks[0].channel.unwrap().value, @drums.DRUM_CHANNEL)
  assert_eq(score.tracks[2].events.length(), 8)
}

///|
test "basic_beat_invalid_bars" {
  assert_true(@drums.basic_beat_checked(0) is Err(_))
}
