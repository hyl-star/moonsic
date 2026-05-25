// ============================================================
// Game Music IR 模块 (v2 Phase 1-5)
// 游戏动态音乐 IR — 类型定义、构造器、校验、导出
// ============================================================

// ============================================================
// 辅助类型（桥接到已有 moonsic 类型，或为 v2 内部使用）
// ============================================================

///|
/// 音乐时间定位：小节 + 拍 + tick 偏移
pub(all) struct MusicalTime {
  bar : Int
  beat : Double
  tick : Int
}

///|
/// 默认音乐时间
pub fn musical_time(bar : Int, beat : Double, tick : Int) -> MusicalTime {
  { bar, beat, tick }
}

///|
/// 零时间点
pub fn musical_time_zero() -> MusicalTime {
  { bar: 0, beat: 0.0, tick: 0 }
}

///|
/// 辅助：创建 ScoreFragment（利用 adapter 模块的 ScoreFragment 类型）
pub fn score_fragment_from_track(
  track : Track,
  start_bar : Int,
  length_bars : Int,
) -> ScoreFragment {
  { tracks: [track], start_bar, length_bars }
}

///|
pub fn score_fragment_empty() -> ScoreFragment {
  { tracks: [], start_bar: 0, length_bars: 0 }
}

///|
/// 简化 Timeline Entry 表示（v2 桥接类型）
pub(all) struct GameTimelineEntry {
  tick : Int
  channel : Int
  note : Int
  velocity : Int
  is_note_on : Bool
  duration_ticks : Int
}

///|
/// Game 用的 Timeline 桥接
pub(all) struct GameTimelineSource {
  entries : Array[GameTimelineEntry]
  ppq : Int
  total_ticks : Int
}

///|
/// 从 Track 创建 GameTimelineSource
pub fn game_timeline_from_track(track : Track, ppq : Int) -> GameTimelineSource {
  let entries : Array[GameTimelineEntry] = []
  let mut current_tick = 0
  for evt in track.events {
    let dur_ticks = evt.duration().ticks(ppq)
    match evt {
      Note(n) => {
        let midi = n.pitch.to_midi()
        entries.push(GameTimelineEntry::{
          tick: current_tick,
          channel: track.channel,
          note: midi,
          velocity: n.velocity,
          is_note_on: true,
          duration_ticks: dur_ticks,
        })
      }
      Chord(c) =>
        for p in c.pitches {
          let midi = p.to_midi()
          entries.push(GameTimelineEntry::{
            tick: current_tick,
            channel: track.channel,
            note: midi,
            velocity: c.velocity,
            is_note_on: true,
            duration_ticks: dur_ticks,
          })
        }
      Rest(_) => ()
    }
    current_tick = current_tick + dur_ticks
  }
  { entries, ppq, total_ticks: current_tick }
}

///|
/// BrowserEventDocument — v2 桥接类型，给 web demo 消费
pub(all) struct BrowserEventDocument {
  events : Array[GameTimelineEntry]
  ppq : Int
  tempo_bpm : Int
  loop_enabled : Bool
  loop_start_ticks : Int
  loop_end_ticks : Int
}

///|
/// AudioAssetRef — 外部音频资产引用（协议预留）
pub(all) struct AudioAssetRef {
  uri : String
  asset_type : String
  format : String
}

///|
/// ScoreLayout 桥接（简化表示）
pub(all) struct GameScoreLayoutRef {
  title : String
  ppq : Int
  part_count : Int
}

// ============================================================
// 错误类型
// ============================================================

///|
/// 游戏音乐错误类型
pub(all) enum GameMusicError {
  InvalidProjectId(String)
  DuplicateCueId(String)
  MissingCue(String)
  InvalidCue(String)
  EmptyCue(String)
  EmptySegment(String)
  InvalidSegmentDuration(String)
  InvalidLoopRegion(String)
  InvalidMarkerPosition(String)
  DuplicateMarkerId(String)
  InvalidTransitionRule(String)
  MissingTransitionTarget(String)
  InvalidTrigger(String)
  InvalidParameter(String)
  InvalidLayer(String)
  UnsupportedGameFeature(String)
  TimelineConversionFailed(String)
  ValidationFailed(String)
  SerializationFailed(String)
}

///|
pub fn GameMusicError::to_string(self : GameMusicError) -> String {
  match self {
    InvalidProjectId(msg) => "无效项目ID：" + msg
    DuplicateCueId(msg) => "重复CueID：" + msg
    MissingCue(msg) => "缺少Cue：" + msg
    InvalidCue(msg) => "无效Cue：" + msg
    EmptyCue(msg) => "空Cue：" + msg
    EmptySegment(msg) => "空Segment：" + msg
    InvalidSegmentDuration(msg) => "无效Segment时值：" + msg
    InvalidLoopRegion(msg) => "无效循环区域：" + msg
    InvalidMarkerPosition(msg) => "无效标记位置：" + msg
    DuplicateMarkerId(msg) => "重复标记ID：" + msg
    InvalidTransitionRule(msg) => "无效过渡规则：" + msg
    MissingTransitionTarget(msg) => "缺少过渡目标：" + msg
    InvalidTrigger(msg) => "无效触发器：" + msg
    InvalidParameter(msg) => "无效参数：" + msg
    InvalidLayer(msg) => "无效层级：" + msg
    UnsupportedGameFeature(msg) => "不支持的游戏功能：" + msg
    TimelineConversionFailed(msg) => "时间线转换失败：" + msg
    ValidationFailed(msg) => "校验失败：" + msg
    SerializationFailed(msg) => "序列化失败：" + msg
  }
}

