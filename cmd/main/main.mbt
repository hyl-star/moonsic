///|
/// moonsic 命令行 — 导出示例 MIDI + 浏览器 demo 数据
/// 运行：`moon run cmd/main`
fn main {
  // v1.5 简洁 API 构建示例旋律
  let lead = @lib.melody([
    @lib.n(@lib.c(4), @lib.quarter()),
    @lib.n(@lib.d(4), @lib.quarter()),
    @lib.n(@lib.e(4), @lib.quarter()),
    @lib.n(@lib.g(4), @lib.dotted(@lib.quarter())),
    @lib.r(@lib.eighth()),
    @lib.n(@lib.c(5), @lib.half()),
  ])

  let harmony = @lib.melody([
    @lib.major(@lib.c(3), @lib.half()),
    @lib.minor(@lib.a(3), @lib.half()),
  ])

  let song = @lib.score_with([lead, harmony], 120, @lib.four_four())

  println("// moonsic v\{@lib.version()} — demo events")
  println(@lib.note_events_to_browser_js(song.to_note_events()))
}
