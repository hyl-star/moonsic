// ============================================================
// Demo Pipeline 基准测试
// ============================================================

///|
/// 基准：默认请求 pipeline
test "benchmark_default_pipeline" {
  let request = default_composition_request()
  let result = composition_asset_pipeline_checked(request)
  assert_true(result is Ok(_))
}

///|
/// 基准：JSON 入口 pipeline
test "benchmark_json_pipeline" {
  let json = composition_request_to_json(default_composition_request())
  let result = composition_asset_pipeline_from_json_checked(json)
  assert_true(result is Ok(_))
}

///|
/// 基准：FFI 入口
test "benchmark_ffi_pipeline" {
  let json = composition_request_to_json(default_composition_request())
  let output = ffi_composition_assets_json(json)
  assert_true(output.length() > 0)
}

///|
/// 基准：请求标准化
test "benchmark_request_normalize" {
  let request = default_composition_request()
  let result = normalize_composition_request_checked(request)
  assert_true(result is Ok(_))
}

///|
/// 基准：导出 MIDI
test "benchmark_export_midi" {
  let request = default_composition_request()
  let normalized = match normalize_composition_request_checked(request) {
    Ok(n) => n
    Err(_) => abort("normalize failed")
  }
  let demo_score = match assemble_demo_score_checked(normalized) {
    Ok(s) => s
    Err(_) => abort("assembly failed")
  }
  let bytes = export_midi_asset_checked(demo_score.score, 480)
  assert_true(bytes is Ok(_))
  let ok_bytes = match bytes {
    Ok(b) => b
    Err(_) => abort("unexpected error")
  }
  assert_true(ok_bytes.length() > 0)
}

///|
/// 基准：导出 MusicXML
test "benchmark_export_musicxml" {
  let request = default_composition_request()
  let normalized = match normalize_composition_request_checked(request) {
    Ok(n) => n
    Err(_) => abort("normalize failed")
  }
  let demo_score = match assemble_demo_score_checked(normalized) {
    Ok(s) => s
    Err(_) => abort("assembly failed")
  }
  let xml = export_musicxml_asset_checked(demo_score.score)
  assert_true(xml is Ok(_))
}

///|
/// 基准：导出 WAV
test "benchmark_export_wav" {
  let request = default_composition_request()
  let normalized = match normalize_composition_request_checked(request) {
    Ok(n) => n
    Err(_) => abort("normalize failed")
  }
  let demo_score = match assemble_demo_score_checked(normalized) {
    Ok(s) => s
    Err(_) => abort("assembly failed")
  }
  let timeline = match export_timeline_asset_checked(demo_score.score) {
    Ok(tl) => tl
    Err(_) => abort("timeline failed")
  }
  let wav = export_wav_asset_checked(timeline)
  assert_true(wav is Ok(_))
}