// ============================================================
// GameCueKind
// ============================================================

///|
pub(all) enum GameCueKind {
  LinearCue
  LoopCue
  StingerCue
  TransitionCue
  LayeredCue
  AdaptiveCue
  MenuCue
  CombatCue
  AmbienceCue
}

///|
pub fn GameCueKind::is_default_loop(self : GameCueKind) -> Bool {
  match self {
    LinearCue | StingerCue | TransitionCue => false
    LoopCue | MenuCue | CombatCue | AmbienceCue => true
    LayeredCue | AdaptiveCue => false
  }
}

///|
pub fn GameCueKind::to_string(self : GameCueKind) -> String {
  match self {
    LinearCue => "linear"
    LoopCue => "loop"
    StingerCue => "stinger"
    TransitionCue => "transition"
    LayeredCue => "layered"
    AdaptiveCue => "adaptive"
    MenuCue => "menu"
    CombatCue => "combat"
    AmbienceCue => "ambience"
  }
}

// ============================================================
// LoopRegion
// ============================================================

///|
pub(all) struct LoopRegion {
  id : String
  start : MusicalTime
  end : MusicalTime
  quantization : TransitionQuantization
  max_repeats : Int?
}

///|
pub(all) enum TransitionQuantization {
  Immediate
  NextBeat
  NextBar
  NextPhrase(Int)
  AtMarker(String)
}

///|
pub fn TransitionQuantization::to_string(
  self : TransitionQuantization,
) -> String {
  match self {
    Immediate => "immediate"
    NextBeat => "next-beat"
    NextBar => "next-bar"
    NextPhrase(n) => {
      let s = n.to_string()
      "next-phrase-" + s
    }
    AtMarker(id) => "at-marker-" + id
  }
}

// ============================================================
// GameTrigger
// ============================================================

///|
pub(all) enum GameTrigger {
  TriggerImmediate
  TriggerOnState(String)
  TriggerOnParameter(String, ParameterCompare, Double)
  TriggerOnMarker(String)
  TriggerManual(String)
}

///|
pub(all) enum ParameterCompare {
  Equal
  NotEqual
  GreaterThan
  GreaterOrEqual
  LessThan
  LessOrEqual
}

///|
pub fn ParameterCompare::to_string(self : ParameterCompare) -> String {
  match self {
    Equal => "=="
    NotEqual => "!="
    GreaterThan => ">"
    GreaterOrEqual => ">="
    LessThan => "<"
    LessOrEqual => "<="
  }
}

// ============================================================
// TransitionBehavior
// ============================================================

///|
pub(all) enum TransitionBehavior {
  Cut
  Crossfade(Double)
  PlayStingerThenSwitch(String)
  WaitThenSwitch(Double)
  LayerFade(GameLayerFade)
}

///|
pub(all) struct GameLayerFade {
  fade_in_layers : Array[String]
  fade_out_layers : Array[String]
  crossfade_seconds : Double
}

// ============================================================
// TransitionCondition
// ============================================================

///|
pub(all) enum TransitionCondition {
  Always
  OnState(String)
  OnParam(String, ParameterCompare, Double)
  OnMarker(String)
  AfterLoops(Int)
}

// ============================================================
// Stinger
// ============================================================

///|
pub(all) enum StingerPolicy {
  InterruptCurrent
  PlayToEndThenSwitch
  OverlayAndFade
}

///|
pub(all) struct Stinger {
  id : String
  trigger : GameTrigger
  segment : GameSegment
  quantization : TransitionQuantization
  priority : Int
  policy : StingerPolicy
}

// ============================================================
// GameSegment
// ============================================================

///|
pub(all) enum GameSegmentSource {
  ScoreFragmentSource(ScoreFragment)
  ScoreLayoutSource(GameScoreLayoutRef)
  TimelineSource(GameTimelineSource)
  ExternalAssetSource(AudioAssetRef)
  EmptySegmentSource
}

///|
pub(all) struct GameSegment {
  id : String
  label : String
  source : GameSegmentSource
  start : MusicalTime
  duration_beats : Double
  loop_region : LoopRegion?
  markers : Array[GameMarker]
  layers : Array[GameLayer]
  intensity_level : Int
  tags : Array[String]
}

// ============================================================
// GameLayer
// ============================================================

///|
pub(all) enum GameLayerRole {
  LayerMelody
  LayerHarmony
  LayerBass
  LayerDrums
  LayerPercussion
  LayerPad
  LayerFx
  LayerCustom(String)
}

