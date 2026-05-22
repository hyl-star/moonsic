///|
/// moonsic v2 — 和弦进行 + 琶音 + 旋律 + 鼓组
/// 运行：`moon run cmd/main`
fn main {
  // I-V-vi-IV 和弦进行（C 大调）
  let chords = @lib.progression(
    @lib.c(3),
    @lib.Major,
    [@lib.I, @lib.V, @lib.VI, @lib.IV],
    @lib.half(),
  )

  // 琶音化
  let arp = @lib.arpeggiate(chords, @lib.eighth())
  let arp_piano = @lib.instrument(arp, @lib.electric_piano_1())

  // 旋律
  let lead = @lib.melody([
    @lib.n(@lib.c(4), @lib.quarter()),
    @lib.n(@lib.d(4), @lib.quarter()),
    @lib.n(@lib.e(4), @lib.quarter()),
    @lib.n(@lib.g(4), @lib.dotted(@lib.quarter())),
    @lib.r(@lib.eighth()),
    @lib.n(@lib.c(5), @lib.half()),
  ])
  let lead_violin = @lib.instrument(lead, @lib.violin())

  // 鼓组
  let drums = @lib.basic_beat(4)

  // 合并所有轨道
  let song = @lib.score_with(
    [arp_piano, lead_violin, drums.tracks[0], drums.tracks[1], drums.tracks[2]],
    120,
    @lib.four_four(),
  )

  println("// moonsic v\{@lib.version()} — v2 demo events")
  println(@lib.note_events_to_browser_js(song.to_note_events()))
}
