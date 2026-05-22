///|
/// moonsic v3 — Pop Progression: I-V-vi-IV + bass + melody + drums
/// 运行：`moon run cmd/main`
fn main {
  let k = @lib.key(@lib.c(4), @lib.Major)

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

  // 旋律来自调内音级
  let lead_melody = @lib.melody_degrees(
    k,
    [1, 2, 3, 5, 3, 2, 1, 5, 5],
    @lib.quarter(),
  )
  let lead = @lib.instrument(lead_melody, @lib.violin())

  // 鼓组
  let drums = @lib.basic_beat(4)

  let song = @lib.score_with(
    [arp, bass, lead, drums.tracks[0], drums.tracks[1], drums.tracks[2]],
    120,
    @lib.four_four(),
  )

  println("// moonsic v\{@lib.version()} — v3 demo events")
  println(@lib.note_events_to_browser_js(song.to_note_events()))
}