///|
pub fn GameLayerRole::to_string(self : GameLayerRole) -> String {
  match self {
    LayerMelody => "melody"
    LayerHarmony => "harmony"
    LayerBass => "bass"
    LayerDrums => "drums"
    LayerPercussion => "percussion"
    LayerPad => "pad"
    LayerFx => "fx"
    LayerCustom(name) => "custom:" + name
  }
}

///|
pub(all) struct LayerParameterBinding {
  parameter_id : String
  min_value : Double
  max_value : Double
  response : Double
}

///|
pub(all) struct GameLayer {
  id : String
  name : String
  source_track_id : String
  role : GameLayerRole
  default_gain : Double
  parameter_binding : LayerParameterBinding?
}

// ============================================================
// GameMarker
// ============================================================

///|
pub(all) enum GameMarkerKind {
  EntryMarker
  ExitMarker
  LoopStartMarker
  LoopEndMarker
  PhraseStartMarker
  PhraseEndMarker
  SyncMarker
  CustomMarker(String)
}

///|
pub fn GameMarkerKind::to_string(self : GameMarkerKind) -> String {
  match self {
    EntryMarker => "entry"
    ExitMarker => "exit"
    LoopStartMarker => "loop-start"
    LoopEndMarker => "loop-end"
    PhraseStartMarker => "phrase-start"
    PhraseEndMarker => "phrase-end"
    SyncMarker => "sync"
    CustomMarker(name) => "custom:" + name
  }
}

///|
pub(all) struct GameMarker {
  id : String
  kind : GameMarkerKind
  position : MusicalTime
  label : String
}

// ============================================================
// CueEntryPoint / CueExitPoint
// ============================================================

///|
pub(all) struct CueEntryPoint {
  id : String
  label : String
  position : MusicalTime
  conditions : Array[TransitionCondition]
}

///|
pub(all) struct CueExitPoint {
  id : String
  label : String
  position : MusicalTime
  target_cue : String
  transition_behavior : TransitionBehavior
}

// ============================================================
// GameCue
// ============================================================

///|
pub(all) struct GameCue {
  id : String
  name : String
  kind : GameCueKind
  segments : Array[GameSegment]
  entry_points : Array[CueEntryPoint]
  exit_points : Array[CueExitPoint]
  default_loop : LoopRegion?
  layers : Array[GameLayer]
  tags : Array[String]
  metadata : GameMusicMetadata
}

// ============================================================
// MusicState
// ============================================================

///|
pub(all) struct MusicState {
  id : String
  name : String
  default_cue : String
  tags : Array[String]
}

// ============================================================
// MusicParameter
// ============================================================

///|
pub(all) enum MusicParameterKind {
  Continuous
  Discrete
  Boolean
}

///|
pub(all) struct MusicParameter {
  id : String
  name : String
  kind : MusicParameterKind
  default_value : Double
  min_value : Double
  max_value : Double
}

// ============================================================
// TransitionRule
// ============================================================

///|
pub(all) struct TransitionRule {
  id : String
  from_cue : String
  to_cue : String
  trigger : GameTrigger
  quantization : TransitionQuantization
  behavior : TransitionBehavior
  condition : TransitionCondition
  priority : Int
}

// ============================================================
// GameMusicMetadata
// ============================================================

///|
pub(all) struct GameMusicMetadata {
  author : String
  description : String
  mood : String
  intensity : Double
}

///|
pub fn empty_game_metadata() -> GameMusicMetadata {
  { author: "", description: "", mood: "", intensity: 0.5 }
}

// ============================================================
// GameMusicProject
// ============================================================

///|
pub(all) struct GameMusicProject {
  id : String
  name : String
  tempo_bpm : Int
  time_signature : TimeSignature
  cues : Array[GameCue]
  states : Array[MusicState]
  parameters : Array[MusicParameter]
  transitions : Array[TransitionRule]
  metadata : GameMusicMetadata
}

// ============================================================
// 校验类型
// ============================================================

///|
pub(all) enum GameIssueSeverity {
  GameInfo
  GameWarning
  GameError
}

///|
pub fn GameIssueSeverity::to_string(self : GameIssueSeverity) -> String {
  match self {
    GameInfo => "Info"
    GameWarning => "Warning"
    GameError => "Error"
  }
}

///|
pub(all) enum GameIssueCode {
  CueHasNoSegments
  DuplicateCue
  MissingDefaultCue
  InvalidLoopRange
  LoopNotBarAligned
  TransitionTargetMissing
  TransitionUnreachable
  MarkerOutsideSegment
  LayerTrackMissing
  ParameterOutOfRange
  UnsupportedRuntimeBehavior
}

