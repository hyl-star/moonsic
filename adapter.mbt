//
// AI/外部生成器接入预留模块 -- 协议定义、校验、JSON 编解码、确定性 mock
//

// ============================================================
// ExternalGenerationError
// ============================================================

///|
/// 外部生成器协议的统一错误类型
pub(all) enum ExternalGenerationError {
  InvalidGenerationRequest(String)
  InvalidGenerationConstraint(String)
  ProviderCapabilityMismatch(String)
  InvalidGenerationPatch(String)
  PatchTargetNotFound(String)
  PatchConflict(String)
  ExternalGenerationParseError(String)
  ExternalGenerationUnsupported(String)
}

///|
/// 转为可读的错误消息
pub fn ExternalGenerationError::to_string(
  self : ExternalGenerationError,
) -> String {
  match self {
    InvalidGenerationRequest(msg) => "无效生成请求：\{msg}"
    InvalidGenerationConstraint(msg) => "无效约束：\{msg}"
    ProviderCapabilityMismatch(msg) => "生成器能力不匹配：\{msg}"
    InvalidGenerationPatch(msg) => "无效补丁：\{msg}"
    PatchTargetNotFound(msg) => "补丁目标不存在：\{msg}"
    PatchConflict(msg) => "补丁冲突：\{msg}"
    ExternalGenerationParseError(msg) => "外部生成器解析错误：\{msg}"
    ExternalGenerationUnsupported(msg) => "不支持的操作：\{msg}"
  }
}

// ============================================================
// 枚举类型定义
// ============================================================

///|
/// 外部生成器种类
pub(all) enum ExternalGeneratorKind {
  LocalRuleProvider
  LocalModelProvider
  RemoteModelProvider
  HumanPluginProvider
  MockProvider
}

///|
/// 生成任务种类
pub(all) enum GenerationTaskKind {
  MelodyContinuation
  ChordProgression
  BassLine
  AccompanimentTask
  RhythmPatternGen
  GameLoopTask
  Variation
  Orchestration
}

///|
/// 风格标签
pub(all) enum GenerationStyleTag {
  Pop
  Jazz
  Lofi
  Cinematic
  Ambient
  Chiptune
  GameCombat
  GameExploration
}

///|
/// 生成约束（带参数）
pub(all) enum GenerationConstraint {
  MinBars(Int)
  MaxBars(Int)
  AllowedScaleDegrees(Array[Int])
  AllowedPitchRange(Int, Int)
  RequiredStyle(GenerationStyleTag)
  MaxLeap(Int)
  TargetDensity(Double)
  MustFitTimeSignature
  MustLoop
}

///|
/// 补丁操作种类
pub(all) enum PatchOperationKind {
  AppendTrack
  InsertTrack
  ReplaceTrack
  RemoveTrack
  AppendMeasure
  ReplaceMeasure
  InsertSection
  AddNotation
  SetTempo
}

///|
/// 补丁目标种类
pub(all) enum PatchTargetKind {
  ScoreTarget
  TrackTarget
  PartTarget
  StaffTarget
  VoiceTarget
  MeasureTarget
  EventTarget
  SectionTarget
}

///|
/// 生成器能力
pub(all) enum GenerationCapability {
  CanGenerateMelody
  CanGenerateHarmony
  CanGenerateBass
  CanGenerateAccompaniment
  CanGenerateRhythm
  CanGenerateGameLoop
  CanGenerateVariation
  CanGenerateArrangement
}

///|
/// 确定性等级
pub(all) enum GenerationDeterminism {
  Deterministic
  Seeded
  NonDeterministic
}

// ============================================================
// 结构体类型定义
// ============================================================

///|
/// 当前曲谱上下文摘要
pub(all) struct ScoreContext {
  score_summary : String
  key_hint : Key?
  time_signature : TimeSignature
  tempo : Tempo
  bars : Int
  track_count : Int
  ppq : Int
}

///|
/// 生成请求
pub(all) struct GenerationRequest {
  id : String
  task : GenerationTaskKind
  context : ScoreContext
  style_tags : Array[GenerationStyleTag]
  constraints : Array[GenerationConstraint]
  deterministic : GenerationDeterminism
  seed : Int?
}

///|
/// 生成器信息
pub(all) struct GenerationProviderInfo {
  name : String
  kind : ExternalGeneratorKind
  capabilities : Array[GenerationCapability]
  determinism : GenerationDeterminism
}

///|
/// 补丁操作
pub(all) struct GenerationPatchOperation {
  kind : PatchOperationKind
  target : PatchTargetKind
  path : String
  payload_json : String
}

///|
/// 生成补丁
pub(all) struct GenerationPatch {
  operations : Array[GenerationPatchOperation]
  source : String
}

///|
/// 乐谱片段
pub(all) struct ScoreFragment {
  tracks : Array[Track]
  start_bar : Int
  length_bars : Int
}

///|
/// 生成候选
pub(all) struct GenerationCandidate {
  fragment : ScoreFragment
  confidence : Double
  description : String
}

///|
/// 生成响应
pub(all) struct GenerationResponse {
  request_id : String
  candidates : Array[GenerationCandidate]
  patch : GenerationPatch?
  message : String
}

// ============================================================
// 规则表：Task -> Required Capability
// ============================================================

///|
/// 获取 task 所需的 capability
fn task_to_required_capability(
  task : GenerationTaskKind,
) -> GenerationCapability {
  match task {
    MelodyContinuation => CanGenerateMelody
    ChordProgression => CanGenerateHarmony
    BassLine => CanGenerateBass
    AccompanimentTask => CanGenerateAccompaniment
    RhythmPatternGen => CanGenerateRhythm
    GameLoopTask => CanGenerateGameLoop
    Variation => CanGenerateVariation
    Orchestration => CanGenerateArrangement
  }
}

///|
/// 根据 ExternalGeneratorKind 推导默认 determinism
fn kind_default_determinism(
  kind : ExternalGeneratorKind,
) -> GenerationDeterminism {
  match kind {
    LocalRuleProvider => Deterministic
    LocalModelProvider => Seeded
    RemoteModelProvider => NonDeterministic
    HumanPluginProvider => NonDeterministic
    MockProvider => Deterministic
  }
}

///|
/// 枚举值 -> 标签字符串
fn task_kind_to_tag(task : GenerationTaskKind) -> String {
  match task {
    MelodyContinuation => "MelodyContinuation"
    ChordProgression => "ChordProgression"
    BassLine => "BassLine"
    AccompanimentTask => "Accompaniment"
    RhythmPatternGen => "RhythmPattern"
    GameLoopTask => "GameLoop"
    Variation => "Variation"
    Orchestration => "Orchestration"
  }
}

///|
fn style_tag_to_str(tag : GenerationStyleTag) -> String {
  match tag {
    Pop => "Pop"
    Jazz => "Jazz"
    Lofi => "Lofi"
    Cinematic => "Cinematic"
    Ambient => "Ambient"
    Chiptune => "Chiptune"
    GameCombat => "GameCombat"
    GameExploration => "GameExploration"
  }
}

///|
fn determinism_to_tag(d : GenerationDeterminism) -> String {
  match d {
    Deterministic => "Deterministic"
    Seeded => "Seeded"
    NonDeterministic => "NonDeterministic"
  }
}

