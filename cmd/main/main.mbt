///|
/// moonsic 命令行 — 导出示例 MIDI 文件
/// 运行：`moon run cmd/main`
fn main {
  let p = @lib.pitch

  // C 大调旋律：C4 D4 E4 G4 C5
  let melody = @lib.track([
    @lib.Note(@lib.note(p(@lib.C, @lib.Natural, 4), @lib.Quarter)),
    @lib.Note(@lib.note(p(@lib.D, @lib.Natural, 4), @lib.Quarter)),
    @lib.Note(@lib.note(p(@lib.E, @lib.Natural, 4), @lib.Quarter)),
    @lib.Note(@lib.note(p(@lib.G, @lib.Natural, 4), @lib.Quarter)),
    @lib.Note(@lib.note(p(@lib.C, @lib.Natural, 5), @lib.Half)),
    @lib.Rest(@lib.rest(@lib.Half)),
  ])

  let score = @lib.score_with_tempo([melody], @lib.tempo(120), @lib.four_four())

  let bytes = score.to_midi_bytes()

  println("moonsic v\{@lib.version()}")
  println(
    "Score: \{score.track_count()} track(s), \{score.duration_beats()} beats",
  )
  println("MIDI bytes: \{bytes.length()}")
}
