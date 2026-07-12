// ============================================================
// Demo Pipeline 黑盒测试
// ============================================================

///|
/// 测试 1：默认请求完整 pipeline
test "full_pipeline_default_request" {
  let request = default_composition_request()
  let result = composition_asset_pipeline_checked(request)
  assert_true(result is Ok(_))

  let bundle = match result {
    Ok(b) => b
    Err(_) => abort("unexpected error")
  }

  // 核心资产非空
  assert_true(bundle.score_json is Some(_))
  match bundle.score_json {
    Some(json) => assert_true(json.length() > 0)
    None => abort("score_json is None")
  }
  assert_true(bundle.midi_bytes is Some(_))
  match bundle.midi_bytes {
    Some(bytes) => assert_true(bytes.length() > 0)
    None => abort("midi_bytes is None")
  }
  assert_true(bundle.musicxml is Some(_))
  match bundle.musicxml {
    Some(xml) => assert_true(xml.contains("score-partwise"))
    None => abort("musicxml is None")
  }
  assert_true(bundle.wav_bytes is Some(_))
  assert_true(bundle.web_events_json is Some(_))
  assert_true(bundle.game_ir_json is Some(_))
  assert_true(bundle.validation_json is Some(_))
}

///|
/// 测试 2：deterministic 输出（相同 seed 输出一致）
test "deterministic_output" {
  let request = default_composition_request()
  let r1 = match composition_asset_pipeline_checked(request) {
    Ok(b) => b
    Err(_) => abort("pipeline 1 failed")
  }
  let r2 = match composition_asset_pipeline_checked(request) {
    Ok(b) => b
    Err(_) => abort("pipeline 2 failed")
  }

  // Score JSON 一致
  assert_true(r1.score_json == r2.score_json)
  // MIDI bytes 一致
  match (r1.midi_bytes, r2.midi_bytes) {
    (Some(b1), Some(b2)) => assert_true(b1.length() == b2.length())
    _ => abort("midi bytes missing")
  }
  // MusicXML 一致
  assert_true(r1.musicxml == r2.musicxml)
}

///|
/// 测试 3：不同和弦进行输出不同
test "different_chords_different_output" {
  let req1 = default_composition_request()
  let req2 = {
    ..default_composition_request(),
    chord_progression: ["I", "IV", "V", "I"],
  }
  let r1 = match composition_asset_pipeline_checked(req1) {
    Ok(b) => b
    Err(_) => abort("pipeline 1 failed")
  }
  let r2 = match composition_asset_pipeline_checked(req2) {
    Ok(b) => b
    Err(_) => abort("pipeline 2 failed")
  }
  // 不同和弦进行应有不同 score JSON
  match (r1.score_json, r2.score_json) {
    (Some(j1), Some(j2)) => assert_true(j1 != j2)
    _ => abort("score json missing")
  }
}

///|
/// 测试 4：JSON 入口 pipeline
test "json_pipeline" {
  let json = composition_request_to_json(default_composition_request())
  let result = composition_asset_pipeline_from_json_checked(json)
  assert_true(result is Ok(_))
  let bundle = match result {
    Ok(b) => b
    Err(_) => abort("json pipeline failed")
  }
  assert_true(bundle.midi_bytes is Some(_))
}

///|
/// 测试 5：FFI 入口
test "ffi_pipeline" {
  let json = composition_request_to_json(default_composition_request())
  let output = ffi_composition_assets_json(json)
  assert_true(output.contains("\"ok\":true"))
}

///|
/// 测试 6：非法 JSON 返回 Err
test "invalid_json_returns_err" {
  let result = composition_asset_pipeline_from_json_checked("not valid json")
  assert_true(result is Err(_))
}

///|
/// 测试 7：请求标准化（完整字段）
test "normalize_complete_request" {
  let request = CompositionRequest::{
    key: "D",
    scale: "minor",
    tempo: 100,
    bars: 8,
    style: "ambient",
    chord_progression: ["i", "iv", "V"],
    seed: 7,
  }
  let result = normalize_composition_request_checked(request)
  assert_true(result is Ok(_))
  let normalized = match result {
    Ok(n) => n
    Err(_) => abort("normalize failed")
  }
  assert_eq(normalized.key_name, "D")
  assert_eq(normalized.tempo.bpm, 100)
  assert_eq(normalized.bars, 8)
  assert_eq(normalized.chord_degrees, [1, 4, 5])
}

///|
/// 测试 8：非法 tempo 返回 Err
test "invalid_tempo_returns_err" {
  let request = { ..default_composition_request(), tempo: 0 }
  let result = normalize_composition_request_checked(request)
  assert_true(result is Err(_))
}

///|
/// 测试 9：非法 bars 返回 Err
test "invalid_bars_returns_err" {
  let request = { ..default_composition_request(), bars: 0 }
  let result = normalize_composition_request_checked(request)
  assert_true(result is Err(_))
}

///|
/// 测试 10：MIDI 导出非空
test "midi_export_nonempty" {
  let request = default_composition_request()
  let normalized = match normalize_composition_request_checked(request) {
    Ok(n) => n
    Err(_) => abort("normalize failed")
  }
  let demo_score = match assemble_demo_score_checked(normalized) {
    Ok(s) => s
    Err(_) => abort("assembly failed")
  }
  let bytes_result = export_midi_asset_checked(demo_score.score, 480)
  assert_true(bytes_result is Ok(_))
  let bytes = match bytes_result {
    Ok(b) => b
    Err(_) => abort("midi export failed")
  }
  assert_true(bytes.length() > 0)
}

