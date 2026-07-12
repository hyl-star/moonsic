///|
pub fn bench_adapter_mock(iterations : Int) -> String {
  let context = ScoreContext::{
    score_summary: "bench",
    key_hint: None,
    time_signature: @time.time_signature(4, 4),
    tempo: @score.tempo_checked(120).unwrap(),
    bars: 2,
    track_count: 0,
    ppq: 480,
  }
  let request = generation_request_default_checked(
    MelodyContinuation,
    context,
    [MinBars(1), MaxBars(4)],
  ).unwrap()
  let mut count = 0
  for i = 0; i < iterations; i = i + 1 {
    let response = deterministic_mock_generate(request).unwrap()
    count = count + response.candidates.length()
  }
  "adapter mock: \{count}"
}