///|
pub fn GameIssueCode::to_string(self : GameIssueCode) -> String {
  match self {
    CueHasNoSegments => "CueHasNoSegments"
    DuplicateCue => "DuplicateCue"
    MissingDefaultCue => "MissingDefaultCue"
    InvalidLoopRange => "InvalidLoopRange"
    LoopNotBarAligned => "LoopNotBarAligned"
    TransitionTargetMissing => "TransitionTargetMissing"
    TransitionUnreachable => "TransitionUnreachable"
    MarkerOutsideSegment => "MarkerOutsideSegment"
    LayerTrackMissing => "LayerTrackMissing"
    ParameterOutOfRange => "ParameterOutOfRange"
    UnsupportedRuntimeBehavior => "UnsupportedRuntimeBehavior"
  }
}

///|
pub fn GameIssueCode::default_severity(
  self : GameIssueCode,
) -> GameIssueSeverity {
  match self {
    CueHasNoSegments
    | DuplicateCue
    | InvalidLoopRange
    | TransitionTargetMissing
    | MarkerOutsideSegment
    | ParameterOutOfRange => GameError
    MissingDefaultCue
    | LoopNotBarAligned
    | TransitionUnreachable
    | LayerTrackMissing
    | UnsupportedRuntimeBehavior => GameWarning
  }
}

///|
pub(all) struct GameValidationIssue {
  severity : GameIssueSeverity
  code : GameIssueCode
  path : String
  message : String
  suggestion : String
}

///|
pub(all) struct GameValidationSummary {
  total_issues : Int
  error_count : Int
  warning_count : Int
  info_count : Int
}

///|
pub(all) struct GameValidationReport {
  issues : Array[GameValidationIssue]
  summary : GameValidationSummary
}

///|
pub fn empty_game_validation_report() -> GameValidationReport {
  {
    issues: [],
    summary: {
      total_issues: 0,
      error_count: 0,
      warning_count: 0,
      info_count: 0,
    },
  }
}

///|
pub fn game_validation_report_has_errors(report : GameValidationReport) -> Bool {
  report.summary.error_count > 0
}

///|
pub fn game_validation_report_to_json(report : GameValidationReport) -> String {
  let mut result = "{"
  result = result +
    "\"error_count\":" +
    report.summary.error_count.to_string() +
    ","
  result = result +
    "\"warning_count\":" +
    report.summary.warning_count.to_string() +
    ","
  result = result +
    "\"info_count\":" +
    report.summary.info_count.to_string() +
    ","
  result = result +
    "\"total_issues\":" +
    report.summary.total_issues.to_string() +
    ","
  result = result + "\"issues\":[]"
  result = result + "}"
  result
}

///|
pub fn game_validation_report_is_export_blocking(
  report : GameValidationReport,
) -> Bool {
  report.summary.error_count > 0
}

// ============================================================
// 导出类型
// ============================================================

///|
pub(all) struct GameTimelineExport {
  cue_id : String
  timeline : GameTimelineSource
  loop_enabled : Bool
  loop_start_ticks : Int
  loop_end_ticks : Int
}

///|
pub(all) struct GameAssetExport {
  asset_id : String
  asset_type : String
  uri : String
}

///|
pub(all) struct GameMusicExportDocument {
  schema_version : String
  project_id : String
  project_name : String
  timelines : Array[GameTimelineExport]
  assets : Array[GameAssetExport]
  validation : GameValidationReport
}

// ============================================================
// 选项类型
// ============================================================

///|
pub(all) struct GameSegmentOptions {
  label : String
  intensity : Int
  tags : Array[String]
}

///|
pub(all) struct GameTimelineOptions {
  ppq : Int
  enable_loop : Bool
  include_markers : Bool
}

///|
pub(all) struct GameBrowserExportOptions {
  ppq : Int
  enable_loop : Bool
  include_markers : Bool
}

///|
pub(all) struct GameExportOptions {
  schema_version : String
  include_timelines : Bool
  include_validation_report : Bool
  strict : Bool
}

///|
pub fn default_game_export_options() -> GameExportOptions {
  {
    schema_version: "2.0",
    include_timelines: false,
    include_validation_report: true,
    strict: false,
  }
}

///|
pub fn default_game_timeline_options() -> GameTimelineOptions {
  { ppq: 480, enable_loop: false, include_markers: false }
}

///|
pub fn default_game_segment_options() -> GameSegmentOptions {
  { label: "", intensity: 5, tags: [] }
}

// ============================================================
// 内部辅助函数
// ============================================================

///|
/// 在数组中查找重复字符串（用于检测重复 cue id）
fn _has_duplicate_string(arr : Array[String]) -> Bool {
  for i = 0; i < arr.length(); i = i + 1 {
    for j = i + 1; j < arr.length(); j = j + 1 {
      if arr[i] == arr[j] {
        return true
      }
    }
  }
  false
}

///|
/// 在数组中查找字符串
fn _array_contains_string(arr : Array[String], target : String) -> Bool {
  for i = 0; i < arr.length(); i = i + 1 {
    if arr[i] == target {
      return true
    }
  }
  false
}

///|
/// 提取所有 cue id 为 String array
fn _extract_cue_ids(cues : Array[GameCue]) -> Array[String] {
  let ids : Array[String] = []
  for cue in cues {
    ids.push(cue.id)
  }
  ids
}

