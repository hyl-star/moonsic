// ============================================================
// 核心音乐模型
// ============================================================

// --- 常量 ---

///|
/// 默认 PPQ（每四分音符的 tick 数）
pub const DEFAULT_PPQ : Int = 480

///|
/// 默认力度
pub const DEFAULT_VELOCITY : Int = 100

///|
/// 力度范围：0-127
pub const MIN_VELOCITY : Int = 0
pub const MAX_VELOCITY : Int = 127

///|
/// MIDI 音符范围：0-127
pub const MIN_MIDI_NOTE : Int = 0
pub const MAX_MIDI_NOTE : Int = 127

///|
/// MIDI 通道范围：0-15
pub const MIN_CHANNEL : Int = 0
pub const MAX_CHANNEL : Int = 15

///|
/// A4 的 MIDI 编号和频率
pub const A4_MIDI : Int = 69
pub const A4_FREQ : Double = 440.0

// --- 音高类 PitchClass ---

///|
/// 自然音名，不含变音记号
pub(all) enum PitchClass {
  C
  D
  E
  F
  G
  A
  B
}

///|
/// 获取自然音名的基准半音偏移（C=0, D=2, ..., B=11）
pub fn PitchClass::base_semitone(self : PitchClass) -> Int {
  match self {
    C => 0
    D => 2
    E => 4
    F => 5
    G => 7
    A => 9
    B => 11
  }
}

///|
/// 转为字符串表示
pub fn PitchClass::to_string(self : PitchClass) -> String {
  match self {
    C => "C"
    D => "D"
    E => "E"
    F => "F"
    G => "G"
    A => "A"
    B => "B"
  }
}

// --- 变音记号 Accidental ---

///|
/// 变音记号：升、降、还原
pub(all) enum Accidental {
  Natural
  Sharp
  Flat
}

///|
/// 获取变音记号的半音偏移量（升=+1，降=-1，还原=0）
pub fn Accidental::semitone_offset(self : Accidental) -> Int {
  match self {
    Natural => 0
    Sharp => 1
    Flat => -1
  }
}

///|
/// 转为字符串表示（还原="", 升="#", 降="b"）
pub fn Accidental::to_string(self : Accidental) -> String {
  match self {
    Natural => ""
    Sharp => "#"
    Flat => "b"
  }
}

// --- 音高 Pitch ---

///|
/// 音高 = 音名 + 变音记号 + 八度
pub(all) struct Pitch {
  class : PitchClass
  accidental : Accidental
  octave : Int
}

///|
/// 创建音高
pub fn pitch(
  class : PitchClass,
  accidental : Accidental,
  octave : Int,
) -> Pitch {
  { class, accidental, octave }
}

///|
/// 创建自然音高（无变音记号）
pub fn natural(class : PitchClass, octave : Int) -> Pitch {
  { class, accidental: Natural, octave }
}

///|
/// 音高转为 MIDI 音符编号
/// 公式：(octave+1)*12 + base_semitone + accidental_offset
pub fn Pitch::to_midi(self : Pitch) -> Int {
  (self.octave + 1) * 12 +
  self.class.base_semitone() +
  self.accidental.semitone_offset()
}

///|
/// 判断该音高是否在有效 MIDI 范围内（0-127）
pub fn Pitch::is_valid_midi(self : Pitch) -> Bool {
  let midi = self.to_midi()
  midi >= 0 && midi <= 127
}

///|
/// 移调：按半音数移动，使用升号拼写
pub fn Pitch::transpose(self : Pitch, semitones : Int) -> Pitch {
  let midi = self.to_midi() + semitones
  midi_to_pitch(midi)
}

///|
/// 转为字符串，如 "C4", "C#4", "Db4"
pub fn Pitch::to_string(self : Pitch) -> String {
  "\{self.class.to_string()}\{self.accidental.to_string()}\{self.octave}"
}

///|
/// 从 MIDI 编号转为 Pitch（升号拼写）
pub fn midi_to_pitch(midi : Int) -> Pitch {
  let octave = midi / 12 - 1
  let semitone = midi % 12
  let (class, accidental) = match semitone {
    0 => (C, Natural)
    1 => (C, Sharp)
    2 => (D, Natural)
    3 => (D, Sharp)
    4 => (E, Natural)
    5 => (F, Natural)
    6 => (F, Sharp)
    7 => (G, Natural)
    8 => (G, Sharp)
    9 => (A, Natural)
    10 => (A, Sharp)
    11 => (B, Natural)
    _ => (C, Natural)
  }
  { class, accidental, octave }
}

// --- 时值 Duration ---

///|
/// 音符时值：全音符、二分、四分、八分、十六分
pub(all) enum Duration {
  Whole
  Half
  Quarter
  Eighth
  Sixteenth
}

