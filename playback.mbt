//
// 播放时间线模块 — Score 到可播放事件流的转换与按秒查询
//

// --- PlaybackTimeline ---

///|
/// 播放时间线：以秒为单位的 NoteEvent 数组 + 总时长
/// 事件中的 start/duration 已从拍（beat）转为秒
pub(all) struct PlaybackTimeline {
  events : Array[NoteEvent]
  total_seconds : Double
}

// --- 时间线构建 ---

///|
/// 将乐谱转为播放时间线，所有事件的 start/duration 已转为秒
pub fn timeline_from_score(score : Score) -> PlaybackTimeline {
  let raw_events = score.to_note_events()
  let quarter_sec = 60.0 / score.tempo.bpm.to_double()
  let total_beats = score.duration_beats()
  let total = total_beats * quarter_sec
  let converted = []
  for e in raw_events {
    converted.push({
      start: e.start * quarter_sec,
      duration: e.duration * quarter_sec,
      midi_note: e.midi_note,
      velocity: e.velocity,
      channel: e.channel,
    })
  }
  { events: converted, total_seconds: total }
}

///|
/// 用指定 BPM 将 NoteEvent 数组转为播放时间线
pub fn timeline_from_events(
  events : Array[NoteEvent],
  bpm : Int,
  total_beats : Double,
) -> PlaybackTimeline {
  let quarter_sec = 60.0 / bpm.to_double()
  let total = total_beats * quarter_sec
  let converted = []
  for e in events {
    converted.push({
      start: e.start * quarter_sec,
      duration: e.duration * quarter_sec,
      midi_note: e.midi_note,
      velocity: e.velocity,
      channel: e.channel,
    })
  }
  { events: converted, total_seconds: total }
}

// --- 时间调度查询 ---

///|
/// 查询时刻 t（秒）正在播放的事件（t ∈ [start, start+duration)）
pub fn PlaybackTimeline::at_second(
  self : PlaybackTimeline,
  t : Double,
) -> Array[NoteEvent] {
  let result = []
  for e in self.events {
    let e_end = e.start + e.duration
    if t >= e.start && t < e_end {
      result.push(e)
    }
  }
  result
}

///|
/// 查询在时间窗口 [start, end) 内与窗口有交集的事件
pub fn PlaybackTimeline::events_between(
  self : PlaybackTimeline,
  start_sec : Double,
  end_sec : Double,
) -> Array[NoteEvent] {
  let result = []
  for e in self.events {
    let e_end = e.start + e.duration
    if e.start < end_sec && e_end > start_sec {
      result.push(e)
    }
  }
  result
}

///|
/// 返回时间线总时长（秒）
pub fn PlaybackTimeline::duration(self : PlaybackTimeline) -> Double {
  self.total_seconds
}

///|
/// 返回时间线中的事件总数
pub fn PlaybackTimeline::event_count(self : PlaybackTimeline) -> Int {
  self.events.length()
}

///|
/// 判断时间线是否为空（无事件）
pub fn PlaybackTimeline::is_empty(self : PlaybackTimeline) -> Bool {
  self.events.length() == 0
}

///|
/// 返回最后事件的结束时间（秒），空时间线返回 0.0
pub fn PlaybackTimeline::last_end(self : PlaybackTimeline) -> Double {
  let mut max_end = 0.0
  for e in self.events {
    let e_end = e.start + e.duration
    if e_end > max_end {
      max_end = e_end
    }
  }
  max_end
}

///|
/// 查询指定通道在时刻 t 正在播放的事件
pub fn PlaybackTimeline::at_second_channel(
  self : PlaybackTimeline,
  t : Double,
  channel : Int,
) -> Array[NoteEvent] {
  let result = []
  for e in self.events {
    if e.channel == channel {
      let e_end = e.start + e.duration
      if t >= e.start && t < e_end {
        result.push(e)
      }
    }
  }
  result
}

///|
/// 将播放时间线转为字符串摘要
pub fn PlaybackTimeline::to_string(self : PlaybackTimeline) -> String {
  "PlaybackTimeline(events=\{self.events.length()}, total_seconds=\{self.total_seconds})"
}
