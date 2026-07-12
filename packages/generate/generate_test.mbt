///|
fn key_c_major() -> @scale.Key {
  @scale.key(@pitch.c(4), @scale.Major)
}

///|
test "default_config" {
  let config = @generate.default_generation_config()
  assert_eq(config.range_low.to_midi(), 60)
}

///|
test "generate_melody" {
  let rhythm = @rhythm.rhythm_template(@rhythm.FourQuarters)
  let track = @generate.generate_melody_checked(
    key_c_major(),
    rhythm,
    @generate.default_generation_config(),
  ).unwrap()
  assert_eq(track.events.length(), 4)
}

///|
test "generate_melody_empty_rhythm" {
  let empty = @rhythm.RhythmPattern::{ cells: [], total_beats: 0.0 }
  assert_true(
    @generate.generate_melody_checked(
      key_c_major(),
      empty,
      @generate.default_generation_config(),
    )
    is Err(_),
  )
}

///|
test "generate_chord_progression" {
  let track = @generate.generate_chord_progression_checked(
    key_c_major(),
    [1, 5, 6, 4],
    @time.rhythm_duration(@time.DurHalf, 0, None),
    @generate.default_generation_config(),
  ).unwrap()
  assert_eq(track.events.length(), 4)
}

///|
test "generate_chord_bad_degree" {
  assert_true(
    @generate.generate_chord_progression_checked(
      key_c_major(),
      [1, 8],
      @time.rhythm_duration(@time.DurHalf, 0, None),
      @generate.default_generation_config(),
    )
    is Err(_),
  )
}

///|
test "generate_phrase_melody" {
  let context = @generate.GenerationContext::{
    key: key_c_major(),
    progression: [1, 5, 6, 4],
    time_signature: @time.time_signature(4, 4),
    tempo: @score.tempo_checked(120).unwrap(),
    bars: 1,
  }
  let phrase = @generate.generate_phrase_checked(
    context,
    @generate.default_generation_config(),
  ).unwrap()
  assert_eq(phrase.track.events.length(), 4)
}

///|
test "generated_phrase_to_score" {
  let context = @generate.GenerationContext::{
    key: key_c_major(),
    progression: [1, 5, 6, 4],
    time_signature: @time.time_signature(4, 4),
    tempo: @score.tempo_checked(120).unwrap(),
    bars: 1,
  }
  let phrase = @generate.generate_phrase_checked(
    context,
    @generate.default_generation_config(),
  ).unwrap()
  let score = @generate.generated_phrase_to_score_checked(
    phrase,
    @score.tempo_checked(120).unwrap(),
    @time.time_signature(4, 4),
  ).unwrap()
  assert_eq(score.tracks.length(), 1)
}

///|
test "generate_bass_root_fifth" {
  let context = @generate.GenerationContext::{
    key: key_c_major(),
    progression: [1, 4],
    time_signature: @time.time_signature(4, 4),
    tempo: @score.tempo_checked(120).unwrap(),
    bars: 1,
  }
  let config = @generate.GenerationConfig::{
    mode: @generate.BassOnly,
    contour: @generate.StepwiseUp,
    range_low: @pitch.c(2),
    range_high: @pitch.c(4),
    seed: None,
    voice_leading: @generate.KeepInRange,
    allow_rests: false,
    max_leap: 12,
  }
  let track = @generate.generate_bass_checked(
    context,
    @generate.RootFifthBass,
    config,
  ).unwrap()
  assert_eq(track.events.length(), 4)
}

///|
test "generate_accompaniment_arpeggio" {
  let context = @generate.GenerationContext::{
    key: key_c_major(),
    progression: [1],
    time_signature: @time.time_signature(4, 4),
    tempo: @score.tempo_checked(120).unwrap(),
    bars: 1,
  }
  let track = @generate.generate_accompaniment_checked(
    context,
    @generate.ArpeggioUp,
    @generate.default_generation_config(),
  ).unwrap()
  assert_eq(track.events.length(), 3)
}

///|
test "generate_game_loop" {
  let context = @generate.GenerationContext::{
    key: key_c_major(),
    progression: [1, 5, 6, 4],
    time_signature: @time.time_signature(4, 4),
    tempo: @score.tempo_checked(120).unwrap(),
    bars: 1,
  }
  let score = @generate.generate_game_loop_checked(
    context,
    1,
    @generate.default_generation_config(),
  ).unwrap()
  assert_eq(score.tracks.length(), 2)
  assert_eq(score.tracks[0].events.length(), 4)
}