// ============================================================
// 构造 API (checked)
// ============================================================

///|
pub fn game_project_checked(
  id : String,
  name : String,
  cues : Array[GameCue],
) -> Result[GameMusicProject, GameMusicError] {
  if id == "" {
    return Err(InvalidProjectId("项目ID不能为空"))
  }
  let cue_ids = _extract_cue_ids(cues)
  if _has_duplicate_string(cue_ids) {
    return Err(DuplicateCueId("存在重复的 Cue ID"))
  }
  Ok({
    id,
    name,
    tempo_bpm: 120,
    time_signature: four_four(),
    cues,
    states: [],
    parameters: [],
    transitions: [],
    metadata: empty_game_metadata(),
  })
}

///|
pub fn game_project_full_checked(
  id : String,
  name : String,
  cues : Array[GameCue],
  states : Array[MusicState],
  parameters : Array[MusicParameter],
  transitions : Array[TransitionRule],
) -> Result[GameMusicProject, GameMusicError] {
  if id == "" {
    return Err(InvalidProjectId("项目ID不能为空"))
  }
  let cue_ids = _extract_cue_ids(cues)
  if _has_duplicate_string(cue_ids) {
    return Err(DuplicateCueId("存在重复的 Cue ID"))
  }
  // 校验 transition 的 from/to cue 存在
  for tr in transitions {
    if not(_array_contains_string(cue_ids, tr.from_cue)) {
      return Err(
        MissingTransitionTarget(
          "transition 来源 cue 不存在: " + tr.from_cue,
        ),
      )
    }
    if not(_array_contains_string(cue_ids, tr.to_cue)) {
      return Err(
        MissingTransitionTarget("transition 目标 cue 不存在: " + tr.to_cue),
      )
    }
  }
  // 校验 state 的 default_cue 存在
  for s in states {
    if s.default_cue != "" &&
      not(_array_contains_string(cue_ids, s.default_cue)) {
      return Err(MissingCue("state 默认cue不存在: " + s.default_cue))
    }
  }
  Ok({
    id,
    name,
    tempo_bpm: 120,
    time_signature: four_four(),
    cues,
    states,
    parameters,
    transitions,
    metadata: empty_game_metadata(),
  })
}

///|
pub fn game_cue_checked(
  id : String,
  name : String,
  kind : GameCueKind,
  segments : Array[GameSegment],
) -> Result[GameCue, GameMusicError] {
  if id == "" {
    return Err(InvalidCue("Cue ID不能为空"))
  }
  Ok({
    id,
    name,
    kind,
    segments,
    entry_points: [],
    exit_points: [],
    default_loop: None,
    layers: [],
    tags: [],
    metadata: empty_game_metadata(),
  })
}

///|
pub fn game_segment_from_fragment_checked(
  id : String,
  label : String,
  fragment : ScoreFragment,
  duration_beats : Double,
) -> Result[GameSegment, GameMusicError] {
  if id == "" {
    return Err(EmptySegment("segment ID不能为空"))
  }
  if duration_beats <= 0.0 {
    return Err(InvalidSegmentDuration("segment 时值必须 > 0"))
  }
  Ok({
    id,
    label,
    source: ScoreFragmentSource(fragment),
    start: musical_time_zero(),
    duration_beats,
    loop_region: None,
    markers: [],
    layers: [],
    intensity_level: 5,
    tags: [],
  })
}

///|
pub fn game_segment_from_timeline_checked(
  id : String,
  label : String,
  timeline : GameTimelineSource,
) -> Result[GameSegment, GameMusicError] {
  if id == "" {
    return Err(EmptySegment("segment ID不能为空"))
  }
  Ok({
    id,
    label,
    source: TimelineSource(timeline),
    start: musical_time_zero(),
    duration_beats: timeline.total_ticks.to_double() /
    timeline.ppq.to_double() *
    4.0,
    loop_region: None,
    markers: [],
    layers: [],
    intensity_level: 5,
    tags: [],
  })
}

///|
pub fn loop_region_checked(
  id : String,
  start : MusicalTime,
  end : MusicalTime,
  quantization : TransitionQuantization,
) -> Result[LoopRegion, GameMusicError] {
  if end.bar < start.bar || (end.bar == start.bar && end.beat <= start.beat) {
    return Err(InvalidLoopRegion("循环结束必须大于循环开始"))
  }
  Ok({ id, start, end, quantization, max_repeats: None })
}

///|
pub fn loop_region_with_repeats_checked(
  id : String,
  start : MusicalTime,
  end : MusicalTime,
  quantization : TransitionQuantization,
  max_repeats : Int,
) -> Result[LoopRegion, GameMusicError] {
  if end.bar < start.bar || (end.bar == start.bar && end.beat <= start.beat) {
    return Err(InvalidLoopRegion("循环结束必须大于循环开始"))
  }
  if max_repeats < 1 {
    return Err(InvalidLoopRegion("最大重复次数必须 >= 1"))
  }
  Ok({ id, start, end, quantization, max_repeats: Some(max_repeats) })
}