///|
fn capability_to_tag(c : GenerationCapability) -> String {
  match c {
    CanGenerateMelody => "CanGenerateMelody"
    CanGenerateHarmony => "CanGenerateHarmony"
    CanGenerateBass => "CanGenerateBass"
    CanGenerateAccompaniment => "CanGenerateAccompaniment"
    CanGenerateRhythm => "CanGenerateRhythm"
    CanGenerateGameLoop => "CanGenerateGameLoop"
    CanGenerateVariation => "CanGenerateVariation"
    CanGenerateArrangement => "CanGenerateArrangement"
  }
}

///|
fn capability_eq(a : GenerationCapability, b : GenerationCapability) -> Bool {
  match a {
    CanGenerateMelody => b is CanGenerateMelody
    CanGenerateHarmony => b is CanGenerateHarmony
    CanGenerateBass => b is CanGenerateBass
    CanGenerateAccompaniment => b is CanGenerateAccompaniment
    CanGenerateRhythm => b is CanGenerateRhythm
    CanGenerateGameLoop => b is CanGenerateGameLoop
    CanGenerateVariation => b is CanGenerateVariation
    CanGenerateArrangement => b is CanGenerateArrangement
  }
}

///|
fn patch_kind_to_tag(k : PatchOperationKind) -> String {
  match k {
    AppendTrack => "AppendTrack"
    InsertTrack => "InsertTrack"
    ReplaceTrack => "ReplaceTrack"
    RemoveTrack => "RemoveTrack"
    AppendMeasure => "AppendMeasure"
    ReplaceMeasure => "ReplaceMeasure"
    InsertSection => "InsertSection"
    AddNotation => "AddNotation"
    SetTempo => "SetTempo"
  }
}

///|
fn patch_target_to_tag(t : PatchTargetKind) -> String {
  match t {
    ScoreTarget => "ScoreTarget"
    TrackTarget => "TrackTarget"
    PartTarget => "PartTarget"
    StaffTarget => "StaffTarget"
    VoiceTarget => "VoiceTarget"
    MeasureTarget => "MeasureTarget"
    EventTarget => "EventTarget"
    SectionTarget => "SectionTarget"
  }
}

///|
fn constraint_kind_name(c : GenerationConstraint) -> String {
  match c {
    MinBars(_) => "MinBars"
    MaxBars(_) => "MaxBars"
    AllowedScaleDegrees(_) => "AllowedScaleDegrees"
    AllowedPitchRange(_, _) => "AllowedPitchRange"
    RequiredStyle(_) => "RequiredStyle"
    MaxLeap(_) => "MaxLeap"
    TargetDensity(_) => "TargetDensity"
    MustFitTimeSignature => "MustFitTimeSignature"
    MustLoop => "MustLoop"
  }
}

///|
fn generator_kind_to_tag(k : ExternalGeneratorKind) -> String {
  match k {
    LocalRuleProvider => "LocalRuleProvider"
    LocalModelProvider => "LocalModelProvider"
    RemoteModelProvider => "RemoteModelProvider"
    HumanPluginProvider => "HumanPluginProvider"
    MockProvider => "MockProvider"
  }
}

///|
fn parse_task_kind_from_tag(
  s : String,
) -> Result[GenerationTaskKind, ExternalGenerationError] {
  match s {
    "MelodyContinuation" => Ok(MelodyContinuation)
    "ChordProgression" => Ok(ChordProgression)
    "BassLine" => Ok(BassLine)
    "Accompaniment" => Ok(AccompanimentTask)
    "RhythmPattern" => Ok(RhythmPatternGen)
    "GameLoop" => Ok(GameLoopTask)
    "Variation" => Ok(Variation)
    "Orchestration" => Ok(Orchestration)
    _ => Err(ExternalGenerationParseError("未知任务种类：\{s}"))
  }
}

///|
fn parse_style_tag_from_str(
  s : String,
) -> Result[GenerationStyleTag, ExternalGenerationError] {
  match s {
    "Pop" => Ok(Pop)
    "Jazz" => Ok(Jazz)
    "Lofi" => Ok(Lofi)
    "Cinematic" => Ok(Cinematic)
    "Ambient" => Ok(Ambient)
    "Chiptune" => Ok(Chiptune)
    "GameCombat" => Ok(GameCombat)
    "GameExploration" => Ok(GameExploration)
    _ => Err(ExternalGenerationParseError("未知风格标签：\{s}"))
  }
}

///|
fn parse_determinism_from_tag(
  s : String,
) -> Result[GenerationDeterminism, ExternalGenerationError] {
  match s {
    "Deterministic" => Ok(Deterministic)
    "Seeded" => Ok(Seeded)
    "NonDeterministic" => Ok(NonDeterministic)
    _ => Err(ExternalGenerationParseError("未知确定性等级：\{s}"))
  }
}

///|
fn parse_capability_from_tag(
  s : String,
) -> Result[GenerationCapability, ExternalGenerationError] {
  match s {
    "CanGenerateMelody" => Ok(CanGenerateMelody)
    "CanGenerateHarmony" => Ok(CanGenerateHarmony)
    "CanGenerateBass" => Ok(CanGenerateBass)
    "CanGenerateAccompaniment" => Ok(CanGenerateAccompaniment)
    "CanGenerateRhythm" => Ok(CanGenerateRhythm)
    "CanGenerateGameLoop" => Ok(CanGenerateGameLoop)
    "CanGenerateVariation" => Ok(CanGenerateVariation)
    "CanGenerateArrangement" => Ok(CanGenerateArrangement)
    _ => Err(ExternalGenerationParseError("未知能力：\{s}"))
  }
}

///|
fn parse_patch_kind_from_tag(
  s : String,
) -> Result[PatchOperationKind, ExternalGenerationError] {
  match s {
    "AppendTrack" => Ok(AppendTrack)
    "InsertTrack" => Ok(InsertTrack)
    "ReplaceTrack" => Ok(ReplaceTrack)
    "RemoveTrack" => Ok(RemoveTrack)
    "AppendMeasure" => Ok(AppendMeasure)
    "ReplaceMeasure" => Ok(ReplaceMeasure)
    "InsertSection" => Ok(InsertSection)
    "AddNotation" => Ok(AddNotation)
    "SetTempo" => Ok(SetTempo)
    _ => Err(ExternalGenerationParseError("未知补丁操作：\{s}"))
  }
}

///|
fn parse_patch_target_from_tag(
  s : String,
) -> Result[PatchTargetKind, ExternalGenerationError] {
  match s {
    "ScoreTarget" => Ok(ScoreTarget)
    "TrackTarget" => Ok(TrackTarget)
    "PartTarget" => Ok(PartTarget)
    "StaffTarget" => Ok(StaffTarget)
    "VoiceTarget" => Ok(VoiceTarget)
    "MeasureTarget" => Ok(MeasureTarget)
    "EventTarget" => Ok(EventTarget)
    "SectionTarget" => Ok(SectionTarget)
    _ => Err(ExternalGenerationParseError("未知补丁目标：\{s}"))
  }
}

// ============================================================
// 约束校验
// ============================================================