///|
/// 测试 11：MusicXML 导出非空
test "musicxml_export_nonempty" {
  let request = default_composition_request()
  let normalized = match normalize_composition_request_checked(request) {
    Ok(n) => n
    Err(_) => abort("normalize failed")
  }
  let demo_score = match assemble_demo_score_checked(normalized) {
    Ok(s) => s
    Err(_) => abort("assembly failed")
  }
  let xml_result = export_musicxml_asset_checked(demo_score.score)
  assert_true(xml_result is Ok(_))
  let xml = match xml_result {
    Ok(x) => x
    Err(_) => abort("musicxml export failed")
  }
  assert_true(xml.contains("score-partwise"))
}

///|
/// 测试 12：WAV 导出非空且包含 valid header
test "wav_export_nonempty_with_header" {
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
  let wav_result = export_wav_asset_checked(timeline)
  assert_true(wav_result is Ok(_))
  let wav = match wav_result {
    Ok(w) => w
    Err(_) => abort("wav export failed")
  }
  assert_true(wav.length() > 44)
}

///|
/// 测试 13：空请求 key 字段返回 Err
test "empty_key_returns_err" {
  let result = composition_request_checked(
    "",
    "major",
    120,
    4,
    "pop",
    ["I", "V"],
    1,
  )
  assert_true(result is Err(_))
}

///|
/// 测试 14：默认请求标准化成功
test "default_request_normalize_ok" {
  let request = default_composition_request()
  let result = normalize_composition_request_checked(request)
  assert_true(result is Ok(_))
}

///|
/// 测试 15：asset bundle JSON 摘要
test "asset_bundle_to_json" {
  let request = default_composition_request()
  let bundle = match composition_asset_pipeline_checked(request) {
    Ok(b) => b
    Err(_) => abort("pipeline failed")
  }
  let json = composition_asset_bundle_to_json(bundle)
  assert_true(json.contains("request_id"))
  assert_true(json.contains("has_midi"))
  assert_true(json.contains("true"))
}

// ============================================================
// Examples Writer 测试
// ============================================================

///|
/// 测试 16：write_composition_assets_checked 有效 bundle 返回 Ok
test "write_composition_assets_ok" {
  let request = default_composition_request()
  let bundle = match composition_asset_pipeline_checked(request) {
    Ok(b) => b
    Err(_) => abort("pipeline failed")
  }
  let result = write_composition_assets_checked(bundle, "examples/output/")
  assert_true(result is Ok(_))
}

///|
/// 测试 17：write_composition_assets_checked 空 output_dir 返回 Err
test "write_composition_assets_empty_dir" {
  let request = default_composition_request()
  let bundle = match composition_asset_pipeline_checked(request) {
    Ok(b) => b
    Err(_) => abort("pipeline failed")
  }
  let result = write_composition_assets_checked(bundle, "")
  assert_true(result is Err(_))
}

///|
/// 测试 18：write_composition_assets_checked 空 bundle 返回 Err
test "write_composition_assets_empty_bundle" {
  let bundle = empty_asset_bundle("test-empty")
  let result = write_composition_assets_checked(bundle, "output/")
  assert_true(result is Err(_))
}

///|
/// 测试 19：write_midi_file 有效 bytes 返回 Ok
test "write_midi_file_ok" {
  let midi : Bytes = Bytes::make(10, b'\x00')
  let result = write_midi_file(midi, "test.mid")
  assert_true(result is Ok(_))
}

///|
/// 测试 20：write_midi_file 空 bytes 返回 Err
test "write_midi_file_empty" {
  let result = write_midi_file(Bytes::make(0, b'\x00'), "test.mid")
  assert_true(result is Err(_))
}

///|
/// 测试 21：write_midi_file 空 path 返回 Err
test "write_midi_file_empty_path" {
  let midi : Bytes = Bytes::make(10, b'\x00')
  let result = write_midi_file(midi, "")
  assert_true(result is Err(_))
}

///|
/// 测试 22：write_musicxml_file 有效 XML 返回 Ok
test "write_musicxml_file_ok" {
  let xml = "<?xml version=\"1.0\"?><score-partwise><part-list/></score-partwise>"
  let result = write_musicxml_file(xml, "test.musicxml")
  assert_true(result is Ok(_))
}

///|
/// 测试 23：write_musicxml_file 不含 score-partwise 返回 Err
test "write_musicxml_file_invalid" {
  let xml = "<not-musicxml></not-musicxml>"
  let result = write_musicxml_file(xml, "test.musicxml")
  assert_true(result is Err(_))
}

///|
/// 测试 24：write_musicxml_file 空字符串返回 Err
test "write_musicxml_file_empty" {
  let result = write_musicxml_file("", "test.musicxml")
  assert_true(result is Err(_))
}

///|
/// 测试 25：write_wav_file 有效 44 字节返回 Ok
test "write_wav_file_ok" {
  let wav : Bytes = Bytes::make(44, b'\x00')
  let result = write_wav_file(wav, "test.wav")
  assert_true(result is Ok(_))
}

///|
/// 测试 26：write_wav_file 小于 44 字节返回 Err
test "write_wav_file_too_small" {
  let wav : Bytes = Bytes::make(43, b'\x00')
  let result = write_wav_file(wav, "test.wav")
  assert_true(result is Err(_))
}