///|
pub fn stinger_checked(
  id : String,
  trigger : GameTrigger,
  segment : GameSegment,
  quantization : TransitionQuantization,
  priority : Int,
) -> Result[Stinger, GameMusicError] {
  if id == "" {
    return Err(InvalidCue("Stinger ID不能为空"))
  }
  if priority < 0 {
    return Err(InvalidParameter("stinger 优先级不能为负"))
  }
  Ok({ id, trigger, segment, quantization, priority, policy: InterruptCurrent })
}

///|
pub fn transition_rule_checked(
  id : String,
  from_cue : String,
  to_cue : String,
  trigger : GameTrigger,
  quantization : TransitionQuantization,
  behavior : TransitionBehavior,
) -> Result[TransitionRule, GameMusicError] {
  if id == "" {
    return Err(InvalidTransitionRule("transition rule ID不能为空"))
  }
  if from_cue == "" {
    return Err(InvalidTransitionRule("来源cue不能为空"))
  }
  if to_cue == "" {
    return Err(InvalidTransitionRule("目标cue不能为空"))
  }
  if from_cue == to_cue {
    return Err(InvalidTransitionRule("来源cue 与目标cue 不能相同"))
  }
  Ok({
    id,
    from_cue,
    to_cue,
    trigger,
    quantization,
    behavior,
    condition: Always,
    priority: 0,
  })
}

// ============================================================
// 转换 API
// ============================================================

///|
pub fn score_fragment_to_game_segment_checked(
  fragment : ScoreFragment,
  options : GameSegmentOptions,
) -> Result[GameSegment, GameMusicError] {
  if fragment.tracks.length() == 0 {
    return Err(EmptySegment("ScoreFragment 不包含轨道"))
  }
  let mut total_beats = 0.0
  for t in fragment.tracks {
    let beats = t.duration_beats()
    if beats > total_beats {
      total_beats = beats
    }
  }
  let seg_id = "seg_" + fragment.length_bars.to_string() + "bars"
  Ok({
    id: seg_id,
    label: options.label,
    source: ScoreFragmentSource(fragment),
    start: musical_time_zero(),
    duration_beats: total_beats,
    loop_region: None,
    markers: [],
    layers: [],
    intensity_level: options.intensity,
    tags: options.tags,
  })
}

///|
pub fn game_cue_to_timeline_checked(
  cue : GameCue,
  options : GameTimelineOptions,
) -> Result[GameTimelineSource, GameMusicError] {
  if cue.segments.length() == 0 {
    return Err(TimelineConversionFailed("Cue 没有 segment"))
  }
  let all_entries : Array[GameTimelineEntry] = []
  let mut max_ticks = 0
  for segment in cue.segments {
    match segment.source {
      TimelineSource(tl) => {
        for e in tl.entries {
          all_entries.push(e)
        }
        if tl.total_ticks > max_ticks {
          max_ticks = tl.total_ticks
        }
      }
      _ => continue
    }
  }
  Ok({ entries: all_entries, ppq: options.ppq, total_ticks: max_ticks })
}

///|
pub fn game_project_to_timelines_checked(
  project : GameMusicProject,
  options : GameTimelineOptions,
) -> Result[Array[GameTimelineExport], GameMusicError] {
  let exports : Array[GameTimelineExport] = []
  for cue in project.cues {
    match game_cue_to_timeline_checked(cue, options) {
      Ok(tl) => {
        let mut loop_enabled = false
        let mut loop_start = 0
        let mut loop_end = 0
        let _ = match cue.default_loop {
          Some(lr) => {
            loop_enabled = true
            loop_start = 0
            loop_end = (lr.end.beat *
            options.ppq.to_double() *
            (project.time_signature.measure_beats() / 4.0)).to_int()
          }
          None => ()
        }
        exports.push(GameTimelineExport::{
          cue_id: cue.id,
          timeline: tl,
          loop_enabled,
          loop_start_ticks: loop_start,
          loop_end_ticks: loop_end,
        })
      }
      Err(e) => return Err(e)
    }
  }
  Ok(exports)
}

///|
pub fn game_project_to_browser_events_checked(
  project : GameMusicProject,
  cue_id : String,
  options : GameBrowserExportOptions,
) -> Result[BrowserEventDocument, GameMusicError] {
  let mut target_cue : GameCue? = None
  for cue in project.cues {
    if cue.id == cue_id {
      target_cue = Some(cue)
      break
    }
  }
  match target_cue {
    None => Err(MissingCue("找不到 cue: " + cue_id))
    Some(cue) => {
      let tl_opts = GameTimelineOptions::{
        ppq: options.ppq,
        enable_loop: options.enable_loop,
        include_markers: options.include_markers,
      }
      match game_cue_to_timeline_checked(cue, tl_opts) {
        Ok(tl) => {
          let loop_start = 0
          let loop_end = tl.total_ticks
          Ok(BrowserEventDocument::{
            events: tl.entries,
            ppq: tl.ppq,
            tempo_bpm: project.tempo_bpm,
            loop_enabled: options.enable_loop,
            loop_start_ticks: loop_start,
            loop_end_ticks: loop_end,
          })
        }
        Err(e) => Err(e)
      }
    }
  }
}