///|
/// 校验约束数组是否合法（无冲突）
fn validate_constraints(
  constraints : Array[GenerationConstraint],
) -> Result[Unit, ExternalGenerationError] {
  let mut min_bars : Int? = None
  let mut max_bars : Int? = None
  for c in constraints {
    match c {
      MinBars(n) => {
        if n <= 0 {
          return Err(
            InvalidGenerationConstraint("MinBars 必须 > 0，当前：\{n}"),
          )
        }
        min_bars = Some(n)
      }
      MaxBars(n) => {
        if n <= 0 {
          return Err(
            InvalidGenerationConstraint("MaxBars 必须 > 0，当前：\{n}"),
          )
        }
        max_bars = Some(n)
      }
      AllowedScaleDegrees(degrees) => {
        if degrees.length() == 0 {
          return Err(
            InvalidGenerationConstraint("AllowedScaleDegrees 不能为空"),
          )
        }
        for d in degrees {
          if d <= 0 {
            return Err(
              InvalidGenerationConstraint(
                "音级度数必须 > 0，当前：\{d}",
              ),
            )
          }
        }
      }
      AllowedPitchRange(low, high) =>
        if low > high {
          return Err(
            InvalidGenerationConstraint(
              "音高范围 low=\{low} > high=\{high}",
            ),
          )
        }
      MaxLeap(n) =>
        if n < 0 {
          return Err(
            InvalidGenerationConstraint("MaxLeap 不能为负数：\{n}"),
          )
        }
      TargetDensity(x) =>
        if x < 0.0 || x > 1.0 {
          return Err(
            InvalidGenerationConstraint(
              "TargetDensity 必须在 [0.0, 1.0]，当前：\{x}",
            ),
          )
        }
      MustFitTimeSignature | MustLoop | RequiredStyle(_) => ()
    }
  }
  // 检查 MinBars 和 MaxBars 冲突
  match (min_bars, max_bars) {
    (Some(mn), Some(mx)) =>
      if mn > mx {
        return Err(
          InvalidGenerationConstraint("MinBars(\{mn}) > MaxBars(\{mx})"),
        )
      }
    _ => ()
  }
  Ok(())
}

// ============================================================
// Checked API
// ============================================================

///|
/// 构建 GenerationRequest 并校验上下文和约束。
pub fn generation_request_checked(
  task : GenerationTaskKind,
  context : ScoreContext,
  constraints : Array[GenerationConstraint],
) -> Result[GenerationRequest, ExternalGenerationError] {
  match validate_constraints(constraints) {
    Ok(_) => ()
    Err(e) => return Err(e)
  }
  let seed : Int? = None
  Ok({
    id: "req_" + random_id_suffix(),
    task,
    context,
    style_tags: [],
    constraints,
    deterministic: Deterministic,
    seed,
  })
}

///|
/// 生成简单的请求 ID 后缀（基于时间戳的确定性字符串）
fn random_id_suffix() -> String {
  // v1.x 不引入随机：使用固定后缀，让调用者可覆盖
  "0000"
}

///|
/// 声明外部生成器能力。
pub fn generation_provider_info(
  name : String,
  kind : ExternalGeneratorKind,
  capabilities : Array[GenerationCapability],
) -> GenerationProviderInfo {
  let determinism = kind_default_determinism(kind)
  { name, kind, capabilities, determinism }
}

///|
/// 检查 provider 是否能处理该请求。
pub fn validate_generation_request(
  request : GenerationRequest,
  provider : GenerationProviderInfo,
) -> Result[Unit, ExternalGenerationError] {
  let required = task_to_required_capability(request.task)
  let mut has_cap = false
  for c in provider.capabilities {
    if capability_eq(c, required) {
      has_cap = true
      break
    }
  }
  if !has_cap {
    let msg = "provider " +
      provider.name +
      " 缺少能力 " +
      capability_to_tag(required) +
      "，无法处理 " +
      task_kind_to_tag(request.task)
    return Err(ProviderCapabilityMismatch(msg))
  }
  // 检查 determinism 兼容性
  match provider.determinism {
    Deterministic => ()
    // Deterministic provider 可以处理任何请求
    Seeded =>
      match request.deterministic {
        Deterministic => ()
        // Seeded 可满足 Deterministic（固定种子即可）
        Seeded => ()
        NonDeterministic => ()
      }
    NonDeterministic => ()
  }
  Ok(())
}

///|
/// 构造生成补丁。
pub fn generation_patch_checked(
  operations : Array[GenerationPatchOperation],
) -> Result[GenerationPatch, ExternalGenerationError] {
  if operations.length() == 0 {
    return Err(InvalidGenerationPatch("operations 不能为空"))
  }
  for op in operations {
    // 校验每个 operation 的非空字段
    if op.path.length() == 0 {
      return Err(InvalidGenerationPatch("operation path 不能为空"))
    }
    // ReplaceTrack / RemoveTrack 需要有效的 track 索引路径
    match op.kind {
      ReplaceTrack | RemoveTrack =>
        match op.target {
          TrackTarget => ()
          _ =>
            return Err(
              InvalidGenerationPatch(
                patch_kind_to_tag(op.kind) +
                " 操作要求 target=" +
                patch_target_to_tag(TrackTarget),
              ),
            )
        }
      InsertTrack | AppendTrack =>
        // 允许 ScoreTarget 或 TrackTarget
        match op.target {
          ScoreTarget | TrackTarget => ()
          _ =>
            return Err(
              InvalidGenerationPatch(
                patch_kind_to_tag(op.kind) +
                " 操作要求 target 为 ScoreTarget 或 TrackTarget",
              ),
            )
        }
      _ => ()
    }
  }
  Ok({ operations, source: "moonsic" })
}

///|
/// 校验 patch 是否能应用到当前上下文。
pub fn validate_generation_patch(
  patch : GenerationPatch,
  context : ScoreContext,
) -> Result[Unit, ExternalGenerationError] {
  if patch.operations.length() == 0 {
    return Err(InvalidGenerationPatch("operations 不能为空"))
  }
  for op in patch.operations {
    match op.kind {
      ReplaceTrack | RemoveTrack => {
        let idx = parse_track_index(op.path)
        match idx {
          Ok(i) =>
            if i < 0 || i >= context.track_count {
              return Err(
                PatchTargetNotFound(
                  "track 索引 \{i} 超出范围 [0, \{context.track_count - 1}]",
                ),
              )
            }
          Err(e) => return Err(e)
        }
      }
      InsertTrack => {
        let idx = parse_track_index(op.path)
        match idx {
          Ok(i) =>
            if i < 0 || i > context.track_count {
              return Err(
                PatchTargetNotFound(
                  "insert track 索引 \{i} 超出范围 [0, \{context.track_count}]",
                ),
              )
            }
          Err(e) => return Err(e)
        }
      }
      AppendTrack => ()
      AppendMeasure | ReplaceMeasure | InsertSection | AddNotation | SetTempo =>
        return Err(
          ExternalGenerationUnsupported(
            "\{patch_kind_to_tag(op.kind)} 操作暂不支持",
          ),
        )
    }
  }
  Ok(())
}

