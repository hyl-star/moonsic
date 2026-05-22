///|
/// 苏打绿 — 他夏了夏天（C 大调, 4/4, ♩=120）
/// 运行：`moon run cmd/main`
fn main {
  // I-V-vi-IV 和弦进行，重复覆盖全曲
  let chord_pattern = @lib.progression(
    @lib.c(3),
    @lib.Major,
    [@lib.I, @lib.V, @lib.VI, @lib.IV],
    @lib.half(),
  )
  let chords = chord_pattern.repeat(16)

  // 琶音 + 低音
  let arp = @lib.instrument(@lib.arpeggiate(chords, @lib.eighth()), @lib.electric_piano_1())
  let bass = @lib.instrument(@lib.bass_roots(chords, @lib.half()), @lib.electric_bass_finger())

  // 主歌旋律（他夏了夏天 verse）
  let verse_melody = @lib.melody([
    // 第 1-4 小节
    @lib.n(@lib.c(4), @lib.quarter()), @lib.n(@lib.d(4), @lib.quarter()), @lib.n(@lib.e(4), @lib.quarter()), @lib.n(@lib.g(4), @lib.quarter()),
    @lib.n(@lib.a(4), @lib.quarter()), @lib.n(@lib.g(4), @lib.quarter()), @lib.n(@lib.e(4), @lib.quarter()), @lib.n(@lib.d(4), @lib.quarter()),
    @lib.n(@lib.c(4), @lib.quarter()), @lib.n(@lib.d(4), @lib.quarter()), @lib.n(@lib.e(4), @lib.quarter()), @lib.n(@lib.g(4), @lib.quarter()),
    @lib.n(@lib.a(4), @lib.quarter()), @lib.n(@lib.g(4), @lib.quarter()), @lib.n(@lib.e(4), @lib.quarter()), @lib.n(@lib.d(4), @lib.quarter()),
    // 第 5-8 小节
    @lib.n(@lib.c(4), @lib.quarter()), @lib.n(@lib.d(4), @lib.quarter()), @lib.n(@lib.e(4), @lib.quarter()), @lib.n(@lib.a(4), @lib.quarter()),
    @lib.n(@lib.g(4), @lib.quarter()), @lib.n(@lib.e(4), @lib.quarter()), @lib.n(@lib.d(4), @lib.quarter()), @lib.n(@lib.c(4), @lib.quarter()),
    @lib.n(@lib.b(3), @lib.quarter()), @lib.n(@lib.c(4), @lib.quarter()), @lib.n(@lib.d(4), @lib.quarter()), @lib.n(@lib.g(4), @lib.quarter()),
    @lib.n(@lib.e(4), @lib.half()),     @lib.n(@lib.d(4), @lib.quarter()), @lib.n(@lib.c(4), @lib.quarter()),
  ])

  // 副歌旋律
  let chorus_melody = @lib.melody([
    // 第 1-4 小节
    @lib.n(@lib.c(4), @lib.quarter()), @lib.n(@lib.c(4), @lib.quarter()), @lib.n(@lib.d(4), @lib.quarter()), @lib.n(@lib.e(4), @lib.quarter()),
    @lib.n(@lib.e(4), @lib.quarter()), @lib.n(@lib.d(4), @lib.quarter()), @lib.n(@lib.c(4), @lib.quarter()), @lib.n(@lib.g(3), @lib.quarter()),
    @lib.n(@lib.a(3), @lib.quarter()), @lib.n(@lib.a(3), @lib.quarter()), @lib.n(@lib.g(3), @lib.quarter()), @lib.n(@lib.e(3), @lib.quarter()),
    @lib.n(@lib.d(3), @lib.whole()),
    // 第 5-8 小节
    @lib.n(@lib.g(3), @lib.quarter()), @lib.n(@lib.g(3), @lib.quarter()), @lib.n(@lib.a(3), @lib.quarter()), @lib.n(@lib.c(4), @lib.quarter()),
    @lib.n(@lib.c(4), @lib.quarter()), @lib.n(@lib.a(3), @lib.quarter()), @lib.n(@lib.g(3), @lib.quarter()), @lib.n(@lib.e(3), @lib.quarter()),
    @lib.n(@lib.d(3), @lib.quarter()), @lib.n(@lib.e(3), @lib.quarter()), @lib.n(@lib.g(3), @lib.quarter()), @lib.n(@lib.a(3), @lib.quarter()),
    @lib.n(@lib.g(3), @lib.whole()),
  ])

  // 主歌×2 + 副歌×2
  let lead_track = verse_melody.concat(verse_melody).concat(chorus_melody).concat(chorus_melody)
  let lead = @lib.instrument(lead_track, @lib.synth_lead_square())

  // 鼓组（32 小节）
  let drums = @lib.basic_beat(32)

  let song = @lib.score_with(
    [arp, bass, lead, drums.tracks[0], drums.tracks[1], drums.tracks[2]],
    120,
    @lib.four_four(),
  )

  println("// moonsic v\{@lib.version()} — 苏打绿 他夏了夏天")
  println(@lib.note_events_to_browser_js(song.to_note_events()))
}