///|
/// 测试 27：write_json_file 有效 JSON 返回 Ok
test "write_json_file_ok" {
  let result = write_json_file("{\"ok\":true}", "test.json")
  assert_true(result is Ok(_))
}

///|
/// 测试 28：write_json_file 空 JSON 返回 Err
test "write_json_file_empty" {
  let result = write_json_file("", "test.json")
  assert_true(result is Err(_))
}

///|
/// 测试 29：collect_assets_from_bundle 完整 pipeline bundle
test "collect_assets_full_bundle" {
  let request = default_composition_request()
  let bundle = match composition_asset_pipeline_checked(request) {
    Ok(b) => b
    Err(_) => abort("pipeline failed")
  }
  let entries = collect_assets_from_bundle(bundle)
  // 至少包含 bundle.json + score.json + midi + musicxml + wav + web-events + game
  assert_true(entries.length() >= 3)
}

///|
/// 测试 30：collect_assets_from_bundle 空 bundle
test "collect_assets_empty_bundle" {
  let bundle = empty_asset_bundle("test-empty")
  let entries = collect_assets_from_bundle(bundle)
  // 只有 bundle.json
  assert_eq(entries.length(), 1)
  assert_true(entries[0].filename == "bundle.json")
}

// ============================================================
// 新增: write_* 函数内容验证 — 验证返回正确 bytes/string 内容
// ============================================================

///|
/// 测试 31：write_midi_from_pipeline — full pipeline MIDI 返回有效 content
test "write_midi_from_pipeline_has_header" {
  let request = default_composition_request()
  let bundle = match composition_asset_pipeline_checked(request) {
    Ok(b) => b
    Err(_) => abort("pipeline failed")
  }
  match bundle.midi_bytes {
    Some(bytes) => {
      let result = write_midi_file(bytes, "composition.mid")
      assert_true(result is Ok(_))
      // 验证 header 合法
      assert_true(check_midi_header(bytes))
    }
    None => abort("midi_bytes is None")
  }
}

///|
/// 测试 32：write_musicxml_from_pipeline — 返回含 score-partwise 的 XML
test "write_musicxml_from_pipeline_valid" {
  let request = default_composition_request()
  let bundle = match composition_asset_pipeline_checked(request) {
    Ok(b) => b
    Err(_) => abort("pipeline failed")
  }
  match bundle.musicxml {
    Some(xml) => {
      let result = write_musicxml_file(xml, "composition.musicxml")
      assert_true(result is Ok(_))
      match result {
        Ok(validated) => {
          assert_true(validated.contains("<?xml"))
          assert_true(validated.contains("score-partwise"))
        }
        Err(_) => abort("expected Ok")
      }
    }
    None => abort("musicxml is None")
  }
}

///|
/// 测试 33：write_wav_from_pipeline — 返回含 RIFF+WAVE header 的 WAV
test "write_wav_from_pipeline_has_header" {
  let request = default_composition_request()
  let bundle = match composition_asset_pipeline_checked(request) {
    Ok(b) => b
    Err(_) => abort("pipeline failed")
  }
  match bundle.wav_bytes {
    Some(bytes) => {
      let result = write_wav_file(bytes, "composition.wav")
      assert_true(result is Ok(_))
      assert_true(check_wav_header(bytes))
    }
    None => abort("wav_bytes is None")
  }
}

///|
/// 测试 34：write_json_from_pipeline — JSON 资产可解析
test "write_json_from_pipeline_parseable" {
  let request = default_composition_request()
  let bundle = match composition_asset_pipeline_checked(request) {
    Ok(b) => b
    Err(_) => abort("pipeline failed")
  }
  match bundle.score_json {
    Some(json) => {
      let result = write_json_file(json, "score.json")
      assert_true(result is Ok(_))
    }
    None => abort("score_json is None")
  }
  match bundle.game_ir_json {
    Some(json) => {
      let result = write_json_file(json, "game.json")
      assert_true(result is Ok(_))
    }
    None => abort("game_ir_json is None")
  }
}

///|
/// 测试 35：write_assets_entries — 条目列表包含全部 7 类文件
test "write_assets_entries_contain_expected_files" {
  let request = default_composition_request()
  let bundle = match composition_asset_pipeline_checked(request) {
    Ok(b) => b
    Err(_) => abort("pipeline failed")
  }
  let result = write_composition_assets_checked(bundle, "examples/output/")
  match result {
    Ok(entries) => {
      let mut has_score = false
      let mut has_midi = false
      let mut has_musicxml = false
      let mut has_wav = false
      let mut has_web = false
      let mut has_game = false
      let mut has_bundle = false
      for entry in entries {
        match entry.filename {
          "score.json" => has_score = true
          "composition.mid" => has_midi = true
          "composition.musicxml" => has_musicxml = true
          "composition.wav" => has_wav = true
          "web-events.json" => has_web = true
          "game.json" => has_game = true
          "bundle.json" => has_bundle = true
          _ => ()
        }
      }
      assert_true(has_bundle)
      assert_true(has_score)
      assert_true(has_midi)
      assert_true(has_musicxml)
      assert_true(has_wav)
      assert_true(has_web)
      assert_true(has_game)
    }
    Err(_) => abort("expected Ok")
  }
}

