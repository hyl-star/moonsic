//
// 核心音乐模型
//

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

///|
pub const MAX_VELOCITY : Int = 127

///|
/// MIDI 音符范围：0-127
pub const MIN_MIDI_NOTE : Int = 0

///|
pub const MAX_MIDI_NOTE : Int = 127

///|
/// MIDI 通道范围：0-15
pub const MIN_CHANNEL : Int = 0

///|
pub const MAX_CHANNEL : Int = 15

///|
/// A4 的 MIDI 编号和频率
pub const A4_MIDI : Int = 69

///|
pub const A4_FREQ : Double = 440.0

// --- 音阶种类 ---

///|
pub(all) enum ScaleKind {
  Major
  NaturalMinor
  MajorPentatonic
  MinorPentatonic
  HarmonicMinor
  MelodicMinor
  Dorian
  Phrygian
  Lydian
  Mixolydian
  Locrian
  Chromatic
}

///|
pub fn ScaleKind::intervals(self : ScaleKind) -> Array[Int] {
  match self {
    Major => [0, 2, 4, 5, 7, 9, 11]
    NaturalMinor => [0, 2, 3, 5, 7, 8, 10]
    MajorPentatonic => [0, 2, 4, 7, 9]
    MinorPentatonic => [0, 3, 5, 7, 10]
    HarmonicMinor => [0, 2, 3, 5, 7, 8, 11]
    MelodicMinor => [0, 2, 3, 5, 7, 9, 11]
    Dorian => [0, 2, 3, 5, 7, 9, 10]
    Phrygian => [0, 1, 3, 5, 7, 8, 10]
    Lydian => [0, 2, 4, 6, 7, 9, 11]
    Mixolydian => [0, 2, 4, 5, 7, 9, 10]
    Locrian => [0, 1, 3, 5, 6, 8, 10]
    Chromatic => [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
  }
}

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
/// 变音记号：重降、降、还原、升、重升
pub(all) enum Accidental {
  DoubleFlat
  Flat
  Natural
  Sharp
  DoubleSharp
}

///|
/// 获取变音记号的半音偏移量（重降=-2，降=-1，还原=0，升=+1，重升=+2）
pub fn Accidental::semitone_offset(self : Accidental) -> Int {
  match self {
    DoubleFlat => -2
    Flat => -1
    Natural => 0
    Sharp => 1
    DoubleSharp => 2
  }
}

///|
/// 转为字符串表示（重降="bb", 降="b", 还原="", 升="#", 重升="x"）
pub fn Accidental::to_string(self : Accidental) -> String {
  match self {
    DoubleFlat => "bb"
    Flat => "b"
    Natural => ""
    Sharp => "#"
    DoubleSharp => "x"
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
/// v1.5 推荐名，等价于 natural()
pub fn natural_pitch(class : PitchClass, octave : Int) -> Pitch {
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
/// Safe MIDI conversion. Returns MidiOutOfRange when the pitch is outside 0..127.
pub fn Pitch::to_midi_checked(self : Pitch) -> Result[Int, TheoryError] {
  let midi = self.to_midi()
  if is_valid_midi_note(midi) {
    Ok(midi)
  } else {
    Err(MidiOutOfRange(midi))
  }
}

///|
/// Function-style safe MIDI conversion for wrapper layers.
pub fn pitch_to_midi(p : Pitch) -> Result[Int, TheoryError] {
  p.to_midi_checked()
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
/// Safe transposition. The old transpose method is kept for compatibility.
pub fn Pitch::transpose_checked(
  self : Pitch,
  semitones : Int,
) -> Result[Pitch, TheoryError] {
  midi_to_pitch_checked(self.to_midi() + semitones)
}

///|
/// Function-style safe transposition for callers that prefer Result APIs.
pub fn transpose_pitch(
  p : Pitch,
  semitones : Int,
) -> Result[Pitch, TheoryError] {
  p.transpose_checked(semitones)
}

///|
/// 转为字符串，如 "C4", "C#4", "Db4"
pub fn Pitch::to_string(self : Pitch) -> String {
  "\{self.class.to_string()}\{self.accidental.to_string()}\{self.octave}"
}

///|
/// Safe MIDI number to Pitch conversion. Uses sharp spelling.
pub fn midi_to_pitch_checked(midi : Int) -> Result[Pitch, TheoryError] {
  if !is_valid_midi_note(midi) {
    return Err(MidiOutOfRange(midi))
  }
  Ok(midi_to_pitch(midi))
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

// --- 音高比较 ---

///|
/// 比较两个音高是否拼写完全相同（字母、变音记号、八度均相同）。
/// C#4 与 Db4 虽然等音（MIDI 相同），但拼写不同，返回 false。
pub fn pitch_equal(a : Pitch, b : Pitch) -> Bool {
  let class_eq = match a.class {
    C =>
      match b.class {
        C => true
        _ => false
      }
    D =>
      match b.class {
        D => true
        _ => false
      }
    E =>
      match b.class {
        E => true
        _ => false
      }
    F =>
      match b.class {
        F => true
        _ => false
      }
    G =>
      match b.class {
        G => true
        _ => false
      }
    A =>
      match b.class {
        A => true
        _ => false
      }
    B =>
      match b.class {
        B => true
        _ => false
      }
  }
  let acc_eq = match a.accidental {
    DoubleFlat =>
      match b.accidental {
        DoubleFlat => true
        _ => false
      }
    Flat =>
      match b.accidental {
        Flat => true
        _ => false
      }
    Natural =>
      match b.accidental {
        Natural => true
        _ => false
      }
    Sharp =>
      match b.accidental {
        Sharp => true
        _ => false
      }
    DoubleSharp =>
      match b.accidental {
        DoubleSharp => true
        _ => false
      }
  }
  class_eq && acc_eq && a.octave == b.octave
}

///|
/// 比较两个音高是否等音（MIDI 编号相同，忽略拼写差异）。
/// 例如 C#4 和 Db4 等音，返回 true。
pub fn enharmonic_equal(a : Pitch, b : Pitch) -> Bool {
  a.to_midi() == b.to_midi()
}

///|
/// 按 MIDI 编号比较音高，返回 -1（a<b）、0（相等）、1（a>b）。
pub fn pitch_compare(a : Pitch, b : Pitch) -> Int {
  let a_midi = a.to_midi()
  let b_midi = b.to_midi()
  if a_midi < b_midi {
    -1
  } else if a_midi > b_midi {
    1
  } else {
    0
  }
}

///|
/// 按数值比较 MIDI 编号，返回 -1、0 或 1。
pub fn midi_note_compare(a : Int, b : Int) -> Int {
  if a < b {
    -1
  } else if a > b {
    1
  } else {
    0
  }
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
  Dotted(Duration)
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
    Dotted(base) => base.beats() * 1.5
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
    Dotted(base) => "dotted \{base.to_string()}"
  }
}

///|
/// 附点时值 = 基础时值 × 1.5
pub fn dotted(duration : Duration) -> Duration {
  Dotted(duration)
}

// --- 速度 Tempo ---

///|
/// 速度，以 BPM 表示
pub(all) struct Tempo {
  bpm : Int
}

///|
/// 创建速度，BPM 必须 > 0
/// Legacy throwing tempo constructor. Prefer `tempo_checked` in library/FFI code.
pub fn tempo(bpm : Int) -> Tempo {
  if bpm <= 0 {
    abort("tempo: BPM 必须 > 0，实际值：\{bpm}")
  }
  { bpm, }
}

///|
/// Safe Tempo constructor for library/FFI code.
pub fn tempo_checked(bpm : Int) -> Result[Tempo, TimeError] {
  if bpm <= 0 {
    Err(InvalidTempo("BPM must be > 0, got \{bpm}"))
  } else {
    Ok({ bpm, })
  }
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
pub fn Note::transpose_checked(
  self : Note,
  semitones : Int,
) -> Result[Note, TheoryError] {
  match self.pitch.transpose_checked(semitones) {
    Ok(p) => Ok({ pitch: p, duration: self.duration, velocity: self.velocity })
    Err(e) => Err(e)
  }
}

///|
pub fn Note::to_string(self : Note) -> String {
  "\{self.pitch.to_string()} \{self.duration.to_string()} v=\{self.velocity}"
}

// --- 和弦 Chord ---

///|
/// 和弦 = 多个音高 + 时值 + 力度
pub(all) struct Chord {
  pitches : Array[Pitch]
  duration : Duration
  velocity : Int
}

///|
/// 创建和弦（默认力度 100）
pub fn chord(pitches : Array[Pitch], duration : Duration) -> Chord {
  { pitches, duration, velocity: DEFAULT_VELOCITY }
}

///|
/// 创建和弦（指定力度）
pub fn chord_with_velocity(
  pitches : Array[Pitch],
  duration : Duration,
  velocity : Int,
) -> Chord {
  { pitches, duration, velocity }
}

///|
pub fn Chord::transpose(self : Chord, semitones : Int) -> Chord {
  let new_pitches = []
  for p in self.pitches {
    new_pitches.push(p.transpose(semitones))
  }
  { pitches: new_pitches, duration: self.duration, velocity: self.velocity }
}

///|
pub fn Chord::transpose_checked(
  self : Chord,
  semitones : Int,
) -> Result[Chord, TheoryError] {
  let new_pitches = []
  for p in self.pitches {
    match p.transpose_checked(semitones) {
      Ok(tp) => new_pitches.push(tp)
      Err(e) => return Err(e)
    }
  }
  Ok({ pitches: new_pitches, duration: self.duration, velocity: self.velocity })
}

///|
/// 和弦转位：将最低音升高八度，重复 times 次
pub fn Chord::invert(self : Chord, times : Int) -> Chord {
  if times <= 0 || self.pitches.length() <= 1 {
    return self
  }
  let n = times % self.pitches.length()
  let new_pitches = []
  for i = 0; i < self.pitches.length(); i = i + 1 {
    let src_idx = i + n
    let p = if src_idx >= self.pitches.length() {
      self.pitches[src_idx - self.pitches.length()].transpose(12)
    } else {
      self.pitches[src_idx]
    }
    new_pitches.push(p)
  }
  { pitches: new_pitches, duration: self.duration, velocity: self.velocity }
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
  Chord(Chord)
}

///|
/// 获取事件的时值
pub fn MusicEvent::duration(self : MusicEvent) -> Duration {
  match self {
    Note(n) => n.duration
    Rest(r) => r.duration
    Chord(c) => c.duration
  }
}

///|
pub fn MusicEvent::to_string(self : MusicEvent) -> String {
  match self {
    Note(n) => n.to_string()
    Rest(r) => r.to_string()
    Chord(c) => "chord [\{c.pitches.length()} notes] \{c.duration.to_string()}"
  }
}

///|
/// 事件移调（休止不变，音符/和弦移调）
pub fn MusicEvent::transpose(self : MusicEvent, semitones : Int) -> MusicEvent {
  match self {
    Note(n) => Note(n.transpose(semitones))
    Rest(r) => Rest(r)
    Chord(c) => Chord(c.transpose(semitones))
  }
}

///|
pub fn MusicEvent::transpose_checked(
  self : MusicEvent,
  semitones : Int,
) -> Result[MusicEvent, TheoryError] {
  match self {
    Note(n) =>
      match n.transpose_checked(semitones) {
        Ok(v) => Ok(Note(v))
        Err(e) => Err(e)
      }
    Rest(r) => Ok(Rest(r))
    Chord(c) =>
      match c.transpose_checked(semitones) {
        Ok(v) => Ok(Chord(v))
        Err(e) => Err(e)
      }
  }
}

// --- 轨道 Track ---

///|
/// 轨道 = 有序的音乐事件序列 + 通道号
pub(all) struct Track {
  events : Array[MusicEvent]
  channel : Int
  program : Int // -1 = 未设置乐器
  volume : Double // 0.0.., 默认 1.0
  pan : Double // -1.0 左 .. 1.0 右, 默认 0.0
  mute : Bool
}

///|
/// 创建轨道（默认通道 0，无乐器）
pub fn track(events : Array[MusicEvent]) -> Track {
  { events, channel: 0, program: -1, volume: 1.0, pan: 0.0, mute: false }
}

///|
/// 创建指定通道的轨道
pub fn track_with_channel(events : Array[MusicEvent], channel : Int) -> Track {
  { events, channel, program: -1, volume: 1.0, pan: 0.0, mute: false }
}

///|
pub fn empty_track() -> Track {
  { events: [], channel: 0, program: -1, volume: 1.0, pan: 0.0, mute: false }
}

///|
/// 设置轨道音量（0.0..，默认 1.0）
pub fn Track::with_volume(self : Track, v : Double) -> Track {
  {
    events: self.events,
    channel: self.channel,
    program: self.program,
    volume: v,
    pan: self.pan,
    mute: self.mute,
  }
}

///|
/// 设置轨道声像（-1.0 左 .. 1.0 右，默认 0.0 居中）
pub fn Track::with_pan(self : Track, p : Double) -> Track {
  {
    events: self.events,
    channel: self.channel,
    program: self.program,
    volume: self.volume,
    pan: p,
    mute: self.mute,
  }
}

///|
/// 设置轨道静音
pub fn Track::with_mute(self : Track, m : Bool) -> Track {
  {
    events: self.events,
    channel: self.channel,
    program: self.program,
    volume: self.volume,
    pan: self.pan,
    mute: m,
  }
}

///|
/// 追加事件到轨道末尾（返回新轨道，不修改原轨道）
pub fn Track::append(self : Track, event : MusicEvent) -> Track {
  let new_events = []
  for e in self.events {
    new_events.push(e)
  }
  new_events.push(event)
  {
    events: new_events,
    channel: self.channel,
    program: self.program,
    volume: self.volume,
    pan: self.pan,
    mute: self.mute,
  }
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
  {
    events: new_events,
    channel: self.channel,
    program: self.program,
    volume: self.volume,
    pan: self.pan,
    mute: self.mute,
  }
}

///|
pub fn Track::transpose_checked(
  self : Track,
  semitones : Int,
) -> Result[Track, TheoryError] {
  let new_events = []
  for event in self.events {
    match event.transpose_checked(semitones) {
      Ok(v) => new_events.push(v)
      Err(e) => return Err(e)
    }
  }
  Ok({
    events: new_events,
    channel: self.channel,
    program: self.program,
    volume: self.volume,
    pan: self.pan,
    mute: self.mute,
  })
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
  {
    events: new_events,
    channel: self.channel,
    program: self.program,
    volume: self.volume,
    pan: self.pan,
    mute: self.mute,
  }
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
  master_gain : Double // 默认 0.85
}

///|
/// 创建乐谱（默认速度 120，拍号 4/4）
pub fn score(tracks : Array[Track]) -> Score {
  {
    tempo: default_tempo(),
    time_signature: four_four(),
    tracks,
    master_gain: 0.85,
  }
}

///|
/// 创建乐谱（指定速度和拍号）
pub fn score_with_tempo(
  tracks : Array[Track],
  tempo : Tempo,
  time_signature : TimeSignature,
) -> Score {
  { tempo, time_signature, tracks, master_gain: 0.85 }
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
  {
    tempo: self.tempo,
    time_signature: self.time_signature,
    tracks: new_tracks,
    master_gain: self.master_gain,
  }
}

///|
pub fn Score::transpose_checked(
  self : Score,
  semitones : Int,
) -> Result[Score, TheoryError] {
  let new_tracks = []
  for track in self.tracks {
    match track.transpose_checked(semitones) {
      Ok(v) => new_tracks.push(v)
      Err(e) => return Err(e)
    }
  }
  Ok({
    tempo: self.tempo,
    time_signature: self.time_signature,
    tracks: new_tracks,
    master_gain: self.master_gain,
  })
}

///|
pub fn Score::to_string(self : Score) -> String {
  let mut result = "Score tempo=\{self.tempo.to_string()} time=\{self.time_signature.to_string()}\n"
  for i = 0; i < self.tracks.length(); i = i + 1 {
    result = result + "  \{self.tracks[i].to_string()}\n"
  }
  result
}
