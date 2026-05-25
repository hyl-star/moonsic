//
// TimeMap 类型与 API — 多 tempo / 多拍号时间地图
//

///|
/// 速度变化点
pub(all) struct TempoChange {
  at_tick : Int
  tempo_bpm : Double
}

///|
/// 拍号变化点
pub(all) struct TimeSigChange {
  at_bar : Int
  sig_num : Int
  sig_den : Int
}

///|
/// 时间地图 = PPQ + 初始拍号/速度 + 变化点列表
pub(all) struct TimeMap {
  ppq : Int
  sig_num : Int
  sig_den : Int
  tempo_bpm : Double
  tempo_changes : Array[TempoChange]
  sig_changes : Array[TimeSigChange]
}

///|
/// 构造 TimeMap，验证 ppq > 0、拍号合法、bpm > 0
pub fn make_time_map(
  ppq : Int,
  sig : TimeSignature,
  bpm : Double,
) -> Result[TimeMap, TimeError] {
  if ppq <= 0 {
    return Err(InvalidPPQ("PPQ 必须 > 0，当前：\{ppq}"))
  }
  if !is_valid_time_signature(sig.numerator, sig.denominator) {
    return Err(
      InvalidTimeSignature("无效拍号：\{sig.numerator}/\{sig.denominator}"),
    )
  }
  if bpm <= 0.0 {
    return Err(InvalidTempo("BPM 必须 > 0，当前：\{bpm}"))
  }
  Ok({
    ppq,
    sig_num: sig.numerator,
    sig_den: sig.denominator,
    tempo_bpm: bpm,
    tempo_changes: [],
    sig_changes: [],
  })
}

///|
/// 查询指定 tick 对应的 BPM（遍历所有变化点取最后匹配的）
pub fn tempo_at_tick(map : TimeMap, tick : Int) -> Double {
  let mut result = map.tempo_bpm
  for i = 0; i < map.tempo_changes.length(); i = i + 1 {
    if map.tempo_changes[i].at_tick <= tick {
      result = map.tempo_changes[i].tempo_bpm
    }
  }
  result
}

///|
/// 查询指定 bar 对应的拍号 (num, den)
pub fn signature_at_bar(map : TimeMap, bar : Int) -> (Int, Int) {
  let mut num = map.sig_num
  let mut den = map.sig_den
  for i = 0; i < map.sig_changes.length(); i = i + 1 {
    if map.sig_changes[i].at_bar <= bar {
      num = map.sig_changes[i].sig_num
      den = map.sig_changes[i].sig_den
    }
  }
  (num, den)
}

///|
/// 向 TimeMap 添加速度变化（保持 at_tick 升序）
pub fn add_tempo_change(map : TimeMap, ch : TempoChange) -> TimeMap {
  let new_changes = insert_sorted_tempo(map.tempo_changes, ch)
  {
    ppq: map.ppq,
    sig_num: map.sig_num,
    sig_den: map.sig_den,
    tempo_bpm: map.tempo_bpm,
    tempo_changes: new_changes,
    sig_changes: map.sig_changes,
  }
}

///|
/// 向 TimeMap 添加拍号变化（保持 at_bar 升序）
pub fn add_sig_change(map : TimeMap, ch : TimeSigChange) -> TimeMap {
  let new_changes = insert_sorted_sig(map.sig_changes, ch)
  {
    ppq: map.ppq,
    sig_num: map.sig_num,
    sig_den: map.sig_den,
    tempo_bpm: map.tempo_bpm,
    tempo_changes: map.tempo_changes,
    sig_changes: new_changes,
  }
}

///|
/// 将 TempoChange 插入已排序数组（内部函数）
fn insert_sorted_tempo(
  changes : Array[TempoChange],
  ch : TempoChange,
) -> Array[TempoChange] {
  let result : Array[TempoChange] = []
  let mut inserted = false
  for i = 0; i < changes.length(); i = i + 1 {
    if !inserted && ch.at_tick < changes[i].at_tick {
      result.push(ch)
      inserted = true
    }
    result.push(changes[i])
  }
  if !inserted {
    result.push(ch)
  }
  result
}

///|
/// 将 TimeSigChange 插入已排序数组（内部函数）
fn insert_sorted_sig(
  changes : Array[TimeSigChange],
  ch : TimeSigChange,
) -> Array[TimeSigChange] {
  let result : Array[TimeSigChange] = []
  let mut inserted = false
  for i = 0; i < changes.length(); i = i + 1 {
    if !inserted && ch.at_bar < changes[i].at_bar {
      result.push(ch)
      inserted = true
    }
    result.push(changes[i])
  }
  if !inserted {
    result.push(ch)
  }
  result
}

///|
/// 排序 TempoChange 列表（按 at_tick 升序）
fn sort_tempo_changes(changes : Array[TempoChange]) -> Array[TempoChange] {
  let len = changes.length()
  if len <= 1 {
    return changes
  }
  let arr : Array[TempoChange] = []
  for i = 0; i < len; i = i + 1 {
    arr.push(changes[i])
  }
  // 冒泡排序
  for i = 0; i < len; i = i + 1 {
    for j = 0; j < len - i - 1; j = j + 1 {
      if arr[j].at_tick > arr[j + 1].at_tick {
        let tmp = arr[j]
        arr[j] = arr[j + 1]
        arr[j + 1] = tmp
      }
    }
  }
  arr
}

///|
/// 多 tempo 分段累加：从 tick=0 到 target 的秒数
pub fn ticks_to_seconds_timemap(
  target : Int,
  map : TimeMap,
) -> Result[Double, TimeError] {
  if target < 0 {
    return Err(InvalidTick("tick 必须 >= 0，当前：\{target}"))
  }
  if map.ppq <= 0 {
    return Err(InvalidPPQ("PPQ 必须 > 0，当前：\{map.ppq}"))
  }
  let changes = sort_tempo_changes(map.tempo_changes)
  let mut current_tick : Int = 0
  let mut current_bpm = map.tempo_bpm
  let mut seconds = 0.0
  let mut idx = 0
  while current_tick < target {
    let next_change_tick = if idx < changes.length() {
      changes[idx].at_tick
    } else {
      target
    }
    let seg_end = if next_change_tick < target {
      next_change_tick
    } else {
      target
    }
    let delta = seg_end - current_tick
    let seg_seconds = delta.to_double() *
      60.0 /
      (map.ppq.to_double() * current_bpm)
    seconds = seconds + seg_seconds
    current_tick = seg_end
    if idx < changes.length() && current_tick == changes[idx].at_tick {
      current_bpm = changes[idx].tempo_bpm
      idx = idx + 1
    }
  }
  Ok(seconds)
}
