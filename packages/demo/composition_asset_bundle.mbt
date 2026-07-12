// ============================================================
// CompositionAssetBundle / DemoWarning / AssetKind / AssetStatus
// ============================================================

///|
/// 资产种类：区分不同类型导出资产
pub(all) enum AssetKind {
  ScoreJsonAsset
  MidiAsset
  MusicXmlAsset
  WavAsset
  WebEventsAsset
  GameIrAsset
}

///|
pub fn AssetKind::to_string(self : AssetKind) -> String {
  match self {
    ScoreJsonAsset => "score_json"
    MidiAsset => "midi"
    MusicXmlAsset => "musicxml"
    WavAsset => "wav"
    WebEventsAsset => "web_events"
    GameIrAsset => "game_ir"
  }
}

///|
/// 资产状态：成功 / 跳过 / 失败
pub(all) enum AssetStatus {
  AssetGenerated
  AssetSkipped
  AssetFailed
}

///|
/// 单个导出资产的阶段结果
pub(all) struct AssetResult {
  kind : AssetKind
  status : AssetStatus
  warning : DemoWarning?
}

///|
/// 可恢复警告：区分 fatal error 和 recoverable warning
pub(all) struct DemoWarning {
  stage : String
  code : String
  message : String
  recoverable : Bool
}

///|
/// 构造 DemoWarning
pub fn demo_warning(
  stage : String,
  code : String,
  message : String,
) -> DemoWarning {
  { stage, code, message, recoverable: true }
}

///|
pub fn demo_warning_fatal(
  stage : String,
  code : String,
  message : String,
) -> DemoWarning {
  { stage, code, message, recoverable: false }
}

///|
/// 标记某类资产成功
pub fn asset_result_success(kind : AssetKind) -> AssetResult {
  { kind, status: AssetGenerated, warning: None }
}

///|
/// 标记某类资产失败（可恢复）
pub fn asset_result_failed(
  kind : AssetKind,
  warning : DemoWarning,
) -> AssetResult {
  { kind, status: AssetFailed, warning: Some(warning) }
}

///|
/// 将 warning 数组转为 JSON 字符串
pub fn warnings_to_json(warnings : Array[DemoWarning]) -> String {
  let items : Array[@json.JsonValue] = []
  for w in warnings {
    items.push(
      @json.json_object([
        @json.json_field("stage", @json.json_string(w.stage)),
        @json.json_field("code", @json.json_string(w.code)),
        @json.json_field("message", @json.json_string(w.message)),
        @json.json_field("recoverable", @json.json_bool(w.recoverable)),
      ]),
    )
  }
  @json.json_stringify(@json.json_array(items))
}

///|
/// 端到端音乐资产包
pub(all) struct CompositionAssetBundle {
  request_id : String
  score_json : String?
  midi_bytes : Bytes?
  musicxml : String?
  wav_bytes : Bytes?
  web_events_json : String?
  game_ir_json : String?
  validation_json : String?
  warnings : Array[DemoWarning]
}

///|
/// 创建空资产包（仅 request_id）
pub fn empty_asset_bundle(request_id : String) -> CompositionAssetBundle {
  {
    request_id,
    score_json: None,
    midi_bytes: None,
    musicxml: None,
    wav_bytes: None,
    web_events_json: None,
    game_ir_json: None,
    validation_json: None,
    warnings: [],
  }
}

///|
/// 追加 warning 到 bundle（返回新 bundle，不可变）
pub fn append_warning(
  bundle : CompositionAssetBundle,
  warning : DemoWarning,
) -> CompositionAssetBundle {
  let ws : Array[DemoWarning] = []
  for w in bundle.warnings {
    ws.push(w)
  }
  ws.push(warning)
  {
    request_id: bundle.request_id,
    score_json: bundle.score_json,
    midi_bytes: bundle.midi_bytes,
    musicxml: bundle.musicxml,
    wav_bytes: bundle.wav_bytes,
    web_events_json: bundle.web_events_json,
    game_ir_json: bundle.game_ir_json,
    validation_json: bundle.validation_json,
    warnings: ws,
  }
}

///|
/// 把资产包摘要序列化为 JSON
pub fn composition_asset_bundle_to_json(
  bundle : CompositionAssetBundle,
) -> String {
  let fields : Array[@json.JsonField] = [
    @json.json_field("request_id", @json.json_string(bundle.request_id)),
    @json.json_field(
      "has_score_json",
      @json.json_bool(bundle.score_json is Some(_)),
    ),
    @json.json_field("has_midi", @json.json_bool(bundle.midi_bytes is Some(_))),
    @json.json_field(
      "has_musicxml",
      @json.json_bool(bundle.musicxml is Some(_)),
    ),
    @json.json_field("has_wav", @json.json_bool(bundle.wav_bytes is Some(_))),
    @json.json_field(
      "has_web_events",
      @json.json_bool(bundle.web_events_json is Some(_)),
    ),
    @json.json_field(
      "has_game_ir",
      @json.json_bool(bundle.game_ir_json is Some(_)),
    ),
    @json.json_field(
      "has_validation",
      @json.json_bool(bundle.validation_json is Some(_)),
    ),
    @json.json_field("warning_count", @json.json_int(bundle.warnings.length())),
    @json.json_field(
      "warnings",
      @json.json_array(warnings_json_values(bundle.warnings)),
    ),
  ]
  @json.json_stringify(@json.json_object(fields))
}

///|
fn warnings_json_values(
  warnings : Array[DemoWarning],
) -> Array[@json.JsonValue] {
  let items : Array[@json.JsonValue] = []
  for w in warnings {
    items.push(
      @json.json_object([
        @json.json_field("stage", @json.json_string(w.stage)),
        @json.json_field("code", @json.json_string(w.code)),
        @json.json_field("message", @json.json_string(w.message)),
        @json.json_field("recoverable", @json.json_bool(w.recoverable)),
      ]),
    )
  }
  items
}