///|
/// 将 patch 应用到 Score（仅支持 track 级操作）。
pub fn apply_generation_patch_checked(
  score : Score,
  patch : GenerationPatch,
) -> Result[Score, ExternalGenerationError] {
  let mut new_tracks = []
  for t in score.tracks {
    new_tracks.push(t)
  }
  for op in patch.operations {
    match op.kind {
      AppendTrack =>
        match json_parse(op.payload_json) {
          Ok(jv) =>
            match track_from_jv(jv) {
              Ok(t) => new_tracks.push(t)
              Err(e) =>
                return Err(
                  InvalidGenerationPatch(
                    "payload JSON 解析为 Track 失败：\{e}",
                  ),
                )
            }
          Err(e) =>
            return Err(
              InvalidGenerationPatch("payload JSON 解析失败：\{e}"),
            )
        }
      InsertTrack => {
        let idx = match parse_track_index(op.path) {
          Ok(i) => i
          Err(e) => return Err(e)
        }
        match json_parse(op.payload_json) {
          Ok(jv) =>
            match track_from_jv(jv) {
              Ok(t) => {
                let rebuilt = []
                for i = 0; i < new_tracks.length(); i = i + 1 {
                  if i == idx {
                    rebuilt.push(t)
                  }
                  rebuilt.push(new_tracks[i])
                }
                if idx >= new_tracks.length() {
                  rebuilt.push(t)
                }
                new_tracks = rebuilt
              }
              Err(e) =>
                return Err(
                  InvalidGenerationPatch(
                    "payload JSON 解析为 Track 失败：\{e}",
                  ),
                )
            }
          Err(e) =>
            return Err(
              InvalidGenerationPatch("payload JSON 解析失败：\{e}"),
            )
        }
      }
      ReplaceTrack => {
        let idx = match parse_track_index(op.path) {
          Ok(i) => i
          Err(e) => return Err(e)
        }
        if idx < 0 || idx >= new_tracks.length() {
          return Err(PatchTargetNotFound("track 索引 \{idx} 超出范围"))
        }
        match json_parse(op.payload_json) {
          Ok(jv) =>
            match track_from_jv(jv) {
              Ok(t) => new_tracks[idx] = t
              Err(e) =>
                return Err(
                  InvalidGenerationPatch(
                    "payload JSON 解析为 Track 失败：\{e}",
                  ),
                )
            }
          Err(e) =>
            return Err(
              InvalidGenerationPatch("payload JSON 解析失败：\{e}"),
            )
        }
      }
      RemoveTrack => {
        let idx = match parse_track_index(op.path) {
          Ok(i) => i
          Err(e) => return Err(e)
        }
        if idx < 0 || idx >= new_tracks.length() {
          return Err(PatchTargetNotFound("track 索引 \{idx} 超出范围"))
        }
        let rebuilt = []
        for i = 0; i < new_tracks.length(); i = i + 1 {
          if i != idx {
            rebuilt.push(new_tracks[i])
          }
        }
        new_tracks = rebuilt
      }
      _ =>
        return Err(
          ExternalGenerationUnsupported(
            "\{patch_kind_to_tag(op.kind)} 操作暂不支持",
          ),
        )
    }
  }
  Ok({
    tempo: score.tempo,
    time_signature: score.time_signature,
    tracks: new_tracks,
    master_gain: score.master_gain,
  })
}

///|
/// 从路径 "/score/tracks/N" 中提取索引 N
fn parse_track_index(path : String) -> Result[Int, ExternalGenerationError] {
  if path == "/score" {
    return Ok(0)
  }
  // 查找最后一个 "/" 之后的数字
  let len = path.length()
  let mut idx = len - 1
  // 跳过末尾非数字字符
  while idx >= 0 && !(path[idx] >= '0' && path[idx] <= '9') {
    idx = idx - 1
  }
  if idx < 0 {
    return Err(PatchTargetNotFound("路径中找不到索引数字：\{path}"))
  }
  let mut start = idx
  while start > 0 && path[start - 1] >= '0' && path[start - 1] <= '9' {
    start = start - 1
  }
  let num_str = path[start:idx + 1].to_owned()
  let mut val = 0
  for i = 0; i < num_str.length(); i = i + 1 {
    let c = num_str[i]
    if c >= '0' && c <= '9' {
      val = val * 10 + (c.to_int() - '0'.to_int())
    }
  }
  Ok(val)
}

///|
/// 从现有 Score 提取上下文摘要。
pub fn score_context_from_score(score : Score, ppq : Int) -> ScoreContext {
  let mb = score.time_signature.measure_beats()
  let tb = score.duration_beats()
  let bars_f = tb / mb
  let mut bars = bars_f.to_int()
  if bars_f > bars.to_double() {
    bars = bars + 1
  }
  let tc = score.track_count()
  let summary = "Score with \{tc} tracks, \{bars} bars"
  {
    score_summary: summary,
    key_hint: None,
    time_signature: score.time_signature,
    tempo: score.tempo,
    bars,
    track_count: tc,
    ppq,
  }
}

///|
/// 本地 deterministic mock provider，用于测试和 demo。
/// 相同 request 始终返回相同 response。
pub fn deterministic_mock_generate(
  request : GenerationRequest,
) -> Result[GenerationResponse, ExternalGenerationError] {
  let (tracks, description, message) = match request.task {
    MelodyContinuation => {
      let melody_events = [
        n(c(4), quarter()),
        n(d(4), quarter()),
        n(e(4), quarter()),
        n(f(4), quarter()),
        n(g(4), quarter()),
        n(a(4), quarter()),
        n(b(4), quarter()),
        n(c(5), quarter()),
      ]
      let tracks = [track(melody_events)]
      (
        tracks, "C major 上行音阶", "mock 生成了 2 小节 C 大调上行旋律",
      )
    }
    ChordProgression => {
      let chords = [
        major(c(4), whole()),
        major(f(4), whole()),
        major(g(4), whole()),
        major(c(4), whole()),
      ]
      let tracks = [track(chords)]
      (
        tracks, "I-IV-V-I 和弦进行", "mock 生成了 C 大调 I-IV-V-I 和弦进行",
      )
    }
    BassLine => {
      let bass = [
        n(c(3), quarter()),
        n(c(3), quarter()),
        n(f(3), quarter()),
        n(f(3), quarter()),
        n(g(3), quarter()),
        n(g(3), quarter()),
        n(c(3), quarter()),
        n(c(3), quarter()),
      ]
      let tracks = [track(bass)]
      (
        tracks, "简单根音贝斯", "mock 生成了基于 I-IV-V-I 的根音贝斯线",
      )
    }
    AccompanimentTask => {
      let acc = [
        major(c(4), half()),
        major(f(4), half()),
        major(g(4), half()),
        major(c(4), half()),
      ]
      let tracks = [track(acc)]
      (tracks, "块状和弦伴奏", "mock 生成了柱式和弦伴奏")
    }
    RhythmPatternGen => {
      let empty = [track([])]
      (empty, "空节奏", "mock 不支持 RhythmPattern，返回空")
    }
    GameLoopTask => {
      let loop_events = [
        n(c(4), eighth()),
        n(e(4), eighth()),
        n(g(4), eighth()),
        n(c(5), eighth()),
        n(g(4), eighth()),
        n(e(4), eighth()),
        n(c(4), eighth()),
        n(g(3), eighth()),
      ]
      let tracks = [track(loop_events)]
      (tracks, "游戏循环片段", "mock 生成了 1 小节循环旋律")
    }
    Variation => {
      let var_events = [
        n(e(4), quarter()),
        n(d(4), quarter()),
        n(c(4), quarter()),
        n(d(4), quarter()),
      ]
      let tracks = [track(var_events)]
      (tracks, "旋律变奏", "mock 生成了下行变奏")
    }
    Orchestration => {
      let empty = [track([])]
      (empty, "空编排", "mock 不支持 Orchestration，返回空")
    }
  }
  let fragment = { tracks, start_bar: 0, length_bars: 4 }
  let candidate = { fragment, confidence: 1.0, description }
  let patch : GenerationPatch? = None
  Ok({ request_id: request.id, candidates: [candidate], patch, message })
}