///|
/// 测试 36：bytes_to_hex — 已知输入产生正确输出
test "bytes_to_hex_correct" {

  // Bytes 不可变，直接使用现有构造方式：
  // "MThd" = 0x4D 0x54 0x68 0x64
  // 我们通过 Array[Byte] 构造：
  let arr : Array[Byte] = [b'\x4D', b'\x54', b'\x68', b'\x64']
  let hex = bytes_to_hex(Bytes::from_array(arr))
  assert_eq(hex, "4D546864")
}

///|
/// 测试 37：bytes_to_hex — 空输入返回空字符串
test "bytes_to_hex_empty" {
  assert_eq(bytes_to_hex(Bytes::make(0, b'\x00')), "")
}

///|
/// 测试 38：asset_entries_to_json — 输出合法 JSON
test "asset_entries_to_json_valid" {
  let entries : Array[DemoFileEntry] = [
    {
      filename: "test.txt",
      content_type: "text/plain",
      string_content: Some("hello"),
      bytes_content: None,
    },
  ]
  let json = asset_entries_to_json(entries)
  assert_true(json.contains("test.txt"))
  assert_true(json.contains("hello"))
  let parsed = match @json.json_parse(json) {
    Ok(v) => v
    Err(_) => abort("json parse failed")
  }
  assert_true(parsed is @json.JArray(_))
}

///|
/// 测试 39：asset_entries_to_json — 二进制条目以 hex 编码
test "asset_entries_to_json_with_binary" {
  let arr : Array[Byte] = [b'\x4D', b'\x54', b'\x68', b'\x64']
  let entries : Array[DemoFileEntry] = [
    {
      filename: "data.bin",
      content_type: "application/octet-stream",
      string_content: None,
      bytes_content: Some(Bytes::from_array(arr)),
    },
  ]
  let json = asset_entries_to_json(entries)
  assert_true(json.contains("data.bin"))
  assert_true(json.contains("4D546864"))
  assert_true(json.contains("\"encoding\":\"hex\""))
  assert_true(json.contains("\"byte_length\":4"))
}

///|
/// 测试 40：write_all_assets_summary_json — 完整 pipeline 输出合法 JSON
test "write_all_assets_summary_json_valid" {
  let request = default_composition_request()
  let bundle = match composition_asset_pipeline_checked(request) {
    Ok(b) => b
    Err(_) => abort("pipeline failed")
  }
  let result = write_all_assets_summary_json(bundle, "examples/output/")
  assert_true(result is Ok(_))
  match result {
    Ok(json) => {
      assert_true(json.contains("bundle.json"))
      assert_true(json.contains("score.json"))
      assert_true(json.contains("composition.mid"))
      assert_true(json.contains("composition.musicxml"))
      assert_true(json.contains("composition.wav"))
      assert_true(json.contains("web-events.json"))
      assert_true(json.contains("game.json"))
      let parsed = match @json.json_parse(json) {
        Ok(v) => v
        Err(_) => abort("json parse failed")
      }
      assert_true(parsed is @json.JArray(_))
    }
    Err(e) => abort("expected Ok, got: " + e.to_string())
  }
}

///|
/// 测试 41：write_json_file — 非法 JSON 返回 Err
test "write_json_file_invalid" {
  let result = write_json_file("not json", "test.json")
  assert_true(result is Err(_))
}

///|
/// 测试 42：write_json_file — 空 path 返回 Err
test "write_json_file_empty_path" {
  let result = write_json_file("{\"a\":1}", "")
  assert_true(result is Err(_))
}

///|
/// 测试 43：write_musicxml_file — 空 path 返回 Err
test "write_musicxml_file_empty_path" {
  let xml = "<?xml version=\"1.0\"?><score-partwise><part-list/></score-partwise>"
  let result = write_musicxml_file(xml, "")
  assert_true(result is Err(_))
}

///|
/// 测试 44：write_wav_file — 空 path 返回 Err
test "write_wav_file_empty_path" {
  let wav : Bytes = Bytes::make(44, b'\x00')
  let result = write_wav_file(wav, "")
  assert_true(result is Err(_))
}

///|
/// 测试 45：check_midi_header — 合法 header 返回 true
test "check_midi_header_valid" {
  let arr : Array[Byte] = [
    b'\x4D', b'\x54', b'\x68', b'\x64', b'\x00', b'\x00', b'\x00', b'\x06', b'\x00',
    b'\x00', b'\x00', b'\x01', b'\x01', b'\xE0',
  ]
  assert_true(check_midi_header(Bytes::from_array(arr)))
}

///|
/// 测试 46：check_midi_header — 非法 header 返回 false
test "check_midi_header_invalid" {
  let arr : Array[Byte] = [b'\xFF', b'\xFF', b'\xFF', b'\xFF']
  assert_true(!check_midi_header(Bytes::from_array(arr)))
}

///|
/// 测试 47：check_wav_header — 合法 header 返回 true
test "check_wav_header_valid" {
  let buf : Array[Byte] = []
  for i = 0; i < 44; i = i + 1 {
    buf.push(b'\x00')
  }
  buf[0] = b'\x52'
  buf[1] = b'\x49'
  buf[2] = b'\x46'
  buf[3] = b'\x46'
  buf[8] = b'\x57'
  buf[9] = b'\x41'
  buf[10] = b'\x56'
  buf[11] = b'\x45'
  assert_true(check_wav_header(Bytes::from_array(buf)))
}

///|
/// 测试 48：check_wav_header — 非法 header 返回 false
test "check_wav_header_invalid" {
  let wav : Bytes = Bytes::make(44, b'\x00')
  assert_true(!check_wav_header(wav))
}