// ============================================================
// 校验 API
// ============================================================

///|
pub fn validate_game_project_report(
  project : GameMusicProject,
) -> GameValidationReport {
  let issues : Array[GameValidationIssue] = []
  let cue_ids = _extract_cue_ids(project.cues)

  // 1. 检查重复 cue id
  if _has_duplicate_string(cue_ids) {
    issues.push(GameValidationIssue::{
      severity: DuplicateCue.default_severity(),
      code: DuplicateCue,
      path: "project.cues",
      message: "存在重复的 Cue ID",
      suggestion: "确保每个 Cue 有唯一 ID",
    })
  }

  // 2. 检查每个 cue 是否有 segment
  for cue in project.cues {
    if cue.segments.length() == 0 {
      issues.push(GameValidationIssue::{
        severity: CueHasNoSegments.default_severity(),
        code: CueHasNoSegments,
        path: "project.cues[" + cue.id + "]",
        message: "Cue 没有 segment",
        suggestion: "为每个 Cue 添加至少一个 GameSegment",
      })
    }
  }

  // 3. 检查 loop regions
  for cue in project.cues {
    for segment in cue.segments {
      let _ = match segment.loop_region {
        Some(lr) =>
          if lr.end.bar < lr.start.bar ||
            (lr.end.bar == lr.start.bar && lr.end.beat <= lr.start.beat) {
            issues.push(GameValidationIssue::{
              severity: InvalidLoopRange.default_severity(),
              code: InvalidLoopRange,
              path: "project.cues[" + cue.id + "].segments[" + segment.id + "]",
              message: "无效循环区域",
              suggestion: "确保 loop end > loop start",
            })
          }
        None => ()
      }
    }
  }

  // 4. 检查 transition from/to cue 存在
  for tr in project.transitions {
    if not(_array_contains_string(cue_ids, tr.from_cue)) {
      issues.push(GameValidationIssue::{
        severity: TransitionTargetMissing.default_severity(),
        code: TransitionTargetMissing,
        path: "project.transitions[" + tr.id + "].from_cue",
        message: "transition 来源 cue 不存在: " + tr.from_cue,
        suggestion: "检查 from_cue 是否正确",
      })
    }
    if not(_array_contains_string(cue_ids, tr.to_cue)) {
      issues.push(GameValidationIssue::{
        severity: TransitionTargetMissing.default_severity(),
        code: TransitionTargetMissing,
        path: "project.transitions[" + tr.id + "].to_cue",
        message: "transition 目标 cue 不存在: " + tr.to_cue,
        suggestion: "检查 to_cue 是否正确",
      })
    }
  }

  // 5. 检查 parameter 范围
  for p in project.parameters {
    if p.min_value >= p.max_value {
      issues.push(GameValidationIssue::{
        severity: ParameterOutOfRange.default_severity(),
        code: ParameterOutOfRange,
        path: "project.parameters[" + p.id + "]",
        message: "参数范围无效",
        suggestion: "min_value 应小于 max_value",
      })
    }
    if p.default_value < p.min_value || p.default_value > p.max_value {
      issues.push(GameValidationIssue::{
        severity: ParameterOutOfRange.default_severity(),
        code: ParameterOutOfRange,
        path: "project.parameters[" + p.id + "]",
        message: "参数默认值超出范围",
        suggestion: "default_value 应在 min_value 和 max_value 之间",
      })
    }
  }

  // 6. state default_cue 检查
  for s in project.states {
    if s.default_cue != "" &&
      not(_array_contains_string(cue_ids, s.default_cue)) {
      issues.push(GameValidationIssue::{
        severity: MissingDefaultCue.default_severity(),
        code: MissingDefaultCue,
        path: "project.states[" + s.id + "]",
        message: "state 默认cue不存在: " + s.default_cue,
        suggestion: "确保 default_cue 指向存在的 cue",
      })
    }
  }

  // 汇总
  let mut error_count = 0
  let mut warning_count = 0
  let mut info_count = 0
  for iss in issues {
    match iss.severity {
      GameError => error_count = error_count + 1
      GameWarning => warning_count = warning_count + 1
      GameInfo => info_count = info_count + 1
    }
  }
  {
    issues,
    summary: {
      total_issues: issues.length(),
      error_count,
      warning_count,
      info_count,
    },
  }
}

// ============================================================
// 导出 API
// ============================================================

///|
pub fn game_project_to_json_checked(
  project : GameMusicProject,
  options : GameExportOptions,
) -> Result[String, GameMusicError] {
  if options.strict {
    let report = validate_game_project_report(project)
    if game_validation_report_is_export_blocking(report) {
      return Err(ValidationFailed("strict 模式下有阻塞性校验错误"))
    }
  }
  Ok(_game_project_to_json_string(project, options))
}