// ============================================================
// JSON 序列化 -- 领域对象 -> JsonValue
// ============================================================

///|
fn score_context_to_jv(ctx : ScoreContext) -> JsonValue {
  let fields = [
    jv_field("score_summary", jv_str(ctx.score_summary)),
    jv_field(
      "key_hint",
      match ctx.key_hint {
        Some(k) => key_to_jv(k)
        None => JNull
      },
    ),
    jv_field("time_signature", time_sig_to_jv(ctx.time_signature)),
    jv_field("tempo", tempo_to_jv(ctx.tempo)),
    jv_field("bars", jv_int(ctx.bars)),
    jv_field("track_count", jv_int(ctx.track_count)),
    jv_field("ppq", jv_int(ctx.ppq)),
  ]
  jv_obj(fields)
}

///|
fn key_to_jv(k : Key) -> JsonValue {
  jv_obj([
    jv_field("tonic", jv_str(k.tonic.to_string())),
    jv_field("kind", jv_str(scale_kind_tag(k.kind))),
  ])
}

///|
fn scale_kind_tag(k : ScaleKind) -> String {
  match k {
    Major => "Major"
    NaturalMinor => "NaturalMinor"
    MajorPentatonic => "MajorPentatonic"
    MinorPentatonic => "MinorPentatonic"
    HarmonicMinor => "HarmonicMinor"
    MelodicMinor => "MelodicMinor"
    Dorian => "Dorian"
    Phrygian => "Phrygian"
    Lydian => "Lydian"
    Mixolydian => "Mixolydian"
    Locrian => "Locrian"
    Chromatic => "Chromatic"
  }
}

///|
fn constraint_to_jv(c : GenerationConstraint) -> JsonValue {
  match c {
    MinBars(n) =>
      jv_obj([jv_field("kind", jv_str("MinBars")), jv_field("value", jv_int(n))])
    MaxBars(n) =>
      jv_obj([jv_field("kind", jv_str("MaxBars")), jv_field("value", jv_int(n))])
    AllowedScaleDegrees(degrees) => {
      let arr = []
      for d in degrees {
        arr.push(jv_int(d))
      }
      jv_obj([
        jv_field("kind", jv_str("AllowedScaleDegrees")),
        jv_field("degrees", jv_arr(arr)),
      ])
    }
    AllowedPitchRange(low, high) =>
      jv_obj([
        jv_field("kind", jv_str("AllowedPitchRange")),
        jv_field("low", jv_int(low)),
        jv_field("high", jv_int(high)),
      ])
    RequiredStyle(tag) =>
      jv_obj([
        jv_field("kind", jv_str("RequiredStyle")),
        jv_field("style", jv_str(style_tag_to_str(tag))),
      ])
    MaxLeap(n) =>
      jv_obj([jv_field("kind", jv_str("MaxLeap")), jv_field("value", jv_int(n))])
    TargetDensity(x) =>
      jv_obj([
        jv_field("kind", jv_str("TargetDensity")),
        jv_field("value", jv_num(x)),
      ])
    MustFitTimeSignature =>
      jv_obj([jv_field("kind", jv_str("MustFitTimeSignature"))])
    MustLoop => jv_obj([jv_field("kind", jv_str("MustLoop"))])
  }
}

///|
fn request_to_jv(req : GenerationRequest) -> JsonValue {
  let style_arr = []
  for s in req.style_tags {
    style_arr.push(jv_str(style_tag_to_str(s)))
  }
  let constr_arr = []
  for c in req.constraints {
    constr_arr.push(constraint_to_jv(c))
  }
  let fields = [
    jv_field("id", jv_str(req.id)),
    jv_field("task", jv_str(task_kind_to_tag(req.task))),
    jv_field("context", score_context_to_jv(req.context)),
    jv_field("style_tags", jv_arr(style_arr)),
    jv_field("constraints", jv_arr(constr_arr)),
    jv_field("deterministic", jv_str(determinism_to_tag(req.deterministic))),
    jv_field(
      "seed",
      match req.seed {
        Some(s) => jv_int(s)
        None => JNull
      },
    ),
  ]
  jv_obj(fields)
}

///|
fn patch_op_to_jv(op : GenerationPatchOperation) -> JsonValue {
  jv_obj([
    jv_field("kind", jv_str(patch_kind_to_tag(op.kind))),
    jv_field("target", jv_str(patch_target_to_tag(op.target))),
    jv_field("path", jv_str(op.path)),
    jv_field("payload_json", jv_str(op.payload_json)),
  ])
}

///|
fn patch_to_jv(p : GenerationPatch) -> JsonValue {
  let ops = []
  for op in p.operations {
    ops.push(patch_op_to_jv(op))
  }
  jv_obj([
    jv_field("operations", jv_arr(ops)),
    jv_field("source", jv_str(p.source)),
  ])
}

///|
fn fragment_to_jv(sf : ScoreFragment) -> JsonValue {
  let t_arr = []
  for t in sf.tracks {
    t_arr.push(track_to_jv(t))
  }
  jv_obj([
    jv_field("tracks", jv_arr(t_arr)),
    jv_field("start_bar", jv_int(sf.start_bar)),
    jv_field("length_bars", jv_int(sf.length_bars)),
  ])
}

///|
fn candidate_to_jv(cand : GenerationCandidate) -> JsonValue {
  jv_obj([
    jv_field("fragment", fragment_to_jv(cand.fragment)),
    jv_field("confidence", jv_num(cand.confidence)),
    jv_field("description", jv_str(cand.description)),
  ])
}

///|
fn response_to_jv(resp : GenerationResponse) -> JsonValue {
  let cands = []
  for c in resp.candidates {
    cands.push(candidate_to_jv(c))
  }
  let fields = [
    jv_field("request_id", jv_str(resp.request_id)),
    jv_field("candidates", jv_arr(cands)),
    jv_field(
      "patch",
      match resp.patch {
        Some(p) => patch_to_jv(p)
        None => JNull
      },
    ),
    jv_field("message", jv_str(resp.message)),
  ]
  jv_obj(fields)
}

// ============================================================
// 公开 JSON API
// ============================================================

///|
/// 将 GenerationRequest 序列化为 JSON 字符串。
pub fn generation_request_to_json(request : GenerationRequest) -> String {
  json_stringify(request_to_jv(request))
}