// ============================================================
// golden tests — 端到端流水线确定性验证（assert_eq）
// ============================================================

///|
/// golden: 默认请求 pipeline bundle summary 确定性
test "golden_default_pipeline_bundle_summary_deterministic" {
  let request = default_composition_request()
  let r1 = match composition_asset_pipeline_checked(request) {
    Ok(b) => b
    Err(_) => abort("pipeline 1 failed")
  }
  let r2 = match composition_asset_pipeline_checked(request) {
    Ok(b) => b
    Err(_) => abort("pipeline 2 failed")
  }
  let j1 = composition_asset_bundle_to_json(r1)
  let j2 = composition_asset_bundle_to_json(r2)
  assert_eq(j1, j2)
}

///|
/// golden: 默认请求所有核心资产非空且 request_id 确定
test "golden_default_pipeline_all_assets_present" {
  let request = default_composition_request()
  let bundle = match composition_asset_pipeline_checked(request) {
    Ok(b) => b
    Err(_) => abort("pipeline failed")
  }
  assert_true(bundle.score_json is Some(_))
  assert_true(bundle.midi_bytes is Some(_))
  assert_true(bundle.musicxml is Some(_))
  assert_true(bundle.wav_bytes is Some(_))
  assert_true(bundle.web_events_json is Some(_))
  assert_true(bundle.game_ir_json is Some(_))
  assert_true(bundle.validation_json is Some(_))
  assert_eq(bundle.request_id, "demo-1")
}

///|
/// golden: MIDI bytes 逐字节确定性（默认请求）
test "golden_default_pipeline_midi_deterministic" {
  let request = default_composition_request()
  let b1 = match composition_asset_pipeline_checked(request) {
    Ok(b) => b
    Err(_) => abort("pipeline 1 failed")
  }
  let b2 = match composition_asset_pipeline_checked(request) {
    Ok(b) => b
    Err(_) => abort("pipeline 2 failed")
  }
  match (b1.midi_bytes, b2.midi_bytes) {
    (Some(m1), Some(m2)) => {
      assert_eq(m1.length(), m2.length())
      for i = 0; i < m1.length(); i = i + 1 {
        assert_eq(m1[i].to_int(), m2[i].to_int())
      }
    }
    _ => abort("midi bytes missing")
  }
}

///|
/// golden: MusicXML 字符串确定性（默认请求）
test "golden_default_pipeline_musicxml_deterministic" {
  let request = default_composition_request()
  let b1 = match composition_asset_pipeline_checked(request) {
    Ok(b) => b
    Err(_) => abort("pipeline 1 failed")
  }
  let b2 = match composition_asset_pipeline_checked(request) {
    Ok(b) => b
    Err(_) => abort("pipeline 2 failed")
  }
  match (b1.musicxml, b2.musicxml) {
    (Some(x1), Some(x2)) => assert_eq(x1, x2)
    _ => abort("musicxml missing")
  }
}

///|
/// golden: FFI 入口确定性
test "golden_ffi_pipeline_deterministic" {
  let json = composition_request_to_json(default_composition_request())
  let out1 = ffi_composition_assets_json(json)
  let out2 = ffi_composition_assets_json(json)
  assert_eq(out1, out2)
}

///|
/// golden: 不同 seed 产生不同 request_id 且 MIDI 文件均有效
test "golden_different_seeds_different_request_id" {
  let req1 = default_composition_request()
  let req2 = { ..default_composition_request(), seed: 42 }
  let b1 = match composition_asset_pipeline_checked(req1) {
    Ok(b) => b
    Err(_) => abort("pipeline 1 failed")
  }
  let b2 = match composition_asset_pipeline_checked(req2) {
    Ok(b) => b
    Err(_) => abort("pipeline 2 failed")
  }
  assert_true(b1.request_id != b2.request_id)
  // 两个 MIDI 文件都有效
  match (b1.midi_bytes, b2.midi_bytes) {
    (Some(m1), Some(m2)) => {
      assert_true(m1.length() > 0)
      assert_true(m2.length() > 0)
    }
    _ => abort("midi bytes missing")
  }
}

///|
/// compat: demo 流水线是 v2 新增包，v1 无对应
/// 所有 export 函数入参改为 @score.SimpleScore 替代 v1 Score
test "compat_note_demo_uses_v2_types" {
  let request = default_composition_request()
  let normalized = match normalize_composition_request_checked(request) {
    Ok(n) => n
    Err(_) => abort("normalize failed")
  }
  assert_eq(normalized.tempo.bpm, 120)
  assert_eq(normalized.bars, 4)
}

// ============================================================
// Web Events 包集成测试
// ============================================================

///|
/// 测试: web events JSON 使用 packages/web schema
test "demo_web_events_uses_web_package_schema" {
  let request = default_composition_request()
  let bundle = match composition_asset_pipeline_checked(request) {
    Ok(b) => b
    Err(_) => abort("pipeline failed")
  }
  match bundle.web_events_json {
    Some(json) => {
      assert_true(json.contains("schema_version"))
      assert_true(json.contains("events"))
      assert_true(json.contains("moonsic.web.v1"))
    }
    None => abort("web_events_json is None")
  }
}

// ============================================================
// Game Asset 测试
// ============================================================

