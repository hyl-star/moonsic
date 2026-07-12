///|
pub(all) enum ExternalGeneratorKind {
  LocalRuleProvider
  LocalModelProvider
  RemoteModelProvider
  HumanPluginProvider
  MockProvider
}

///|
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
pub(all) enum GenerationDeterminism {
  Deterministic
  Seeded
  NonDeterministic
}

///|
pub(all) struct ScoreContext {
  score_summary : String
  key_hint : @scale.Key?
  time_signature : @time.TimeSignature
  tempo : @score.Tempo
  bars : Int
  track_count : Int
  ppq : Int
}

///|
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
pub(all) struct GenerationProviderInfo {
  name : String
  kind : ExternalGeneratorKind
  capabilities : Array[GenerationCapability]
  determinism : GenerationDeterminism
}

///|
pub(all) struct GenerationPatchOperation {
  kind : PatchOperationKind
  target : PatchTargetKind
  path : String
  payload_json : String
}

///|
pub(all) struct GenerationPatch {
  operations : Array[GenerationPatchOperation]
  source : String
}

///|
pub(all) struct ScoreFragment {
  tracks : Array[@score.SimpleTrack]
  start_bar : Int
  length_bars : Int
}

///|
pub(all) struct GenerationCandidate {
  fragment : ScoreFragment
  confidence : Double
  description : String
}

///|
pub(all) struct GenerationResponse {
  request_id : String
  candidates : Array[GenerationCandidate]
  patch : GenerationPatch?
  message : String
}

///|
pub fn task_to_required_capability(
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
fn style_tag_to_tag(tag : GenerationStyleTag) -> String {
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
fn determinism_to_tag(determinism : GenerationDeterminism) -> String {
  match determinism {
    Deterministic => "Deterministic"
    Seeded => "Seeded"
    NonDeterministic => "NonDeterministic"
  }
}

///|
fn capability_to_tag(capability : GenerationCapability) -> String {
  match capability {
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
fn capability_eq(
  left : GenerationCapability,
  right : GenerationCapability,
) -> Bool {
  match left {
    CanGenerateMelody => right is CanGenerateMelody
    CanGenerateHarmony => right is CanGenerateHarmony
    CanGenerateBass => right is CanGenerateBass
    CanGenerateAccompaniment => right is CanGenerateAccompaniment
    CanGenerateRhythm => right is CanGenerateRhythm
    CanGenerateGameLoop => right is CanGenerateGameLoop
    CanGenerateVariation => right is CanGenerateVariation
    CanGenerateArrangement => right is CanGenerateArrangement
  }
}

///|
fn patch_kind_to_tag(kind : PatchOperationKind) -> String {
  match kind {
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
fn patch_target_to_tag(target : PatchTargetKind) -> String {
  match target {
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
fn parse_task_kind_from_tag(
  value : String,
) -> Result[GenerationTaskKind, AdapterError] {
  match value {
    "MelodyContinuation" => Ok(MelodyContinuation)
    "ChordProgression" => Ok(ChordProgression)
    "BassLine" => Ok(BassLine)
    "Accompaniment" => Ok(AccompanimentTask)
    "RhythmPattern" => Ok(RhythmPatternGen)
    "GameLoop" => Ok(GameLoopTask)
    "Variation" => Ok(Variation)
    "Orchestration" => Ok(Orchestration)
    _ => Err(AdapterJsonError("unknown task kind: \{value}"))
  }
}

///|
fn parse_style_tag_from_tag(
  value : String,
) -> Result[GenerationStyleTag, AdapterError] {
  match value {
    "Pop" => Ok(Pop)
    "Jazz" => Ok(Jazz)
    "Lofi" => Ok(Lofi)
    "Cinematic" => Ok(Cinematic)
    "Ambient" => Ok(Ambient)
    "Chiptune" => Ok(Chiptune)
    "GameCombat" => Ok(GameCombat)
    "GameExploration" => Ok(GameExploration)
    _ => Err(AdapterJsonError("unknown style tag: \{value}"))
  }
}

///|
fn parse_determinism_from_tag(
  value : String,
) -> Result[GenerationDeterminism, AdapterError] {
  match value {
    "Deterministic" => Ok(Deterministic)
    "Seeded" => Ok(Seeded)
    "NonDeterministic" => Ok(NonDeterministic)
    _ => Err(AdapterJsonError("unknown determinism: \{value}"))
  }
}

///|
fn parse_patch_kind_from_tag(
  value : String,
) -> Result[PatchOperationKind, AdapterError] {
  match value {
    "AppendTrack" => Ok(AppendTrack)
    "InsertTrack" => Ok(InsertTrack)
    "ReplaceTrack" => Ok(ReplaceTrack)
    "RemoveTrack" => Ok(RemoveTrack)
    "AppendMeasure" => Ok(AppendMeasure)
    "ReplaceMeasure" => Ok(ReplaceMeasure)
    "InsertSection" => Ok(InsertSection)
    "AddNotation" => Ok(AddNotation)
    "SetTempo" => Ok(SetTempo)
    _ => Err(AdapterJsonError("unknown patch operation: \{value}"))
  }
}

///|
fn parse_patch_target_from_tag(
  value : String,
) -> Result[PatchTargetKind, AdapterError] {
  match value {
    "ScoreTarget" => Ok(ScoreTarget)
    "TrackTarget" => Ok(TrackTarget)
    "PartTarget" => Ok(PartTarget)
    "StaffTarget" => Ok(StaffTarget)
    "VoiceTarget" => Ok(VoiceTarget)
    "MeasureTarget" => Ok(MeasureTarget)
    "EventTarget" => Ok(EventTarget)
    "SectionTarget" => Ok(SectionTarget)
    _ => Err(AdapterJsonError("unknown patch target: \{value}"))
  }
}
