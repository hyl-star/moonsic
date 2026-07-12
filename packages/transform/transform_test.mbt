///|
fn q() -> @time.RhythmDuration {
  @time.rhythm_duration(@time.DurQuarter, 0, None)
}

///|
fn track() -> @score.SimpleTrack {
  let note = @score.simple_note_checked(
    @pitch.c(4),
    q(),
    Some(@score.velocity_checked(80).unwrap()),
  ).unwrap()
  let rest = @score.simple_rest_checked(q()).unwrap()
  let chord = @score.simple_chord_checked(
    [@pitch.c(4), @pitch.e(4), @pitch.g(4)],
    q(),
    Some(@score.velocity_checked(90).unwrap()),
  ).unwrap()
  @score.simple_track_checked([note, rest, chord], None, None).unwrap()
}

///|
test "concat" {
  let merged = @transform.simple_track_concat(track(), track())
  assert_eq(merged.events.length(), 6)
}

///|
test "reverse" {
  let reversed = @transform.simple_track_reverse(track())
  match reversed.events[0] {
    @score.Chord(_) => ()
    _ => abort("expected chord")
  }
}

///|
test "stretch" {
  let stretched = @transform.simple_track_stretch_checked(track(), 2.0).unwrap()
  match stretched.events[0] {
    @score.Note(note) => {
      let ticks = @time.rhythm_duration_to_ticks(note.duration, 480).unwrap()
      assert_eq(ticks, 960)
    }
    _ => abort("expected note")
  }
}

///|
test "transpose" {
  let transposed = @transform.simple_track_transpose_checked(track(), 2).unwrap()
  match transposed.events[0] {
    @score.Note(note) => assert_eq(note.pitch.to_midi(), 62)
    _ => abort("expected note")
  }
}

///|
test "map_velocity" {
  let mapped = @transform.simple_track_map_velocity_checked(track(), value => {
    value + 10
  }).unwrap()
  match mapped.events[0] {
    @score.Note(note) => assert_eq(note.velocity.value, 90)
    _ => abort("expected note")
  }
}

///|
test "map_velocity_invalid" {
  assert_true(
    @transform.simple_track_map_velocity_checked(track(), value => value + 100)
    is Err(_),
  )
}