///|
/// 将 GenerationResponse 序列化为 JSON 字符串。
pub fn generation_response_to_json(response : GenerationResponse) -> String {
  json_stringify(response_to_jv(response))
}

///|
/// 从 JSON 字符串反序列化为 GenerationRequest。
pub fn generation_request_from_json(
  input : String,
) -> Result[GenerationRequest, ExternalGenerationError] {
  match json_parse(input) {
    Ok(jv) => request_from_jv(jv)
    Err(e) => Err(ExternalGenerationParseError(e))
  }
}

///|
/// 从 JSON 字符串反序列化为 GenerationResponse。
pub fn generation_response_from_json(
  input : String,
) -> Result[GenerationResponse, ExternalGenerationError] {
  match json_parse(input) {
    Ok(jv) => response_from_jv(jv)
    Err(e) => Err(ExternalGenerationParseError(e))
  }
}

///|
fn request_from_jv(
  v : JsonValue,
) -> Result[GenerationRequest, ExternalGenerationError] {
  let fields = match jv_get_fields(v) {
    Ok(f) => f
    Err(e) => return Err(ExternalGenerationParseError(e))
  }
  let id = match jv_lookup(fields, "id") {
    Ok(jv) =>
      match jv_as_string(jv) {
        Ok(s) => s
        Err(e) => return Err(ExternalGenerationParseError(e))
      }
    Err(e) => return Err(ExternalGenerationParseError(e))
  }
  let task_str = match jv_lookup(fields, "task") {
    Ok(jv) =>
      match jv_as_string(jv) {
        Ok(s) => s
        Err(e) => return Err(ExternalGenerationParseError(e))
      }
    Err(e) => return Err(ExternalGenerationParseError(e))
  }
  let task = match parse_task_kind_from_tag(task_str) {
    Ok(t) => t
    Err(e) => return Err(e)
  }
  let ctx_jv = match jv_lookup(fields, "context") {
    Ok(jv) => jv
    Err(e) => return Err(ExternalGenerationParseError(e))
  }
  let context = match score_context_from_jv(ctx_jv) {
    Ok(c) => c
    Err(e) => return Err(e)
  }
  let style_tags = match jv_lookup(fields, "style_tags") {
    Ok(jv) =>
      match jv_as_array(jv) {
        Ok(arr) => {
          let tags = []
          for elem in arr {
            match jv_as_string(elem) {
              Ok(s) =>
                match parse_style_tag_from_str(s) {
                  Ok(tag) => tags.push(tag)
                  Err(e) => return Err(e)
                }
              Err(e) => return Err(ExternalGenerationParseError(e))
            }
          }
          tags
        }
        Err(e) => return Err(ExternalGenerationParseError(e))
      }
    Err(_e) => ([] : Array[GenerationStyleTag])
  }
  let constraints = match jv_lookup(fields, "constraints") {
    Ok(jv) =>
      match jv_as_array(jv) {
        Ok(arr) => {
          let cs = []
          for elem in arr {
            match constraint_from_jv(elem) {
              Ok(c) => cs.push(c)
              Err(e) => return Err(e)
            }
          }
          cs
        }
        Err(e) => return Err(ExternalGenerationParseError(e))
      }
    Err(_e) => ([] : Array[GenerationConstraint])
  }
  let determinism = match jv_lookup(fields, "deterministic") {
    Ok(jv) =>
      match jv_as_string(jv) {
        Ok(s) =>
          match parse_determinism_from_tag(s) {
            Ok(d) => d
            Err(e) => return Err(e)
          }
        Err(e) => return Err(ExternalGenerationParseError(e))
      }
    Err(_e) => Deterministic
  }
  let seed = match jv_lookup(fields, "seed") {
    Ok(JNull) => (None : Int?)
    Ok(jv) =>
      match jv_as_int(jv) {
        Ok(n) => Some(n)
        Err(e) => return Err(ExternalGenerationParseError(e))
      }
    Err(_e) => (None : Int?)
  }
  Ok({
    id,
    task,
    context,
    style_tags,
    constraints,
    deterministic: determinism,
    seed,
  })
}

///|
fn score_context_from_jv(
  v : JsonValue,
) -> Result[ScoreContext, ExternalGenerationError] {
  let fields = match jv_get_fields(v) {
    Ok(f) => f
    Err(e) => return Err(ExternalGenerationParseError(e))
  }
  let score_summary = match jv_lookup(fields, "score_summary") {
    Ok(jv) =>
      match jv_as_string(jv) {
        Ok(s) => s
        Err(e) => return Err(ExternalGenerationParseError(e))
      }
    Err(e) => return Err(ExternalGenerationParseError(e))
  }
  let key_hint = match jv_lookup(fields, "key_hint") {
    Ok(JNull) => (None : Key?)
    Ok(jv) =>
      match key_from_jv(jv) {
        Ok(k) => Some(k)
        Err(e) => return Err(e)
      }
    Err(_e) => (None : Key?)
  }
  let ts_jv = match jv_lookup(fields, "time_signature") {
    Ok(jv) => jv
    Err(e) => return Err(ExternalGenerationParseError(e))
  }
  let time_signature = match time_sig_from_jv(ts_jv) {
    Ok(ts) => ts
    Err(e) => return Err(ExternalGenerationParseError(e))
  }
  let tempo_jv_val = match jv_lookup(fields, "tempo") {
    Ok(jv) => jv
    Err(e) => return Err(ExternalGenerationParseError(e))
  }
  let tempo = match tempo_from_jv(tempo_jv_val) {
    Ok(t) => t
    Err(e) => return Err(ExternalGenerationParseError(e))
  }
  let bars = match jv_lookup(fields, "bars") {
    Ok(jv) =>
      match jv_as_int(jv) {
        Ok(n) => n
        Err(e) => return Err(ExternalGenerationParseError(e))
      }
    Err(e) => return Err(ExternalGenerationParseError(e))
  }
  let track_count = match jv_lookup(fields, "track_count") {
    Ok(jv) =>
      match jv_as_int(jv) {
        Ok(n) => n
        Err(e) => return Err(ExternalGenerationParseError(e))
      }
    Err(e) => return Err(ExternalGenerationParseError(e))
  }
  let ppq = match jv_lookup(fields, "ppq") {
    Ok(jv) =>
      match jv_as_int(jv) {
        Ok(n) => n
        Err(e) => return Err(ExternalGenerationParseError(e))
      }
    Err(e) => return Err(ExternalGenerationParseError(e))
  }
  Ok({ score_summary, key_hint, time_signature, tempo, bars, track_count, ppq })
}

///|
fn key_from_jv(v : JsonValue) -> Result[Key, ExternalGenerationError] {
  let fields = match jv_get_fields(v) {
    Ok(f) => f
    Err(e) => return Err(ExternalGenerationParseError(e))
  }
  let tonic_str = match jv_lookup(fields, "tonic") {
    Ok(jv) =>
      match jv_as_string(jv) {
        Ok(s) => s
        Err(e) => return Err(ExternalGenerationParseError(e))
      }
    Err(e) => return Err(ExternalGenerationParseError(e))
  }
  let tonic = match parse_pitch(tonic_str) {
    Ok(p) => p
    Err(_e) =>
      return Err(
        ExternalGenerationParseError("无法解析 tonic：\{tonic_str}"),
      )
  }
  let kind_str = match jv_lookup(fields, "kind") {
    Ok(jv) =>
      match jv_as_string(jv) {
        Ok(s) => s
        Err(e) => return Err(ExternalGenerationParseError(e))
      }
    Err(e) => return Err(ExternalGenerationParseError(e))
  }
  let kind = match parse_scale_kind_tag(kind_str) {
    Ok(k) => k
    Err(e) => return Err(e)
  }
  Ok(key(tonic, kind))
}