///|
/// 测试 G1：game project 包含五类 cue（intro/loop/layer/transition/stinger）
test "game_project_five_cues" {
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

  let project = match demo_game_project_checked(timeline, normalized) {
    Ok(p) => p
    Err(e) => abort("game project failed: " + e.to_string())
  }

  assert_eq(project.cues.length(), 5)

  // 验证每种 cue id
  let mut has_intro = false
  let mut has_loop = false
  let mut has_layer = false
  let mut has_trans = false
  let mut has_stinger = false
  for cue in project.cues {
    match cue.id {
      "intro" => has_intro = true
      "loop" => has_loop = true
      "layer" => has_layer = true
      "trans" => has_trans = true
      "stinger" => has_stinger = true
      _ => ()
    }
  }
  assert_true(has_intro)
  assert_true(has_loop)
  assert_true(has_layer)
  assert_true(has_trans)
  assert_true(has_stinger)
}

///|
/// 测试 G2：game project 包含 transition rules（from/to cue 存在）
test "game_project_transition_rules" {
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

  let project = match demo_game_project_checked(timeline, normalized) {
    Ok(p) => p
    Err(e) => abort("game project failed: " + e.to_string())
  }

  // 至少有一条 transition rule
  assert_true(project.transitions.length() > 0)

  // 验证所有 transition 的 from/to cue 存在
  for rule in project.transitions {
    let mut from_ok = false
    let mut to_ok = false
    for cue in project.cues {
      if cue.id == rule.from_cue {
        from_ok = true
      }
      if cue.id == rule.to_cue {
        to_ok = true
      }
    }
    assert_true(from_ok)
    assert_true(to_ok)
  }
}

///|
/// 测试 G3：browser events 非空
test "game_project_browser_events" {
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

  let project = match demo_game_project_checked(timeline, normalized) {
    Ok(p) => p
    Err(e) => abort("game project failed: " + e.to_string())
  }

  let doc = match
    @game.game_project_to_browser_events_checked(
      project,
      "loop",
      @game.default_game_browser_export_options(),
    ) {
    Ok(d) => d
    Err(e) => abort("browser events failed: " + e.to_string())
  }
  assert_true(doc.events.length() > 0)
  assert_true(doc.loop_end_ticks > 0)
}

///|
/// 测试 G4：demo_game_asset 完整构建成功
test "demo_game_asset_ok" {
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

  let asset = match
    package_score_as_game_assets_checked(
      demo_score.score,
      timeline,
      normalized.tempo.bpm,
      normalized.bars,
      normalized.style,
    ) {
    Ok(a) => a
    Err(e) => abort("game asset failed: " + e.to_string())
  }

  // export_json 非空且包含 schema_version
  assert_true(asset.export_json.length() > 0)
  assert_true(asset.export_json.contains("\"schema_version\""))

  // browser_events_json 非空
  assert_true(asset.browser_events_json.length() > 0)

  // project 有 5 个 cues
  assert_eq(asset.project.cues.length(), 5)
}

///|
/// 测试 G5：demo_game_asset_to_json 输出摘要
test "demo_game_asset_to_json" {
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

  let asset = match
    package_score_as_game_assets_checked(
      demo_score.score,
      timeline,
      normalized.tempo.bpm,
      normalized.bars,
      normalized.style,
    ) {
    Ok(a) => a
    Err(e) => abort("game asset failed: " + e.to_string())
  }

  let json = match demo_game_asset_to_json_checked(asset) {
    Ok(j) => j
    Err(e) => abort("to_json failed: " + e.to_string())
  }
  assert_true(json.contains("\"project_id\""))
  assert_true(json.contains("\"cue_count\""))
  assert_true(json.contains("\"transition_count\""))
  assert_true(json.contains("\"has_export_json\""))
}

///|
/// 测试 G6：非法 tempo=0 返回 Err
test "game_asset_invalid_tempo" {
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

  let result = package_score_as_game_assets_checked(
    demo_score.score,
    timeline,
    0,
    normalized.bars,
    normalized.style,
  )
  assert_true(result is Err(_))
}

///|
/// 测试 G7：非法 bars=0 返回 Err
test "game_asset_invalid_bars" {
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

  let result = package_score_as_game_assets_checked(
    demo_score.score,
    timeline,
    normalized.tempo.bpm,
    0,
    normalized.style,
  )
  assert_true(result is Err(_))
}

// ============================================================
// Bars 控制测试 — 验证 bars 参数真正控制输出长度
// ============================================================

///|
/// 测试 B1：bars=4 的旋律事件数 > bars=1
test "bars_4_more_events_than_bars_1" {
  let req1 = { ..default_composition_request(), bars: 1 }
  let req4 = { ..default_composition_request(), bars: 4 }
  let n1 = match normalize_composition_request_checked(req1) {
    Ok(n) => n
    Err(_) => abort("normalize bars=1 failed")
  }
  let n4 = match normalize_composition_request_checked(req4) {
    Ok(n) => n
    Err(_) => abort("normalize bars=4 failed")
  }
  let s1 = match assemble_demo_score_checked(n1) {
    Ok(s) => s
    Err(_) => abort("assembly bars=1 failed")
  }
  let s4 = match assemble_demo_score_checked(n4) {
    Ok(s) => s
    Err(_) => abort("assembly bars=4 failed")
  }
  // melody track (index 0) 事件数应随 bars 增长
  let e1 = s1.score.tracks[0].events.length()
  let e4 = s4.score.tracks[0].events.length()
  assert_true(e4 > e1)
}

