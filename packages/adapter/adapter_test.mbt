///|
fn test_context() -> @adapter.ScoreContext {
  @adapter.ScoreContext::{
    score_summary: "test",
    key_hint: None,
    time_signature: @time.time_signature(4, 4),
    tempo: @score.tempo_checked(120).unwrap(),
    bars: 2,
    track_count: 1,
    ppq: 480,
  }
}

///|
fn test_track() -> @score.SimpleTrack {
  let event = @score.simple_note_checked(
    @pitch.c(4),
    @time.rhythm_duration(@time.DurQuarter, 0, None),
    None,
  ).unwrap()
  @score.simple_track_checked([event], None, None).unwrap()
}

///|
test "request_validation" {
  let request = @adapter.generation_request_default_checked(
    @adapter.MelodyContinuation,
    test_context(),
    [@adapter.MinBars(1), @adapter.MaxBars(4)],
  ).unwrap()
  let provider = @adapter.generation_provider_info(
    "mock",
    @adapter.MockProvider,
    [@adapter.CanGenerateMelody],
  )
  assert_true(@adapter.validate_generation_request(request, provider) is Ok(_))
}

///|
test "request_constraint_error" {
  assert_true(
    @adapter.generation_request_default_checked(
      @adapter.MelodyContinuation,
      test_context(),
      [@adapter.MinBars(4), @adapter.MaxBars(2)],
    )
    is Err(_),
  )
}

///|
test "request_json_roundtrip" {
  let request = @adapter.generation_request_checked(
    "req_test",
    @adapter.GameLoopTask,
    test_context(),
    [@adapter.Chiptune],
    [@adapter.MustLoop],
    @adapter.Seeded,
    Some(42),
  ).unwrap()
  let decoded = @adapter.generation_request_from_json(
    @adapter.generation_request_to_json(request),
  ).unwrap()
  assert_eq(decoded.id, "req_test")
  assert_eq(decoded.context.ppq, 480)
  assert_true(decoded.task is @adapter.GameLoopTask)
}

///|
test "mock_generate" {
  let request = @adapter.generation_request_default_checked(
    @adapter.MelodyContinuation,
    test_context(),
    [],
  ).unwrap()
  let response = @adapter.deterministic_mock_generate(request).unwrap()
  assert_eq(response.candidates.length(), 1)
  assert_eq(response.candidates[0].fragment.tracks[0].events.length(), 8)
}

///|
test "simple_score_json_roundtrip" {
  let score = @score.simple_score_checked(
    [test_track()],
    @score.tempo_checked(120).unwrap(),
    @time.time_signature(4, 4),
  ).unwrap()
  let decoded = @adapter.simple_score_from_json_checked(
    @adapter.simple_score_to_json_checked(score).unwrap(),
  ).unwrap()
  assert_eq(decoded.tracks.length(), 1)
  assert_eq(decoded.tracks[0].events.length(), 1)
}

///|
test "patch_append_track" {
  let score = @score.simple_score_checked(
    [test_track()],
    @score.tempo_checked(120).unwrap(),
    @time.time_signature(4, 4),
  ).unwrap()
  let payload = @adapter.simple_score_to_json_checked(score).unwrap()
  let parsed = @json.json_parse(payload).unwrap()
  let fields = @json.json_as_object(parsed).unwrap()
  let tracks = @json.json_as_array(@json.json_lookup(fields, "tracks").unwrap()).unwrap()
  let track_json = @json.json_stringify(tracks[0])
  let patch = @adapter.generation_patch_checked([
    @adapter.GenerationPatchOperation::{
      kind: @adapter.AppendTrack,
      target: @adapter.ScoreTarget,
      path: "/score/tracks",
      payload_json: track_json,
    },
  ]).unwrap()
  let updated = @adapter.apply_generation_patch_checked(score, patch).unwrap()
  assert_eq(updated.tracks.length(), 2)
}

///|
test "ffi_mock_json" {
  let request = @adapter.generation_request_default_checked(
    @adapter.MelodyContinuation,
    test_context(),
    [],
  ).unwrap()
  let output = @adapter.ffi_external_generate_mock_json(
    @adapter.generation_request_to_json(request),
  )
  assert_true(output.contains("\"ok\":true"))
  assert_true(output.contains("\"candidates\""))
}