///|
fn parse_scale_kind_tag(
  s : String,
) -> Result[ScaleKind, ExternalGenerationError] {
  match s {
    "Major" => Ok(Major)
    "NaturalMinor" => Ok(NaturalMinor)
    "MajorPentatonic" => Ok(MajorPentatonic)
    "MinorPentatonic" => Ok(MinorPentatonic)
    "HarmonicMinor" => Ok(HarmonicMinor)
    "MelodicMinor" => Ok(MelodicMinor)
    "Dorian" => Ok(Dorian)
    "Phrygian" => Ok(Phrygian)
    "Lydian" => Ok(Lydian)
    "Mixolydian" => Ok(Mixolydian)
    "Locrian" => Ok(Locrian)
    "Chromatic" => Ok(Chromatic)
    _ => Err(ExternalGenerationParseError("未知音阶类型：\{s}"))
  }
}

///|
fn constraint_from_jv(
  v : JsonValue,
) -> Result[GenerationConstraint, ExternalGenerationError] {
  let fields = match jv_get_fields(v) {
    Ok(f) => f
    Err(e) => return Err(ExternalGenerationParseError(e))
  }
  let kind_str = match jv_lookup(fields, "kind") {
    Ok(jv) =>
      match jv_as_string(jv) {
        Ok(s) => s
        Err(e) => return Err(ExternalGenerationParseError(e))
      }
    Err(e) => return Err(ExternalGenerationParseError(e))
  }
  match kind_str {
    "MinBars" => {
      let n = match jv_lookup(fields, "value") {
        Ok(jv) =>
          match jv_as_int(jv) {
            Ok(n) => n
            Err(e) => return Err(ExternalGenerationParseError(e))
          }
        Err(e) => return Err(ExternalGenerationParseError(e))
      }
      Ok(MinBars(n))
    }
    "MaxBars" => {
      let n = match jv_lookup(fields, "value") {
        Ok(jv) =>
          match jv_as_int(jv) {
            Ok(n) => n
            Err(e) => return Err(ExternalGenerationParseError(e))
          }
        Err(e) => return Err(ExternalGenerationParseError(e))
      }
      Ok(MaxBars(n))
    }
    "AllowedScaleDegrees" => {
      let arr_jv = match jv_lookup(fields, "degrees") {
        Ok(jv) => jv
        Err(e) => return Err(ExternalGenerationParseError(e))
      }
      let arr = match jv_as_array(arr_jv) {
        Ok(a) => a
        Err(e) => return Err(ExternalGenerationParseError(e))
      }
      let degrees = []
      for elem in arr {
        match jv_as_int(elem) {
          Ok(d) => degrees.push(d)
          Err(e) => return Err(ExternalGenerationParseError(e))
        }
      }
      Ok(AllowedScaleDegrees(degrees))
    }
    "AllowedPitchRange" => {
      let low = match jv_lookup(fields, "low") {
        Ok(jv) =>
          match jv_as_int(jv) {
            Ok(n) => n
            Err(e) => return Err(ExternalGenerationParseError(e))
          }
        Err(e) => return Err(ExternalGenerationParseError(e))
      }
      let high = match jv_lookup(fields, "high") {
        Ok(jv) =>
          match jv_as_int(jv) {
            Ok(n) => n
            Err(e) => return Err(ExternalGenerationParseError(e))
          }
        Err(e) => return Err(ExternalGenerationParseError(e))
      }
      Ok(AllowedPitchRange(low, high))
    }
    "RequiredStyle" => {
      let s = match jv_lookup(fields, "style") {
        Ok(jv) =>
          match jv_as_string(jv) {
            Ok(s) => s
            Err(e) => return Err(ExternalGenerationParseError(e))
          }
        Err(e) => return Err(ExternalGenerationParseError(e))
      }
      match parse_style_tag_from_str(s) {
        Ok(tag) => Ok(RequiredStyle(tag))
        Err(e) => Err(e)
      }
    }
    "MaxLeap" => {
      let n = match jv_lookup(fields, "value") {
        Ok(jv) =>
          match jv_as_int(jv) {
            Ok(n) => n
            Err(e) => return Err(ExternalGenerationParseError(e))
          }
        Err(e) => return Err(ExternalGenerationParseError(e))
      }
      Ok(MaxLeap(n))
    }
    "TargetDensity" => {
      let x = match jv_lookup(fields, "value") {
        Ok(jv) =>
          match jv_as_double(jv) {
            Ok(x) => x
            Err(e) => return Err(ExternalGenerationParseError(e))
          }
        Err(e) => return Err(ExternalGenerationParseError(e))
      }
      Ok(TargetDensity(x))
    }
    "MustFitTimeSignature" => Ok(MustFitTimeSignature)
    "MustLoop" => Ok(MustLoop)
    _ => Err(ExternalGenerationParseError("未知约束类型：\{kind_str}"))
  }
}

///|
fn response_from_jv(
  v : JsonValue,
) -> Result[GenerationResponse, ExternalGenerationError] {
  let fields = match jv_get_fields(v) {
    Ok(f) => f
    Err(e) => return Err(ExternalGenerationParseError(e))
  }
  let request_id = match jv_lookup(fields, "request_id") {
    Ok(jv) =>
      match jv_as_string(jv) {
        Ok(s) => s
        Err(e) => return Err(ExternalGenerationParseError(e))
      }
    Err(e) => return Err(ExternalGenerationParseError(e))
  }
  let cands_jv = match jv_lookup(fields, "candidates") {
    Ok(jv) => jv
    Err(_e) => JArray([])
  }
  let cand_arr = match jv_as_array(cands_jv) {
    Ok(arr) => arr
    Err(_e) => ([] : Array[JsonValue])
  }
  let candidates = []
  for cjv in cand_arr {
    match candidate_from_jv(cjv) {
      Ok(c) => candidates.push(c)
      Err(e) => return Err(e)
    }
  }
  let patch = match jv_lookup(fields, "patch") {
    Ok(JNull) => (None : GenerationPatch?)
    Ok(jv) =>
      match patch_from_jv(jv) {
        Ok(p) => Some(p)
        Err(e) => return Err(e)
      }
    Err(_e) => (None : GenerationPatch?)
  }
  let message = match jv_lookup(fields, "message") {
    Ok(jv) =>
      match jv_as_string(jv) {
        Ok(s) => s
        Err(e) => return Err(ExternalGenerationParseError(e))
      }
    Err(_e) => ""
  }
  Ok({ request_id, candidates, patch, message })
}

