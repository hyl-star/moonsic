// ============================================================
// Benchmark 模块 — 基础性能基准测试
// 不参与运行时音乐逻辑，仅用于本地 / CI 性能基线测量。
// 注：MoonBit 当前 WASM 后端不支持 @time 包，此处使用迭代次数
// 统计 + 函数调用开销概算，实际耗时需使用 moon bench 或原生后端。
// ============================================================

///|
/// 格式化基准结果字符串
fn format_result(name : String, n : Int) -> String {
  "\{name}: completed \{n} iterations"
}

///|
/// 跑 n 次 duration→tick 换算并返回统计字符串
pub fn bench_duration_to_ticks(n : Int) -> String {
  let dur = Eighth
  let ppq = 480
  for _i = 0; _i < n; _i = _i + 1 {
    let _ = dur.ticks(ppq)
  }
  format_result("bench_duration_to_ticks", n)
}

///|
/// 跑 n 次 Score→NoteEvent 展平并返回统计字符串
pub fn bench_score_flatten(n : Int) -> String {
  // 构造一个含两条轨道的乐谱
  let p = pitch
  let track1 = track([
    Note(note(p(C, Natural, 4), Quarter)),
    Rest(rest(Quarter)),
    Note(note(p(D, Natural, 4), Half)),
  ])
  let track2 = track_with_channel([Note(note(p(E, Natural, 4), Whole))], 1)
  let s = score([track1, track2])
  for _i = 0; _i < n; _i = _i + 1 {
    let _ = s.to_note_events()
  }
  format_result("bench_score_flatten", n)
}

///|
/// 跑 n 次 to_midi_bytes 并返回统计字符串
pub fn bench_midi_export(n : Int) -> String {
  let p = pitch
  let track = track([
    Note(note(p(C, Natural, 4), Quarter)),
    Rest(rest(Quarter)),
    Note(note(p(D, Natural, 4), Half)),
    Note(note(p(E, Natural, 4), Quarter)),
  ])
  let s = score([track])
  for _i = 0; _i < n; _i = _i + 1 {
    let _ = s.to_midi_bytes()
  }
  format_result("bench_midi_export", n)
}

///|
/// 跑 n 次 to_wav_bytes 并返回统计字符串
pub fn bench_wav_render(n : Int) -> String {
  let p = pitch
  let track = track([
    Note(note(p(C, Natural, 4), Quarter)),
    Note(note(p(D, Natural, 4), Quarter)),
  ])
  let s = score([track])
  for _i = 0; _i < n; _i = _i + 1 {
    let _ = s.to_wav_bytes()
  }
  format_result("bench_wav_render", n)
}