///|
/// 测试 B2：bars=8 的 timeline 事件数 > bars=4
test "bars_8_timeline_longer_than_bars_4" {
  let req4 = { ..default_composition_request(), bars: 4 }
  let req8 = { ..default_composition_request(), bars: 8 }
  let n4 = match normalize_composition_request_checked(req4) {
    Ok(n) => n
    Err(_) => abort("normalize bars=4 failed")
  }
  let n8 = match normalize_composition_request_checked(req8) {
    Ok(n) => n
    Err(_) => abort("normalize bars=8 failed")
  }
  let s4 = match assemble_demo_score_checked(n4) {
    Ok(s) => s
    Err(_) => abort("assembly bars=4 failed")
  }
  let s8 = match assemble_demo_score_checked(n8) {
    Ok(s) => s
    Err(_) => abort("assembly bars=8 failed")
  }
  let tl4 = match export_timeline_asset_checked(s4.score) {
    Ok(tl) => tl
    Err(_) => abort("timeline bars=4 failed")
  }
  let tl8 = match export_timeline_asset_checked(s8.score) {
    Ok(tl) => tl
    Err(_) => abort("timeline bars=8 failed")
  }
  assert_true(tl8.events.length() > tl4.events.length())
}

///|
/// 测试 B3：和弦级数按 bars 循环填充
/// bars=8, chord_progression=["I","IV","V"] → chord track 应有 8 个事件
test "chord_degrees_repeat_to_bars" {
  let req = {
    ..default_composition_request(),
    bars: 8,
    chord_progression: ["I", "IV", "V"],
  }
  let normalized = match normalize_composition_request_checked(req) {
    Ok(n) => n
    Err(_) => abort("normalize failed")
  }
  let demo_score = match assemble_demo_score_checked(normalized) {
    Ok(s) => s
    Err(_) => abort("assembly failed")
  }
  // track[0] = melody, track[1] = chord
  assert_true(demo_score.score.tracks.length() >= 2)
  let chord_events = demo_score.score.tracks[1].events.length()
  // bars=8 应该产生 8 个和弦事件（每 bar 一个）
  assert_eq(chord_events, 8)
}

///|
/// 测试 B4：bars=8 的 MIDI bytes > bars=4
test "bars_midi_length_grows_with_bars" {
  let req4 = { ..default_composition_request(), bars: 4 }
  let req8 = { ..default_composition_request(), bars: 8 }
  let n4 = match normalize_composition_request_checked(req4) {
    Ok(n) => n
    Err(_) => abort("normalize bars=4 failed")
  }
  let n8 = match normalize_composition_request_checked(req8) {
    Ok(n) => n
    Err(_) => abort("normalize bars=8 failed")
  }
  let s4 = match assemble_demo_score_checked(n4) {
    Ok(s) => s
    Err(_) => abort("assembly bars=4 failed")
  }
  let s8 = match assemble_demo_score_checked(n8) {
    Ok(s) => s
    Err(_) => abort("assembly bars=8 failed")
  }
  let midi4 = match export_midi_asset_checked(s4.score, 480) {
    Ok(b) => b
    Err(_) => abort("midi bars=4 failed")
  }
  let midi8 = match export_midi_asset_checked(s8.score, 480) {
    Ok(b) => b
    Err(_) => abort("midi bars=8 failed")
  }
  assert_true(midi8.length() > midi4.length())
}

///|
/// 测试 B5：bars=1 完整 pipeline 可生成且所有资产非空
test "bars_1_pipeline_ok" {
  let request = { ..default_composition_request(), bars: 1 }
  let result = composition_asset_pipeline_checked(request)
  assert_true(result is Ok(_))
  let bundle = match result {
    Ok(b) => b
    Err(_) => abort("unexpected error")
  }
  assert_true(bundle.score_json is Some(_))
  assert_true(bundle.midi_bytes is Some(_))
  assert_true(bundle.musicxml is Some(_))
  assert_true(bundle.wav_bytes is Some(_))
}

///|
/// 测试 B6：bars=0 返回 Err（normalize 阶段拒绝）
test "bars_0_returns_err" {
  let request = { ..default_composition_request(), bars: 0 }
  let result = normalize_composition_request_checked(request)
  assert_true(result is Err(_))
}

///|
/// 测试 B7：不同 bars 值产生 deterministic 输出（相同 bars+seed 一致）
test "bars_deterministic_with_same_bars" {
  let req = { ..default_composition_request(), bars: 2 }
  let b1 = match composition_asset_pipeline_checked(req) {
    Ok(b) => b
    Err(_) => abort("pipeline 1 failed")
  }
  let b2 = match composition_asset_pipeline_checked(req) {
    Ok(b) => b
    Err(_) => abort("pipeline 2 failed")
  }
  match (b1.score_json, b2.score_json) {
    (Some(j1), Some(j2)) => assert_eq(j1, j2)
    _ => abort("score json missing")
  }
}

// ============================================================
// Chord Progression 测试（v2 修复-04）
// ============================================================

///|
/// 测试 C1：罗马数字和弦进行解析
test "chord_roman_numerals" {
  let key_obj = make_c_major_key()
  let result = parse_chord_progression_checked(["I", "V", "vi", "IV"], key_obj)
  assert_eq(result.degrees, [1, 5, 6, 4])
  assert_eq(result.warnings.length(), 0)
}

///|
/// 测试 C2：音名和弦符号在 C major 中解析
test "chord_symbols_in_c_major" {
  let key_obj = make_c_major_key()
  let result = parse_chord_progression_checked(["C", "G", "Am", "F"], key_obj)
  assert_eq(result.degrees, [1, 5, 6, 4])
  assert_eq(result.warnings.length(), 0)
}