///|
fn candidate_from_jv(
  v : JsonValue,
) -> Result[GenerationCandidate, ExternalGenerationError] {
  let fields = match jv_get_fields(v) {
    Ok(f) => f
    Err(e) => return Err(ExternalGenerationParseError(e))
  }
  let frag_jv = match jv_lookup(fields, "fragment") {
    Ok(jv) => jv
    Err(e) => return Err(ExternalGenerationParseError(e))
  }
  let fragment = match fragment_from_jv(frag_jv) {
    Ok(sf) => sf
    Err(e) => return Err(e)
  }
  let confidence = match jv_lookup(fields, "confidence") {
    Ok(jv) =>
      match jv_as_double(jv) {
        Ok(x) => x
        Err(e) => return Err(ExternalGenerationParseError(e))
      }
    Err(_e) => 1.0
  }
  let description = match jv_lookup(fields, "description") {
    Ok(jv) =>
      match jv_as_string(jv) {
        Ok(s) => s
        Err(e) => return Err(ExternalGenerationParseError(e))
      }
    Err(_e) => ""
  }
  Ok({ fragment, confidence, description })
}

///|
fn fragment_from_jv(
  v : JsonValue,
) -> Result[ScoreFragment, ExternalGenerationError] {
  let fields = match jv_get_fields(v) {
    Ok(f) => f
    Err(e) => return Err(ExternalGenerationParseError(e))
  }
  let tracks_jv = match jv_lookup(fields, "tracks") {
    Ok(jv) => jv
    Err(e) => return Err(ExternalGenerationParseError(e))
  }
  let track_arr = match jv_as_array(tracks_jv) {
    Ok(arr) => arr
    Err(e) => return Err(ExternalGenerationParseError(e))
  }
  let tracks = []
  for tjv in track_arr {
    match track_from_jv(tjv) {
      Ok(t) => tracks.push(t)
      Err(e) => return Err(ExternalGenerationParseError(e))
    }
  }
  let start_bar = match jv_lookup(fields, "start_bar") {
    Ok(jv) =>
      match jv_as_int(jv) {
        Ok(n) => n
        Err(e) => return Err(ExternalGenerationParseError(e))
      }
    Err(_e) => 0
  }
  let length_bars = match jv_lookup(fields, "length_bars") {
    Ok(jv) =>
      match jv_as_int(jv) {
        Ok(n) => n
        Err(e) => return Err(ExternalGenerationParseError(e))
      }
    Err(_e) => 0
  }
  Ok({ tracks, start_bar, length_bars })
}

///|
fn patch_from_jv(
  v : JsonValue,
) -> Result[GenerationPatch, ExternalGenerationError] {
  let fields = match jv_get_fields(v) {
    Ok(f) => f
    Err(e) => return Err(ExternalGenerationParseError(e))
  }
  let ops_jv = match jv_lookup(fields, "operations") {
    Ok(jv) => jv
    Err(e) => return Err(ExternalGenerationParseError(e))
  }
  let ops_arr = match jv_as_array(ops_jv) {
    Ok(arr) => arr
    Err(e) => return Err(ExternalGenerationParseError(e))
  }
  let operations = []
  for ojv in ops_arr {
    match patch_op_from_jv(ojv) {
      Ok(op) => operations.push(op)
      Err(e) => return Err(e)
    }
  }
  let source = match jv_lookup(fields, "source") {
    Ok(jv) =>
      match jv_as_string(jv) {
        Ok(s) => s
        Err(e) => return Err(ExternalGenerationParseError(e))
      }
    Err(_e) => "unknown"
  }
  Ok({ operations, source })
}

///|
fn patch_op_from_jv(
  v : JsonValue,
) -> Result[GenerationPatchOperation, ExternalGenerationError] {
  let fields = match jv_get_fields(v) {
    Ok(f) => f
    Err(e) => return Err(ExternalGenerationParseError(e))
  }
  let kind_str = match jv_lookup(fields, "kind") {
    Ok(jv) =>
      match jv_as_string(jv) {
        Ok(s) => s
        Err(e) => return Err(ExternalGenerationParseError(e))
      }
    Err(e) => return Err(ExternalGenerationParseError(e))
  }
  let kind = match parse_patch_kind_from_tag(kind_str) {
    Ok(k) => k
    Err(e) => return Err(e)
  }
  let target_str = match jv_lookup(fields, "target") {
    Ok(jv) =>
      match jv_as_string(jv) {
        Ok(s) => s
        Err(e) => return Err(ExternalGenerationParseError(e))
      }
    Err(e) => return Err(ExternalGenerationParseError(e))
  }
  let target = match parse_patch_target_from_tag(target_str) {
    Ok(t) => t
    Err(e) => return Err(e)
  }
  let path = match jv_lookup(fields, "path") {
    Ok(jv) =>
      match jv_as_string(jv) {
        Ok(s) => s
        Err(e) => return Err(ExternalGenerationParseError(e))
      }
    Err(e) => return Err(ExternalGenerationParseError(e))
  }
  let payload_json = match jv_lookup(fields, "payload_json") {
    Ok(jv) =>
      match jv_as_string(jv) {
        Ok(s) => s
        Err(e) => return Err(ExternalGenerationParseError(e))
      }
    Err(_e) => ""
  }
  Ok({ kind, target, path, payload_json })
}

// ============================================================
// FFI API — String -> String
// ============================================================

///|
/// FFI 入口：接收 JSON request 字符串，返回 JSON response 字符串。
/// 成功：{"ok":true,"data":...}  失败：{"ok":false,"error":"ExternalGenerationError","message":"..."}
pub fn ffi_external_generate_mock_json(input : String) -> String {
  match generation_request_from_json(input) {
    Ok(request) =>
      match deterministic_mock_generate(request) {
        Ok(response) => ffi_ok_data(generation_response_to_json(response))
        Err(e) => ffi_error("ExternalGenerationError", e.to_string())
      }
    Err(e) => ffi_error("ExternalGenerationError", e.to_string())
  }
}

///|
/// FFI 入口：接收 JSON 含 request 和 patch 的字符串，验证 patch 合法性。
/// 成功：{"ok":true,"data":...}  失败：{"ok":false,"error":"ExternalGenerationError","message":"..."}
pub fn ffi_validate_generation_patch_json(input : String) -> String {
  match json_parse(input) {
    Ok(root) => {
      let fields = match jv_get_fields(root) {
        Ok(f) => f
        Err(e) => return ffi_error("ExternalGenerationError", e)
      }
      let request_jv = match jv_lookup(fields, "request") {
        Ok(jv) => jv
        Err(e) => return ffi_error("ExternalGenerationError", e)
      }
      let request = match request_from_jv(request_jv) {
        Ok(r) => r
        Err(e) => return ffi_error("ExternalGenerationError", e.to_string())
      }
      let patch_jv = match jv_lookup(fields, "patch") {
        Ok(jv) => jv
        Err(e) => return ffi_error("ExternalGenerationError", e)
      }
      let patch = match patch_from_jv(patch_jv) {
        Ok(p) => p
        Err(e) => return ffi_error("ExternalGenerationError", e.to_string())
      }
      match validate_generation_patch(patch, request.context) {
        Ok(_) => ffi_ok_data("{\"valid\":true,\"message\":\"patch valid\"}")
        Err(e) => ffi_error("ExternalGenerationError", e.to_string())
      }
    }
    Err(e) => ffi_error("ExternalGenerationError", e)
  }
}
