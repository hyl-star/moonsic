///|
/// moonsic v4 — original summer sketch: I-V-vi-IV + bass + melody + drums
/// 运行：`moon run cmd/main`
fn main {
  // 和弦进行
  let chords = @lib.progression(
    @lib.c(3),
    @lib.Major,
    [@lib.I, @lib.V, @lib.VI, @lib.IV],
    @lib.half(),
  )

  // 琶音
  let arp = @lib.instrument(
    @lib.arpeggiate(chords, @lib.eighth()),
    @lib.electric_piano_1(),
  )

  // 低音根音
  let bass = @lib.instrument(
    @lib.bass_roots(chords, @lib.half()),
    @lib.electric_bass_finger(),
  )

  // Original bright summer-like motif. Not a transcription of any existing song.
  let lead_melody = @lib.melody([
    @lib.n(@lib.e(4), @lib.eighth()),
    @lib.n(@lib.g(4), @lib.eighth()),
    @lib.n(@lib.a(4), @lib.quarter()),
    @lib.r(@lib.eighth()),
    @lib.n(@lib.g(4), @lib.eighth()),
    @lib.n(@lib.e(4), @lib.quarter()),
    @lib.n(@lib.d(4), @lib.eighth()),
    @lib.n(@lib.e(4), @lib.eighth()),
    @lib.n(@lib.g(4), @lib.quarter()),
    @lib.n(@lib.a(4), @lib.eighth()),
    @lib.n(@lib.g(4), @lib.eighth()),
    @lib.n(@lib.e(4), @lib.quarter()),
    @lib.n(@lib.c(5), @lib.quarter()),
    @lib.n(@lib.b(4), @lib.eighth()),
    @lib.n(@lib.a(4), @lib.eighth()),
    @lib.n(@lib.g(4), @lib.quarter()),
    @lib.n(@lib.e(4), @lib.quarter()),
    @lib.n(@lib.d(4), @lib.eighth()),
    @lib.n(@lib.e(4), @lib.eighth()),
    @lib.n(@lib.g(4), @lib.eighth()),
    @lib.n(@lib.a(4), @lib.eighth()),
    @lib.n(@lib.g(4), @lib.quarter()),
    @lib.n(@lib.e(4), @lib.quarter()),
  ])
  let lead = @lib.instrument(lead_melody, @lib.synth_lead_square())

  // 鼓组
  let drums = @lib.basic_beat(4)

  let song = @lib.score_with(
    [arp, bass, lead, drums.tracks[0], drums.tracks[1], drums.tracks[2]],
    120,
    @lib.four_four(),
  )

  println("// moonsic v\{@lib.version()} — v4 demo events")
  println(@lib.note_events_to_browser_js(song.to_note_events()))
}