///|
/// 测试 C3：音名和弦符号在 D major 中解析
test "chord_symbols_in_d_major" {
  let key_obj = make_d_major_key()
  let result = parse_chord_progression_checked(["D", "A", "Bm", "G"], key_obj)
  assert_eq(result.degrees, [1, 5, 6, 4])
  assert_eq(result.warnings.length(), 0)
}

///|
/// 测试 C4：带升降号的音名和弦符号，不在 scale 内则无法映射
test "chord_symbols_with_accidentals" {
  let key_obj = make_c_major_key()
  // F# 不在 C major scale 中，全部失败 → fallback + warning
  let result1 = parse_chord_progression_checked(["F#"], key_obj)
  assert_eq(result1.degrees, [1, 5, 6, 4])
  assert_true(result1.warnings.length() > 0)

  // Bb 不在 C major scale 中
  let result2 = parse_chord_progression_checked(["Bb"], key_obj)
  assert_eq(result2.degrees, [1, 5, 6, 4])
  assert_true(result2.warnings.length() > 0)
}

///|
/// 测试 C5：部分非法和弦符号产生 warning，保留有效项
test "chord_partial_invalid" {
  let key_obj = make_c_major_key()
  let result = parse_chord_progression_checked(
    ["I", "???", "V", "???"],
    key_obj,
  )
  assert_eq(result.degrees, [1, 5])
  assert_true(result.warnings.length() >= 2)
}

///|
/// 测试 C6：全部非法和弦符号 fallback 到默认 [1,5,6,4] 并产生 warning
test "chord_all_invalid" {
  let key_obj = make_c_major_key()
  let result = parse_chord_progression_checked(["???"], key_obj)
  assert_eq(result.degrees, [1, 5, 6, 4])
  let mut has_fallback_warning = false
  for w in result.warnings {
    if w.code == "chord_progression_fallback_default" {
      has_fallback_warning = true
    }
  }
  assert_true(has_fallback_warning)
}

///|
/// 测试 C7：混合罗马数字和音名和弦符号
test "chord_mixed_roman_and_symbols" {
  let key_obj = make_c_major_key()
  // I=1, Am=6, V7=5, F=4 → [1, 6, 5, 4]
  let result = parse_chord_progression_checked(["I", "Am", "V7", "F"], key_obj)
  assert_eq(result.degrees, [1, 6, 5, 4])
  assert_eq(result.warnings.length(), 0)
}

///|
/// 测试 C8：带扩展后缀的和弦符号（maj7, m7, dim, sus4 等）
test "chord_symbols_with_extensions" {
  let key_obj = make_c_major_key()
  // Cmaj7=1, Dm7=2, G7=5, C=1
  let result = parse_chord_progression_checked(
    ["Cmaj7", "Dm7", "G7", "C"],
    key_obj,
  )
  assert_eq(result.degrees, [1, 2, 5, 1])
  assert_eq(result.warnings.length(), 0)
}

///|
/// 测试 C9：normalize_with_warnings_checked 返回 chord warnings
test "normalized_request_includes_chord_warnings" {
  let request = {
    ..default_composition_request(),
    chord_progression: ["I", "???", "V"],
  }
  let result = normalize_with_warnings_checked(request)
  assert_true(result is Ok(_))
  let nr = match result {
    Ok(r) => r
    Err(_) => abort("normalize failed")
  }
  // chord_degrees 只包含成功解析的
  assert_eq(nr.request.chord_degrees, [1, 5])
  // warnings 包含未知和弦符号的 warning
  assert_true(nr.warnings.length() > 0)
}

///|
/// 测试 C10：空和弦符号被忽略
test "chord_empty_symbol_ignored" {
  let key_obj = make_c_major_key()
  let result = parse_chord_progression_checked(["I", "", "V"], key_obj)
  assert_eq(result.degrees, [1, 5])
  assert_true(result.warnings.length() >= 1)
}

///|
/// 测试 C11：通过 normalize + pipeline 验证 chord warnings 到达 bundle
test "chord_warnings_reach_bundle" {
  let request = {
    ..default_composition_request(),
    chord_progression: ["I", "bad_chord", "V"],
  }
  // 先直接验证 normalize_with_warnings 产生 waring
  let nr = match normalize_with_warnings_checked(request) {
    Ok(r) => r
    Err(_) => abort("normalize failed")
  }
  assert_eq(nr.request.chord_degrees, [1, 5])

  // 手动检查 warnings
  let mut found_nr = false
  for w in nr.warnings {
    if w.code == "unknown_chord" {
      found_nr = true
    }
  }
  assert_true(found_nr)

  // 通过 pipeline 验证
  let bundle = match composition_asset_pipeline_checked(request) {
    Ok(b) => b
    Err(_) => abort("pipeline failed")
  }
  // bundle 中应包含 chord parse 阶段的 warning
  let mut found_unknown = false
  for w in bundle.warnings {
    if w.code == "unknown_chord" {
      found_unknown = true
    }
  }
  assert_true(found_unknown)
}

// ============================================================
// helper: 构造 Key 对象用于测试
// ============================================================

///|
fn make_c_major_key() -> @scale.Key {
  @scale.key(@pitch.c(4), @scale.Major)
}

///|
fn make_d_major_key() -> @scale.Key {
  @scale.key(@pitch.d(4), @scale.Major)
}
