///|
fn q() -> @time.RhythmDuration {
  @time.rhythm_duration(@time.DurQuarter, 0, None)
}

///|
fn note_track(note : @pitch.Pitch) -> @score.SimpleTrack {
  let event = @score.simple_note_checked(note, q(), None).unwrap()
  @score.simple_track_checked([event], None, None).unwrap()
}

///|
test "section_duration" {
  let s = @structure.verse([note_track(@pitch.c(4))]).unwrap()
  assert_eq(@structure.section_duration_beats(s), 1.0)
}

///|
test "pad_to" {
  let padded = @structure.simple_track_pad_to_checked(
    note_track(@pitch.c(4)),
    4.0,
  ).unwrap()
  assert_eq(@structure.simple_track_duration_beats(padded), 4.0)
}

///|
test "arrange_sections" {
  let a = @structure.verse([note_track(@pitch.c(4))]).unwrap()
  let b = @structure.chorus([note_track(@pitch.d(4))]).unwrap()
  let score = @structure.arrange_checked(
    [a, b],
    @score.tempo_checked(120).unwrap(),
    @time.time_signature(4, 4),
  ).unwrap()
  assert_eq(score.tracks.length(), 1)
  assert_eq(score.tracks[0].events.length(), 2)
}

///|
test "melody_degrees" {
  let track = @structure.melody_degrees_checked(
    @scale.key(@pitch.c(4), @scale.Major),
    [1, 2, 3],
    q(),
  ).unwrap()
  assert_eq(track.events.length(), 3)
}

///|
test "bass_roots" {
  let chord = @score.simple_chord_checked(
    [@pitch.c(4), @pitch.e(4), @pitch.g(4)],
    q(),
    None,
  ).unwrap()
  let track = @score.simple_track_checked([chord], None, None).unwrap()
  let bass = @structure.bass_roots_checked(track, q()).unwrap()
  match bass.events[0] {
    @score.Note(note) => assert_eq(note.pitch.to_midi(), 60)
    _ => abort("expected note")
  }
}
