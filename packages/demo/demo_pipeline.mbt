// ============================================================
// Demo Pipeline — 端到端作曲资产流水线主入口
// ============================================================

///|
/// 主入口：输入标准化请求，输出完整资产包
pub fn composition_asset_pipeline_checked(
  request : CompositionRequest,
) -> Result[CompositionAssetBundle, DemoError] {
  // 1. 标准化请求
  let normalize_result = match normalize_with_warnings_checked(request) {
    Ok(r) => r
    Err(e) => return Err(e)
  }
  let normalize_warnings = normalize_result.warnings
  let normalized = normalize_result.request

  // 1b. 捕获游戏资产所需字段（在 normalized 被移动之前）
  let game_tempo_bpm = normalized.tempo.bpm
  let game_bars = normalized.bars
  let game_style = normalized.style

  // 2. 生成 + 组装 + 校验
  let demo_score = match assemble_demo_score_checked(normalized) {
    Ok(s) => s
    Err(e) => return Err(e)
  }

  // 3. 导出所有资产
  let export_result = export_all_score_assets(demo_score.score)

  // 4. Game IR（需要 timeline + score）
  let game_warnings : Array[DemoWarning] = []
  let game_ir_json = match export_result.timeline {
    Some(tl) =>
      match
        package_score_as_game_assets_checked(
          demo_score.score,
          tl,
          game_tempo_bpm,
          game_bars,
          game_style,
        ) {
        Ok(game_asset) => {
          for w in game_asset.warnings {
            game_warnings.push(w)
          }
          Some(game_asset.export_json)
        }
        Err(e) => {
          game_warnings.push(
            demo_warning("game_asset", "game_ir_failed", e.to_string()),
          )
          None
        }
      }
    None => None
  }

  // 5. 合并所有 warnings
  let all_warnings : Array[DemoWarning] = merge_warnings(
    merge_warnings(
      merge_warnings(normalize_warnings, demo_score.warnings),
      export_result.warnings,
    ),
    game_warnings,
  )

  // 6. 检查是否有任何核心资产
  let has_any = demo_score.score_json != "{}" ||
    export_result.midi_bytes is Some(_) ||
    export_result.musicxml is Some(_) ||
    export_result.wav_bytes is Some(_) ||
    export_result.web_events_json is Some(_) ||
    game_ir_json is Some(_)

  if !has_any {
    return Err(NoUsableAsset("no usable asset produced"))
  }

  Ok({
    request_id: "demo-" + request.seed.to_string(),
    score_json: Some(demo_score.score_json),
    midi_bytes: export_result.midi_bytes,
    musicxml: export_result.musicxml,
    wav_bytes: export_result.wav_bytes,
    web_events_json: export_result.web_events_json,
    game_ir_json,
    validation_json: Some(demo_score.validation_json),
    warnings: all_warnings,
  })
}

///|
/// JSON 入口：解析 JSON 字符串 -> 资产包
pub fn composition_asset_pipeline_from_json_checked(
  input : String,
) -> Result[CompositionAssetBundle, DemoError] {
  let parse_result = match composition_request_from_json_checked(input) {
    Ok(r) => r
    Err(e) => return Err(e)
  }

  let bundle = match composition_asset_pipeline_checked(parse_result.request) {
    Ok(b) => b
    Err(e) => return Err(e)
  }

  // 合并 JSON 解析阶段的 warnings
  Ok({
    ..bundle,
    warnings: merge_warnings(parse_result.warnings, bundle.warnings),
  })
}

///|
/// FFI：字符串输入 -> JSON 字符串输出
pub fn ffi_composition_assets_json(input : String) -> String {
  match composition_asset_pipeline_from_json_checked(input) {
    Ok(bundle) =>
      @json.json_stringify(
        @json.json_object([
          @json.json_field("ok", @json.json_bool(true)),
          @json.json_field(
            "data",
            @json.json_string(composition_asset_bundle_to_json(bundle)),
          ),
        ]),
      )
    Err(e) =>
      @json.json_stringify(
        @json.json_object([
          @json.json_field("ok", @json.json_bool(false)),
          @json.json_field("error", @json.json_string(e.to_string())),
        ]),
      )
  }
}

///|
/// 合并两个 warning 数组
fn merge_warnings(
  a : Array[DemoWarning],
  b : Array[DemoWarning],
) -> Array[DemoWarning] {
  let result : Array[DemoWarning] = []
  for w in a {
    result.push(w)
  }
  for w in b {
    result.push(w)
  }
  result
}