///|
/// 获取时值对应的拍数（以四分音符=1拍为基准）
pub fn Duration::beats(self : Duration) -> Double {
  match self {
    Whole => 4.0
    Half => 2.0
    Quarter => 1.0
    Eighth => 0.5
    Sixteenth => 0.25
  }
}

///|
/// 将时值转为 MIDI tick 数
pub fn Duration::ticks(self : Duration, ppq : Int) -> Int {
  let raw = self.beats() * ppq.to_double()
  raw.to_int()
}

///|
/// 使用默认 PPQ 转为 tick 数
pub fn Duration::default_ticks(self : Duration) -> Int {
  self.ticks(DEFAULT_PPQ)
}

///|
/// 将时值转为秒数
pub fn Duration::seconds(self : Duration, bpm : Int) -> Double {
  let quarter_sec = 60.0 / bpm.to_double()
  self.beats() * quarter_sec
}

///|
pub fn Duration::to_string(self : Duration) -> String {
  match self {
    Whole => "whole"
    Half => "half"
    Quarter => "quarter"
    Eighth => "eighth"
    Sixteenth => "sixteenth"
  }
}

// --- 速度 Tempo ---

///|
/// 速度，以 BPM 表示
pub(all) struct Tempo {
  bpm : Int
}

///|
pub fn tempo(bpm : Int) -> Tempo {
  { bpm, }
}

///|
pub fn default_tempo() -> Tempo {
  { bpm: 120 }
}

///|
/// 获取四分音符的秒数
pub fn Tempo::quarter_seconds(self : Tempo) -> Double {
  60.0 / self.bpm.to_double()
}

///|
pub fn Tempo::to_string(self : Tempo) -> String {
  "\{self.bpm} BPM"
}

///|
pub fn is_valid_bpm(bpm : Int) -> Bool {
  bpm > 0
}

// --- 拍号 TimeSignature ---

///|
/// 拍号，如 4/4, 3/4, 6/8
pub(all) struct TimeSignature {
  numerator : Int
  denominator : Int
}

///|
pub fn time_signature(numerator : Int, denominator : Int) -> TimeSignature {
  { numerator, denominator }
}

///|
pub fn four_four() -> TimeSignature {
  { numerator: 4, denominator: 4 }
}

///|
/// 每小节的拍数
pub fn TimeSignature::measure_beats(self : TimeSignature) -> Double {
  self.numerator.to_double() * (4.0 / self.denominator.to_double())
}

///|
pub fn TimeSignature::to_string(self : TimeSignature) -> String {
  "\{self.numerator}/\{self.denominator}"
}

///|
pub fn is_valid_time_signature(numerator : Int, denominator : Int) -> Bool {
  if numerator <= 0 {
    return false
  }
  match denominator {
    1 | 2 | 4 | 8 | 16 | 32 | 64 => true
    _ => false
  }
}

// --- 验证函数 ---

///|
pub fn is_valid_velocity(v : Int) -> Bool {
  v >= MIN_VELOCITY && v <= MAX_VELOCITY
}

///|
pub fn is_valid_midi_note(n : Int) -> Bool {
  n >= MIN_MIDI_NOTE && n <= MAX_MIDI_NOTE
}

///|
pub fn is_valid_channel(c : Int) -> Bool {
  c >= MIN_CHANNEL && c <= MAX_CHANNEL
}

// --- 音符 Note ---

///|
/// 音符 = 音高 + 时值 + 力度
pub(all) struct Note {
  pitch : Pitch
  duration : Duration
  velocity : Int
}

///|
/// 创建音符（使用默认力度 100）
pub fn note(pitch : Pitch, duration : Duration) -> Note {
  { pitch, duration, velocity: DEFAULT_VELOCITY }
}

///|
/// 创建音符（指定力度）
pub fn note_with_velocity(
  pitch : Pitch,
  duration : Duration,
  velocity : Int,
) -> Note {
  { pitch, duration, velocity }
}

///|
/// 音符移调（仅改变音高，时值和力度不变）
pub fn Note::transpose(self : Note, semitones : Int) -> Note {
  {
    pitch: self.pitch.transpose(semitones),
    duration: self.duration,
    velocity: self.velocity,
  }
}

///|
pub fn Note::to_string(self : Note) -> String {
  "\{self.pitch.to_string()} \{self.duration.to_string()} v=\{self.velocity}"
}

// --- 休止 Rest ---

///|
/// 休止符，只有时值
pub(all) struct Rest {
  duration : Duration
}

///|
pub fn rest(duration : Duration) -> Rest {
  { duration, }
}

///|
pub fn Rest::to_string(self : Rest) -> String {
  "rest \{self.duration.to_string()}"
}