///|
fn _game_project_to_json_string(
  project : GameMusicProject,
  options : GameExportOptions,
) -> String {
  let mut result = "{"
  result = result + "\"schema_version\":\"" + options.schema_version + "\","
  result = result + "\"project\":{"
  result = result + "\"id\":\"" + project.id + "\","
  result = result + "\"name\":\"" + project.name + "\","
  result = result + "\"tempo_bpm\":" + project.tempo_bpm.to_string() + ","
  result = result + "\"cue_count\":" + project.cues.length().to_string() + ","
  result = result +
    "\"state_count\":" +
    project.states.length().to_string() +
    ","
  result = result +
    "\"parameter_count\":" +
    project.parameters.length().to_string() +
    ","
  result = result +
    "\"transition_count\":" +
    project.transitions.length().to_string()
  result = result + "}"
  if options.include_validation_report {
    let report = validate_game_project_report(project)
    let rpt_json = game_validation_report_to_json(report)
    result = result + ",\"validation\":" + rpt_json
  }
  result = result + "}"
  result
}

///|
pub fn game_cue_to_json_checked(
  cue : GameCue,
  options : GameExportOptions,
) -> Result[String, GameMusicError] {
  let dummy_project = GameMusicProject::{
    id: "temp",
    name: "temp",
    tempo_bpm: 120,
    time_signature: four_four(),
    cues: [cue],
    states: [],
    parameters: [],
    transitions: [],
    metadata: empty_game_metadata(),
  }
  game_project_to_json_checked(dummy_project, options)
}

///|
pub fn game_project_to_export_document_checked(
  project : GameMusicProject,
  options : GameExportOptions,
) -> Result[GameMusicExportDocument, GameMusicError] {
  let report = validate_game_project_report(project)
  if options.strict && game_validation_report_is_export_blocking(report) {
    return Err(ValidationFailed("strict 模式下有阻塞性校验错误"))
  }
  let timelines : Array[GameTimelineExport] = if options.include_timelines {
    match
      game_project_to_timelines_checked(
        project,
        default_game_timeline_options(),
      ) {
      Ok(tls) => tls
      Err(e) => return Err(e)
    }
  } else {
    []
  }
  let assets : Array[GameAssetExport] = []
  Ok({
    schema_version: options.schema_version,
    project_id: project.id,
    project_name: project.name,
    timelines,
    assets,
    validation: report,
  })
}

// ============================================================
// 便捷 API
// ============================================================

///|
pub fn make_loop_cue_checked(
  id : String,
  name : String,
  fragment : ScoreFragment,
  bars : Int,
) -> Result[GameCue, GameMusicError] {
  if id == "" {
    return Err(InvalidCue("Cue ID不能为空"))
  }
  if bars <= 0 {
    return Err(InvalidCue("bars 必须 > 0"))
  }
  let segment_opts = default_game_segment_options()
  let segment = match
    score_fragment_to_game_segment_checked(fragment, segment_opts) {
    Ok(seg) => seg
    Err(e) => return Err(e)
  }
  let loop_start = musical_time_zero()
  let loop_end = musical_time(bars, 0.0, 0)
  let loop_r = match
    loop_region_checked("loop_" + id, loop_start, loop_end, Immediate) {
    Ok(lr) => lr
    Err(e) => return Err(e)
  }
  let segment_with_loop = GameSegment::{
    id: segment.id,
    label: segment.label,
    source: segment.source,
    start: segment.start,
    duration_beats: segment.duration_beats,
    loop_region: Some(loop_r),
    markers: segment.markers,
    layers: segment.layers,
    intensity_level: segment.intensity_level,
    tags: segment.tags,
  }
  game_cue_checked(id, name, LoopCue, [segment_with_loop])
}

///|
pub fn make_stinger_cue_checked(
  id : String,
  name : String,
  fragment : ScoreFragment,
) -> Result[GameCue, GameMusicError] {
  if id == "" {
    return Err(InvalidCue("Cue ID不能为空"))
  }
  let segment_opts = default_game_segment_options()
  let segment = match
    score_fragment_to_game_segment_checked(fragment, segment_opts) {
    Ok(seg) => seg
    Err(e) => return Err(e)
  }
  game_cue_checked(id, name, StingerCue, [segment])
}

///|
pub fn make_transition_cue_checked(
  id : String,
  name : String,
  from_fragment : ScoreFragment,
  to_fragment : ScoreFragment,
) -> Result[GameCue, GameMusicError] {
  if id == "" {
    return Err(InvalidCue("Cue ID不能为空"))
  }
  let opts = default_game_segment_options()
  let from_seg = match
    score_fragment_to_game_segment_checked(from_fragment, opts) {
    Ok(seg) => seg
    Err(e) => return Err(e)
  }
  let to_opts = default_game_segment_options()
  let to_seg = match
    score_fragment_to_game_segment_checked(to_fragment, to_opts) {
    Ok(seg) => seg
    Err(e) => return Err(e)
  }
  game_cue_checked(id, name, TransitionCue, [from_seg, to_seg])
}