// --- 音乐事件 MusicEvent ---

///|
/// 轨道中的音乐事件：音符或休止
pub(all) enum MusicEvent {
  Note(Note)
  Rest(Rest)
}

///|
/// 获取事件的时值
pub fn MusicEvent::duration(self : MusicEvent) -> Duration {
  match self {
    Note(n) => n.duration
    Rest(r) => r.duration
  }
}

///|
pub fn MusicEvent::to_string(self : MusicEvent) -> String {
  match self {
    Note(n) => n.to_string()
    Rest(r) => r.to_string()
  }
}

///|
/// 事件移调（休止不变，音符移调）
pub fn MusicEvent::transpose(self : MusicEvent, semitones : Int) -> MusicEvent {
  match self {
    Note(n) => Note(n.transpose(semitones))
    Rest(r) => Rest(r)
  }
}

// --- 轨道 Track ---

///|
/// 轨道 = 有序的音乐事件序列 + 通道号
pub(all) struct Track {
  events : Array[MusicEvent]
  channel : Int
}

///|
/// 创建轨道（默认通道 0）
pub fn track(events : Array[MusicEvent]) -> Track {
  { events, channel: 0 }
}

///|
/// 创建指定通道的轨道
pub fn track_with_channel(
  events : Array[MusicEvent],
  channel : Int,
) -> Track {
  { events, channel }
}

///|
pub fn empty_track() -> Track {
  { events: [], channel: 0 }
}

///|
/// 追加事件到轨道末尾
pub fn Track::append(self : Track, event : MusicEvent) -> Track {
  let new_events = self.events
  new_events.push(event)
  { events: new_events, channel: self.channel }
}

///|
/// 轨道的总拍数
pub fn Track::duration_beats(self : Track) -> Double {
  let mut total = 0.0
  for event in self.events {
    total = total + event.duration().beats()
  }
  total
}

///|
/// 轨道中的事件数量
pub fn Track::event_count(self : Track) -> Int {
  self.events.length()
}

///|
/// 轨道移调（休止不变，音符移调）
pub fn Track::transpose(self : Track, semitones : Int) -> Track {
  let new_events = []
  for event in self.events {
    new_events.push(event.transpose(semitones))
  }
  { events: new_events, channel: self.channel }
}

///|
/// 重复轨道 count 次
pub fn Track::repeat(self : Track, count : Int) -> Track {
  let new_events = []
  for i = 0; i < count; i = i + 1 {
    for event in self.events {
      new_events.push(event)
    }
  }
  { events: new_events, channel: self.channel }
}

///|
pub fn Track::to_string(self : Track) -> String {
  let mut result = "Track ch=\{self.channel} ["
  for i = 0; i < self.events.length(); i = i + 1 {
    result = result + self.events[i].to_string()
    if i < self.events.length() - 1 {
      result = result + ", "
    }
  }
  result + "]"
}

// --- 乐谱 Score ---

///|
/// 乐谱 = 速度 + 拍号 + 多条轨道
pub(all) struct Score {
  tempo : Tempo
  time_signature : TimeSignature
  tracks : Array[Track]
}

///|
/// 创建乐谱（默认速度 120，拍号 4/4）
pub fn score(tracks : Array[Track]) -> Score {
  { tempo: default_tempo(), time_signature: four_four(), tracks }
}

///|
/// 创建乐谱（指定速度和拍号）
pub fn score_with_tempo(
  tracks : Array[Track],
  tempo : Tempo,
  time_signature : TimeSignature,
) -> Score {
  { tempo, time_signature, tracks }
}

///|
/// 乐谱总拍数 = 最长轨道的拍数
pub fn Score::duration_beats(self : Score) -> Double {
  let mut max_beats = 0.0
  for track in self.tracks {
    let track_beats = track.duration_beats()
    if track_beats > max_beats {
      max_beats = track_beats
    }
  }
  max_beats
}

///|
/// 轨道数量
pub fn Score::track_count(self : Score) -> Int {
  self.tracks.length()
}

///|
/// 乐谱移调（所有轨道）
pub fn Score::transpose(self : Score, semitones : Int) -> Score {
  let new_tracks = []
  for track in self.tracks {
    new_tracks.push(track.transpose(semitones))
  }
  { tempo: self.tempo, time_signature: self.time_signature, tracks: new_tracks }
}

///|
pub fn Score::to_string(self : Score) -> String {
  let mut result = "Score tempo=\{self.tempo.to_string()} time=\{self.time_signature.to_string()}\n"
  for i = 0; i < self.tracks.length(); i = i + 1 {
    result = result + "  \{self.tracks[i].to_string()}\n"
  }
  result
}

