// Tests are split by module. See moonsic_*_test.mbt files.

// ============================================================
// MusicXML 导出测试
// ============================================================

///|
/// 基础音符导出：C4 四分音符 -> 应包含 score-partwise、step C、octave 4、duration 480
test "musicxml_basic_note_export" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let s = @moonsic.score1(t)
  let opts = @moonsic.default_musicxml_export_options()
  match @moonsic.score_to_musicxml_string_checked(s, opts) {
    Ok(xml) => {
      assert_true(xml.contains("score-partwise"))
      assert_true(xml.contains("part-list"))
      assert_true(xml.contains("measure"))
      assert_true(xml.contains("<step>C</step>"))
      assert_true(xml.contains("<octave>4</octave>"))
      assert_true(xml.contains("<duration>480</duration>"))
      assert_true(xml.contains("<type>quarter</type>"))
    }
    Err(e) => _panic(e.to_string())
  }
}

///|
/// 休止符导出：Rest 元素应包含 <rest/>
test "musicxml_rest_export" {
  let events = [
    @moonsic.r(@moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
  ]
  let t = @moonsic.melody(events)
  let s = @moonsic.score1(t)
  let opts = @moonsic.default_musicxml_export_options()
  match @moonsic.score_to_musicxml_string_checked(s, opts) {
    Ok(xml) => {
      assert_true(xml.contains("<rest/>"))
      assert_true(xml.contains("<step>D</step>"))
    }
    Err(e) => _panic(e.to_string())
  }
}

///|
/// 和弦导出：C major chord -> 第二个和第三个音应包含 <chord/>
test "musicxml_chord_export" {
  let evt = @moonsic.major(@moonsic.c(4), @moonsic.quarter())
  let t = @moonsic.melody([evt])
  let s = @moonsic.score1(t)
  let opts = @moonsic.default_musicxml_export_options()
  match @moonsic.score_to_musicxml_string_checked(s, opts) {
    Ok(xml) => {
      assert_true(xml.contains("<step>C</step>"))
      assert_true(xml.contains("<step>E</step>"))
      assert_true(xml.contains("<step>G</step>"))
      // Check chord appears at least twice (for E and G)
      let chord_count = _count_occurrences(xml, "<chord/>")
      assert_eq(chord_count, 2)
    }
    Err(e) => _panic(e.to_string())
  }
}

///|
/// 拍号导出：3/4 score -> attributes 包含 beats 3、beat-type 4
test "musicxml_time_signature_export" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let s = @moonsic.score_with_tempo(
    [t],
    @moonsic.tempo(120),
    @moonsic.time_signature(3, 4),
  )
  let opts = @moonsic.default_musicxml_export_options()
  match @moonsic.score_to_musicxml_string_checked(s, opts) {
    Ok(xml) => {
      assert_true(xml.contains("<beats>3</beats>"))
      assert_true(xml.contains("<beat-type>4</beat-type>"))
    }
    Err(e) => _panic(e.to_string())
  }
}

///|
/// XML escaping 测试：part name 含 A&B <test> -> 应被正确转义
test "musicxml_xml_escaping" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let s = @moonsic.score1(t)
  let opts = @moonsic.MusicXmlExportOptions::{
    divisions: @moonsic.DEFAULT_PPQ,
    document_kind: @moonsic.Partwise,
    include_xml_header: true,
    strict: false,
    part_name_fallback: "A&B <test>",
  }
  match @moonsic.score_to_musicxml_string_checked(s, opts) {
    Ok(xml) => {
      assert_true(xml.contains("A&amp;B &lt;test&gt;"))
      // Should not contain raw unescaped text
      assert_true(!xml.contains("A&B <test>"))
    }
    Err(e) => _panic(e.to_string())
  }
}

///|
/// 错误路径：divisions <= 0 -> 返回 Err(InvalidMusicXmlOptions)
test "musicxml_invalid_divisions" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let s = @moonsic.score1(t)
  let opts = @moonsic.MusicXmlExportOptions::{
    divisions: 0,
    document_kind: @moonsic.Partwise,
    include_xml_header: true,
    strict: false,
    part_name_fallback: "Piano",
  }
  let result = @moonsic.score_to_musicxml_checked(s, opts)
  match result {
    Err(@moonsic.InvalidMusicXmlOptions(_)) => ()
    Ok(_) => _panic("expected Err but got Ok")
    _ => _panic("expected InvalidMusicXmlOptions")
  }
}

///|
/// 错误路径：strict mode error -> musicxml_validate_export_ready 后
/// 使用 musicxml_validation_passed 检查
test "musicxml_strict_validation" {
  let s = @moonsic.score([])
  let opts = @moonsic.MusicXmlExportOptions::{
    divisions: @moonsic.DEFAULT_PPQ,
    document_kind: @moonsic.Partwise,
    include_xml_header: true,
    strict: true,
    part_name_fallback: "Piano",
  }
  let report = @moonsic.musicxml_validate_export_ready(s, opts)
  // Empty tracks -> Error severity; strict mode should fail
  let passed = @moonsic.musicxml_validation_passed(report, true)
  assert_true(!passed)
  // In non-strict mode, Error does NOT fail
  let passed2 = @moonsic.musicxml_validation_passed(report, false)
  assert_true(passed2)
}

///|
/// FFI 测试：合法 Score JSON -> 返回 ok:true 且 data.xml 存在
test "musicxml_ffi_valid_input" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let s = @moonsic.score1(t)
  let json = @moonsic.score_to_json(s)
  let result = @moonsic.ffi_score_to_musicxml_json(json)
  assert_true(result.contains("\"ok\":true"))
  assert_true(result.contains("\"xml\""))
  assert_true(result.contains("score-partwise"))
}

///|
/// FFI 测试：非法 JSON -> 返回 ok:false
test "musicxml_ffi_invalid_input" {
  let result = @moonsic.ffi_score_to_musicxml_json("not valid json")
  assert_true(result.contains("\"ok\":false"))
  assert_true(result.contains("\"error\""))

  let result2 = @moonsic.ffi_score_to_musicxml_json("{}")
  assert_true(result2.contains("\"ok\":false"))
}

///|
/// 附点音符：Dotted quarter -> 包含 <dot/> 和复附点
test "musicxml_dotted_note_export" {
  let dq = @moonsic.dotted(@moonsic.Duration::Quarter)
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), dq)])
  let s = @moonsic.score1(t)
  let opts = @moonsic.default_musicxml_export_options()
  match @moonsic.score_to_musicxml_string_checked(s, opts) {
    Ok(xml) => {
      assert_true(xml.contains("<dot/>"))
      // Dotted quarter duration = 1.5 * 480 = 720
      assert_true(xml.contains("<duration>720</duration>"))
      assert_true(xml.contains("<type>quarter</type>"))
    }
    Err(e) => _panic(e.to_string())
  }
}

///|
/// 多事件多小节：2个四分音符 4/4拍 -> 应产生1个小节
test "musicxml_multiple_events_single_measure" {
  let events = [
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.e(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.f(4), @moonsic.quarter()),
  ]
  let t = @moonsic.melody(events)
  let s = @moonsic.score1(t)
  let opts = @moonsic.default_musicxml_export_options()
  match @moonsic.score_to_musicxml_string_checked(s, opts) {
    Ok(xml) => {
      // All 4 notes in one measure
      assert_true(xml.contains("<measure number=\"1\">"))
      let count = _count_occurrences(xml, "<measure ")
      assert_eq(count, 1)
    }
    Err(e) => _panic(e.to_string())
  }
}

///|
/// 多小节测试：5个四分音符 4/4拍 -> 应产生2个小节
test "musicxml_multiple_measures" {
  let events = [
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.e(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.f(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.g(4), @moonsic.quarter()),
  ]
  let t = @moonsic.melody(events)
  let s = @moonsic.score1(t)
  let opts = @moonsic.default_musicxml_export_options()
  match @moonsic.score_to_musicxml_string_checked(s, opts) {
    Ok(xml) => {
      assert_true(xml.contains("<measure number=\"2\">"))
      // Should NOT have measure 3
      assert_true(!xml.contains("<measure number=\"3\">"))
    }
    Err(e) => _panic(e.to_string())
  }
}

///|
/// 便捷 API：score_to_musicxml_string 返回有效 XML
test "musicxml_convenience_api" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let s = @moonsic.score1(t)
  let xml = @moonsic.score_to_musicxml_string(s)
  assert_true(xml.contains("score-partwise"))
  assert_true(xml.contains("<step>C</step>"))
}

///|
/// 默认导出选项测试
test "musicxml_default_options" {
  let opts = @moonsic.default_musicxml_export_options()
  assert_eq(opts.divisions, @moonsic.DEFAULT_PPQ)
  assert_true(opts.include_xml_header)
  assert_true(!opts.strict)
  assert_true(opts.document_kind is @moonsic.Partwise)
}

///|
/// Division 变更测试：自定义 divisions=960 -> duration 应为 960
test "musicxml_custom_divisions" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let s = @moonsic.score1(t)
  let opts = @moonsic.MusicXmlExportOptions::{
    divisions: 960,
    document_kind: @moonsic.Partwise,
    include_xml_header: false,
    strict: false,
    part_name_fallback: "Piano",
  }
  match @moonsic.score_to_musicxml_string_checked(s, opts) {
    Ok(xml) => {
      assert_true(xml.contains("<duration>960</duration>"))
      assert_true(xml.contains("<divisions>960</divisions>"))
    }
    Err(e) => _panic(e.to_string())
  }
}

///|
/// ScoreLayout 转换：ScoreLayout -> MusicXmlScore -> XML
test "musicxml_score_layout_conversion" {
  let part = @moonsic.empty_part("Piano")
  let layout = match
    @moonsic.make_score_layout("Test", @moonsic.DEFAULT_PPQ, [part]) {
    Ok(l) => l
    Err(e) => _panic(e.to_string())
  }
  let opts = @moonsic.default_musicxml_export_options()
  match @moonsic.score_layout_to_musicxml_checked(layout, opts) {
    Ok(doc) => {
      assert_eq(doc.parts.length(), 0)
      assert_eq(doc.divisions, @moonsic.DEFAULT_PPQ)
    }
    Err(e) => _panic(e.to_string())
  }
}

///|
/// 校验测试：合法 score 应通过校验
test "musicxml_validate_passes" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let s = @moonsic.score1(t)
  let opts = @moonsic.default_musicxml_export_options()
  let report = @moonsic.musicxml_validate_export_ready(s, opts)
  let passed = @moonsic.musicxml_validation_passed(report, false)
  assert_true(passed)
  let passed_strict = @moonsic.musicxml_validation_passed(report, true)
  assert_true(passed_strict)
}

///|
/// MusicXmlError::to_string 测试
test "musicxml_error_to_string" {
  let e = @moonsic.InvalidMusicXmlOptions("divisions must be > 0, got 0")
  let msg = e.to_string()
  assert_true(msg.contains("无效 MusicXML 选项"))
  assert_true(msg.contains("divisions must be > 0"))

  let e2 = @moonsic.MusicXmlUnsupported("feature X not implemented")
  let msg2 = e2.to_string()
  assert_true(msg2.contains("MusicXML 不支持"))

  let e3 = @moonsic.MusicXmlValidationFailed("validation error")
  let msg3 = e3.to_string()
  assert_true(msg3.contains("MusicXML 校验失败"))
}

///|
/// 空 Score fallback 测试：空 Score 导出 via convenience API
test "musicxml_empty_score_convenience" {
  let s = @moonsic.score([])
  let xml = @moonsic.score_to_musicxml_string(s)
  assert_true(xml.contains("score-partwise"))
  assert_true(xml.contains("part-list"))
}

// ============================================================
// 测试辅助函数
// ============================================================

///|
/// 统计子串在字符串中的出现次数
fn _count_occurrences(s : String, target : String) -> Int {
  let mut count = 0
  let mut pos = 0
  while pos + target.length() <= s.length() {
    let mut matched = true
    let mut i = 0
    while i < target.length() {
      if s[pos + i] != target[i] {
        matched = false
      }
      i = i + 1
    }
    if matched {
      count = count + 1
    }
    pos = pos + 1
  }
  count
}

// ============================================================
// adapter 模块测试 -- AI/外部生成器接入协议
// ============================================================

///|
/// 测试 ExternalGenerationError 消息输出
test "adapter: ExternalGenerationError::to_string" {
  let e = @moonsic.InvalidGenerationRequest("bad request")
  assert_eq(e.to_string(), "无效生成请求：bad request")
  let e2 = @moonsic.ProviderCapabilityMismatch("missing cap")
  assert_eq(e2.to_string(), "生成器能力不匹配：missing cap")
  let e3 = @moonsic.InvalidGenerationConstraint("conflict")
  assert_eq(e3.to_string(), "无效约束：conflict")
  let e4 = @moonsic.InvalidGenerationPatch("empty")
  assert_eq(e4.to_string(), "无效补丁：empty")
  let e5 = @moonsic.PatchTargetNotFound("index 5")
  assert_eq(e5.to_string(), "补丁目标不存在：index 5")
  let e6 = @moonsic.PatchConflict("overlap")
  assert_eq(e6.to_string(), "补丁冲突：overlap")
  let e7 = @moonsic.ExternalGenerationParseError("bad json")
  assert_eq(e7.to_string(), "外部生成器解析错误：bad json")
  let e8 = @moonsic.ExternalGenerationUnsupported("not yet")
  assert_eq(e8.to_string(), "不支持的操作：not yet")
}

///|
/// 测试 generation_request_checked：合法约束成功
test "adapter: generation_request_checked valid" {
  let ctx = {
    score_summary: "test",
    key_hint: None,
    time_signature: @moonsic.four_four(),
    tempo: @moonsic.default_tempo(),
    bars: 4,
    track_count: 1,
    ppq: 480,
  }
  let constraints = [@moonsic.MinBars(2), @moonsic.MaxBars(8)]
  let result = @moonsic.generation_request_checked(
    @moonsic.MelodyContinuation,
    ctx,
    constraints,
  )
  match result {
    Ok(req) => {
      assert_eq(req.task, @moonsic.MelodyContinuation)
      assert_eq(req.constraints.length(), 2)
    }
    Err(_) => abort("expected Ok")
  }
}

///|
/// 测试 generation_request_checked：MinBars > MaxBars 冲突
test "adapter: generation_request_checked constraint conflict MinBars > MaxBars" {
  let ctx = {
    score_summary: "test",
    key_hint: None,
    time_signature: @moonsic.four_four(),
    tempo: @moonsic.default_tempo(),
    bars: 4,
    track_count: 1,
    ppq: 480,
  }
  let constraints = [@moonsic.MinBars(8), @moonsic.MaxBars(4)]
  let result = @moonsic.generation_request_checked(
    @moonsic.MelodyContinuation,
    ctx,
    constraints,
  )
  match result {
    Err(@moonsic.InvalidGenerationConstraint(_)) => ()
    Ok(_) => abort("expected Err")
    _ => abort("expected InvalidGenerationConstraint")
  }
}

///|
/// 测试 generation_request_checked：MinBars <= 0 无效
test "adapter: generation_request_checked MinBars <= 0 invalid" {
  let ctx = {
    score_summary: "test",
    key_hint: None,
    time_signature: @moonsic.four_four(),
    tempo: @moonsic.default_tempo(),
    bars: 4,
    track_count: 1,
    ppq: 480,
  }
  let constraints = [@moonsic.MinBars(0)]
  let result = @moonsic.generation_request_checked(
    @moonsic.MelodyContinuation,
    ctx,
    constraints,
  )
  match result {
    Err(@moonsic.InvalidGenerationConstraint(_)) => ()
    Ok(_) => abort("expected Err")
    _ => abort("expected InvalidGenerationConstraint")
  }
}

///|
/// 测试 validate_generation_request：capability 匹配成功
test "adapter: validate_generation_request capability match" {
  let ctx = {
    score_summary: "test",
    key_hint: None,
    time_signature: @moonsic.four_four(),
    tempo: @moonsic.default_tempo(),
    bars: 4,
    track_count: 1,
    ppq: 480,
  }
  let request = match @moonsic.generation_request_checked(@moonsic.MelodyContinuation, ctx, []) {
    Ok(r) => r
    Err(e) => abort("unexpected: \{e.to_string()}")
  }
  let provider = @moonsic.generation_provider_info(
    "test_provider",
    @moonsic.LocalRuleProvider,
    [@moonsic.CanGenerateMelody],
  )
  let result = @moonsic.validate_generation_request(request, provider)
  match result {
    Ok(()) => ()
    Err(e) => abort("expected Ok, got: \{e.to_string()}")
  }
}

///|
/// 测试 validate_generation_request：capability 不匹配
test "adapter: validate_generation_request capability mismatch" {
  let ctx = {
    score_summary: "test",
    key_hint: None,
    time_signature: @moonsic.four_four(),
    tempo: @moonsic.default_tempo(),
    bars: 4,
    track_count: 1,
    ppq: 480,
  }
  let request = match
    @moonsic.generation_request_checked(@moonsic.MelodyContinuation, ctx, []) {
    Ok(r) => r
    Err(e) => abort("unexpected: \{e.to_string()}")
  }
  let provider = @moonsic.generation_provider_info(
    "harmony_only",
    @moonsic.LocalRuleProvider,
    [@moonsic.CanGenerateHarmony],
  )
  let result = @moonsic.validate_generation_request(request, provider)
  match result {
    Err(@moonsic.ProviderCapabilityMismatch(_)) => ()
    Ok(_) => abort("expected Err")
    _ => abort("expected ProviderCapabilityMismatch")
  }
}

///|
/// 测试 generation_patch_checked：空 operations 失败
test "adapter: generation_patch_checked empty operations fails" {
  let result = @moonsic.generation_patch_checked([])
  match result {
    Err(@moonsic.InvalidGenerationPatch(_)) => ()
    Ok(_) => abort("expected Err")
    _ => abort("expected InvalidGenerationPatch")
  }
}

///|
/// 测试 generation_patch_checked：合法 AppendTrack 成功
test "adapter: generation_patch_checked valid AppendTrack" {
  let ops = [
    {
      kind: @moonsic.AppendTrack,
      target: @moonsic.ScoreTarget,
      path: "/score",
      payload_json: "{\"channel\":0,\"program\":-1,\"volume\":1,\"pan\":0,\"mute\":false,\"events\":[]}",
    },
  ]
  let result = @moonsic.generation_patch_checked(ops)
  match result {
    Ok(patch) => {
      assert_eq(patch.operations.length(), 1)
      assert_eq(patch.source, "moonsic")
    }
    Err(e) => abort("expected Ok, got: \{e.to_string()}")
  }
}

///|
/// 测试 generation_patch_checked：ReplaceTrack 必须 TrackTarget
test "adapter: generation_patch_checked ReplaceTrack requires TrackTarget" {
  let ops = [
    {
      kind: @moonsic.ReplaceTrack,
      target: @moonsic.ScoreTarget,
      path: "/score/tracks/0",
      payload_json: "{}",
    },
  ]
  let result = @moonsic.generation_patch_checked(ops)
  match result {
    Err(@moonsic.InvalidGenerationPatch(_)) => ()
    Ok(_) => abort("expected Err")
    _ => abort("expected InvalidGenerationPatch")
  }
}

///|
/// 测试 score_context_from_score
test "adapter: score_context_from_score" {
  let track1 = @moonsic.track([
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.e(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.f(4), @moonsic.quarter()),
  ])
  let s = @moonsic.score([track1])
  let ctx = @moonsic.score_context_from_score(s, 480)
  assert_eq(ctx.track_count, 1)
  assert_eq(ctx.ppq, 480)
  assert_eq(ctx.tempo.bpm, 120)
  assert_true(ctx.bars >= 1)
}

///|
/// 测试 deterministic_mock_generate：MelodyContinuation
test "adapter: deterministic_mock_generate MelodyContinuation" {
  let ctx = {
    score_summary: "test",
    key_hint: None,
    time_signature: @moonsic.four_four(),
    tempo: @moonsic.default_tempo(),
    bars: 4,
    track_count: 1,
    ppq: 480,
  }
  let request = match
    @moonsic.generation_request_checked(@moonsic.MelodyContinuation, ctx, []) {
    Ok(r) => r
    Err(e) => abort("unexpected: \{e.to_string()}")
  }
  let resp = match @moonsic.deterministic_mock_generate(request) {
    Ok(r) => r
    Err(e) => abort("unexpected: \{e.to_string()}")
  }
  assert_eq(resp.candidates.length(), 1)
  let cand = resp.candidates[0]
  assert_eq(cand.fragment.tracks.length(), 1)
  assert_eq(cand.fragment.tracks[0].events.length(), 8)
}

///|
/// 测试 deterministic_mock_generate：ChordProgression
test "adapter: deterministic_mock_generate ChordProgression" {
  let ctx = {
    score_summary: "test",
    key_hint: None,
    time_signature: @moonsic.four_four(),
    tempo: @moonsic.default_tempo(),
    bars: 4,
    track_count: 1,
    ppq: 480,
  }
  let request = match
    @moonsic.generation_request_checked(@moonsic.ChordProgression, ctx, []) {
    Ok(r) => r
    Err(e) => abort("unexpected: \{e.to_string()}")
  }
  let resp = match @moonsic.deterministic_mock_generate(request) {
    Ok(r) => r
    Err(e) => abort("unexpected: \{e.to_string()}")
  }
  assert_eq(resp.candidates.length(), 1)
  assert_eq(resp.candidates[0].fragment.tracks.length(), 1)
}

///|
/// 测试 deterministic_mock_generate：确定性（相同输入 = 相同输出）
test "adapter: deterministic_mock_generate determinism" {
  let ctx = {
    score_summary: "test",
    key_hint: None,
    time_signature: @moonsic.four_four(),
    tempo: @moonsic.default_tempo(),
    bars: 4,
    track_count: 1,
    ppq: 480,
  }
  let request = match
    @moonsic.generation_request_checked(@moonsic.MelodyContinuation, ctx, [
      @moonsic.MinBars(4),
      @moonsic.MaxBars(4),
    ]) {
    Ok(r) => r
    Err(e) => abort("unexpected: \{e.to_string()}")
  }
  let resp1 = match @moonsic.deterministic_mock_generate(request) {
    Ok(r) => r
    Err(e) => abort("unexpected: \{e.to_string()}")
  }
  let resp2 = match @moonsic.deterministic_mock_generate(request) {
    Ok(r) => r
    Err(e) => abort("unexpected: \{e.to_string()}")
  }
  let json1 = @moonsic.generation_response_to_json(resp1)
  let json2 = @moonsic.generation_response_to_json(resp2)
  assert_eq(json1, json2)
}

///|
/// 测试 generation_request_to_json / generation_request_from_json 往返
test "adapter: generation_request JSON round-trip" {
  let ctx = {
    score_summary: "test score",
    key_hint: None,
    time_signature: @moonsic.four_four(),
    tempo: @moonsic.default_tempo(),
    bars: 4,
    track_count: 2,
    ppq: 480,
  }
  let constraints = [
    @moonsic.MinBars(2),
    @moonsic.MaxBars(8),
    @moonsic.TargetDensity(0.5),
  ]
  let request = match
    @moonsic.generation_request_checked(
      @moonsic.MelodyContinuation,
      ctx,
      constraints,
    ) {
    Ok(r) => r
    Err(e) => abort("unexpected: \{e.to_string()}")
  }
  let json = @moonsic.generation_request_to_json(request)
  let parsed = match @moonsic.generation_request_from_json(json) {
    Ok(r) => r
    Err(e) => abort("unexpected parse error: \{e.to_string()}")
  }
  assert_eq(parsed.task, @moonsic.MelodyContinuation)
  assert_eq(parsed.context.track_count, 2)
  assert_eq(parsed.constraints.length(), 3)
}

///|
/// 测试 generation_response_to_json / generation_response_from_json 往返
test "adapter: generation_response JSON round-trip" {
  let ctx = {
    score_summary: "test",
    key_hint: None,
    time_signature: @moonsic.four_four(),
    tempo: @moonsic.default_tempo(),
    bars: 4,
    track_count: 1,
    ppq: 480,
  }
  let request = match
    @moonsic.generation_request_checked(@moonsic.MelodyContinuation, ctx, []) {
    Ok(r) => r
    Err(e) => abort("unexpected: \{e.to_string()}")
  }
  let response = match @moonsic.deterministic_mock_generate(request) {
    Ok(r) => r
    Err(e) => abort("unexpected: \{e.to_string()}")
  }
  let json = @moonsic.generation_response_to_json(response)
  let parsed = match @moonsic.generation_response_from_json(json) {
    Ok(r) => r
    Err(e) => abort("unexpected parse error: \{e.to_string()}")
  }
  assert_eq(parsed.candidates.length(), 1)
}

///|
/// 测试 ffi_external_generate_mock_json：成功
test "adapter: ffi_external_generate_mock_json ok" {
  let ctx = {
    score_summary: "test",
    key_hint: None,
    time_signature: @moonsic.four_four(),
    tempo: @moonsic.default_tempo(),
    bars: 4,
    track_count: 1,
    ppq: 480,
  }
  let request = match
    @moonsic.generation_request_checked(@moonsic.MelodyContinuation, ctx, []) {
    Ok(r) => r
    Err(e) => abort("unexpected: \{e.to_string()}")
  }
  let req_json = @moonsic.generation_request_to_json(request)
  let ffi_result = @moonsic.ffi_external_generate_mock_json(req_json)
  assert_true(ffi_result.has_prefix("{\"ok\":true"))
}

///|
/// 测试 ffi_external_generate_mock_json：非法 JSON 返回错误
test "adapter: ffi_external_generate_mock_json bad input" {
  let ffi_result = @moonsic.ffi_external_generate_mock_json("not valid json")
  assert_true(ffi_result.has_prefix("{\"ok\":false"))
  assert_true(ffi_result.contains("\"error\""))
}

///|
/// 测试 ffi_validate_generation_patch_json：成功
test "adapter: ffi_validate_generation_patch_json ok" {
  let ctx = {
    score_summary: "test",
    key_hint: None,
    time_signature: @moonsic.four_four(),
    tempo: @moonsic.default_tempo(),
    bars: 4,
    track_count: 1,
    ppq: 480,
  }
  let request = match
    @moonsic.generation_request_checked(@moonsic.MelodyContinuation, ctx, []) {
    Ok(r) => r
    Err(e) => abort("unexpected: \{e.to_string()}")
  }
  let req_json = @moonsic.generation_request_to_json(request)
  let ops = [
    {
      kind: @moonsic.AppendTrack,
      target: @moonsic.ScoreTarget,
      path: "/score",
      payload_json: "{\"channel\":0,\"program\":-1,\"volume\":1,\"pan\":0,\"mute\":false,\"events\":[]}",
    },
  ]
  let patch = match @moonsic.generation_patch_checked(ops) {
    Ok(p) => p
    Err(e) => abort("unexpected: \{e.to_string()}")
  }
  let patch_json = "{\"operations\":[{\"kind\":\"AppendTrack\",\"target\":\"ScoreTarget\",\"path\":\"/score\",\"payload_json\":\"\"}],\"source\":\"moonsic\"}"
  let input = "{\"request\":" + req_json + ",\"patch\":" + patch_json + "}"
  let result = @moonsic.ffi_validate_generation_patch_json(input)
  assert_true(result.has_prefix("{\"ok\":true"))
}

///|
/// 测试 apply_generation_patch_checked：AppendTrack
test "adapter: apply_generation_patch_checked AppendTrack" {
  let track1 = @moonsic.track([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let original_score = @moonsic.score([track1])
  assert_eq(original_score.track_count(), 1)
  let empty_track_json = @moonsic.track_to_json(@moonsic.empty_track())
  let ops = [
    {
      kind: @moonsic.AppendTrack,
      target: @moonsic.ScoreTarget,
      path: "/score",
      payload_json: empty_track_json,
    },
  ]
  let patch = match @moonsic.generation_patch_checked(ops) {
    Ok(p) => p
    Err(e) => abort("unexpected: \{e.to_string()}")
  }
  let new_score = match
    @moonsic.apply_generation_patch_checked(original_score, patch) {
    Ok(s) => s
    Err(e) => abort("unexpected: \{e.to_string()}")
  }
  assert_eq(new_score.track_count(), 2)
}

///|
/// 测试 apply_generation_patch_checked：RemoveTrack
test "adapter: apply_generation_patch_checked RemoveTrack" {
  let track1 = @moonsic.track([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let track2 = @moonsic.track([@moonsic.n(@moonsic.d(4), @moonsic.quarter())])
  let original_score = @moonsic.score([track1, track2])
  assert_eq(original_score.track_count(), 2)
  let ops = [
    {
      kind: @moonsic.RemoveTrack,
      target: @moonsic.TrackTarget,
      path: "/score/tracks/0",
      payload_json: "",
    },
  ]
  let patch = match @moonsic.generation_patch_checked(ops) {
    Ok(p) => p
    Err(e) => abort("unexpected: \{e.to_string()}")
  }
  let new_score = match
    @moonsic.apply_generation_patch_checked(original_score, patch) {
    Ok(s) => s
    Err(e) => abort("unexpected: \{e.to_string()}")
  }
  assert_eq(new_score.track_count(), 1)
}

///|
/// 测试 validate_generation_patch：track 索引超出范围
test "adapter: validate_generation_patch track index out of range" {
  let ctx = {
    score_summary: "test",
    key_hint: None,
    time_signature: @moonsic.four_four(),
    tempo: @moonsic.default_tempo(),
    bars: 4,
    track_count: 1,
    ppq: 480,
  }
  let ops = [
    {
      kind: @moonsic.ReplaceTrack,
      target: @moonsic.TrackTarget,
      path: "/score/tracks/99",
      payload_json: "{}",
    },
  ]
  let patch = match @moonsic.generation_patch_checked(ops) {
    Ok(p) => p
    Err(e) => abort("unexpected: \{e.to_string()}")
  }
  let result = @moonsic.validate_generation_patch(patch, ctx)
  match result {
    Err(@moonsic.PatchTargetNotFound(_)) => ()
    Ok(_) => abort("expected Err")
    _ => abort("expected PatchTargetNotFound")
  }
}

///|
/// 测试 generation_provider_info：MockProvider 默认 determinism
test "adapter: generation_provider_info MockProvider determinism" {
  let provider = @moonsic.generation_provider_info(
    "mock",
    @moonsic.MockProvider,
    [@moonsic.CanGenerateMelody],
  )
  assert_eq(provider.kind, @moonsic.MockProvider)
  assert_eq(provider.determinism, @moonsic.Deterministic)
}

///|
/// 测试 TargetDensity 约束校验：超出范围
test "adapter: TargetDensity out of range" {
  let ctx = {
    score_summary: "test",
    key_hint: None,
    time_signature: @moonsic.four_four(),
    tempo: @moonsic.default_tempo(),
    bars: 4,
    track_count: 1,
    ppq: 480,
  }
  let constraints = [@moonsic.TargetDensity(1.5)]
  let result = @moonsic.generation_request_checked(
    @moonsic.MelodyContinuation,
    ctx,
    constraints,
  )
  match result {
    Err(@moonsic.InvalidGenerationConstraint(_)) => ()
    Ok(_) => abort("expected Err")
    _ => abort("expected InvalidGenerationConstraint")
  }
}

///|
/// 测试 AllowedPitchRange 约束校验：low > high
test "adapter: AllowedPitchRange low > high" {
  let ctx = {
    score_summary: "test",
    key_hint: None,
    time_signature: @moonsic.four_four(),
    tempo: @moonsic.default_tempo(),
    bars: 4,
    track_count: 1,
    ppq: 480,
  }
  let constraints = [@moonsic.AllowedPitchRange(72, 60)]
  let result = @moonsic.generation_request_checked(
    @moonsic.MelodyContinuation,
    ctx,
    constraints,
  )
  match result {
    Err(@moonsic.InvalidGenerationConstraint(_)) => ()
    Ok(_) => abort("expected Err")
    _ => abort("expected InvalidGenerationConstraint")
  }
}

// ============================================================
// 规则型音乐生成模块测试 (generate.mbt)
// ============================================================

///|
/// 旋律生成：C major + FourQuarters + StepwiseUp
/// 预期：4 个 Note 事件，音高属于 C major，总拍数 4.0
test "generate_melody_checked_basic" {
  let key = @moonsic.key(@moonsic.c(4), @moonsic.Major)
  let rhythm = @moonsic.rhythm_template(@moonsic.FourQuarters)
  let config = {
    mode: @moonsic.MelodyOnly,
    contour: @moonsic.StepwiseUp,
    range_low: @moonsic.c(4),
    range_high: @moonsic.c(6),
    seed: None,
    voice_leading: @moonsic.KeepInRange,
    allow_rests: false,
    max_leap: 12,
  }
  let result = @moonsic.generate_melody_checked(key, rhythm, config)
  assert_true(result is Ok(_))
  let track = match result {
    Ok(t) => t
    Err(e) => abort(e.to_string())
  }
  assert_eq(track.event_count(), 4)
  for evt in track.events {
    match evt {
      @moonsic.Note(n) => {
        let midi = n.pitch.to_midi()
        let semitone = midi % 12
        let in_c_major = semitone == 0 ||
          semitone == 2 ||
          semitone == 4 ||
          semitone == 5 ||
          semitone == 7 ||
          semitone == 9 ||
          semitone == 11
        assert_true(in_c_major, "pitch not in C major: \{n.pitch.to_string()}")
      }
      _ => abort("expected Note event")
    }
  }
  let beats = track.duration_beats()
  assert_eq(beats, 4.0)
}

///|
/// 错误路径：空节奏模板 -> EmptyRhythmPattern
test "generate_melody_checked_empty_rhythm" {
  let key = @moonsic.key(@moonsic.c(4), @moonsic.Major)
  let rhythm = { units: [], accents: [], allow_rests: false }
  let config = {
    mode: @moonsic.MelodyOnly,
    contour: @moonsic.StepwiseUp,
    range_low: @moonsic.c(4),
    range_high: @moonsic.c(6),
    seed: None,
    voice_leading: @moonsic.KeepInRange,
    allow_rests: false,
    max_leap: 12,
  }
  let result = @moonsic.generate_melody_checked(key, rhythm, config)
  match result {
    Err(@moonsic.EmptyRhythmPattern(_)) => ()
    _ => abort("expected EmptyRhythmPattern")
  }
}

///|
/// 错误路径：音域过小 -> RangeTooSmall
test "generate_melody_checked_range_too_small" {
  let key = @moonsic.key(@moonsic.c(4), @moonsic.Major)
  let rhythm = @moonsic.rhythm_template(@moonsic.FourQuarters)
  let config = {
    mode: @moonsic.MelodyOnly,
    contour: @moonsic.StepwiseUp,
    range_low: @moonsic.c(5),
    range_high: @moonsic.c(4),
    seed: None,
    voice_leading: @moonsic.KeepInRange,
    allow_rests: false,
    max_leap: 12,
  }
  let result = @moonsic.generate_melody_checked(key, rhythm, config)
  match result {
    Err(@moonsic.RangeTooSmall(_)) => ()
    _ => abort("expected RangeTooSmall")
  }
}

///|
/// 和弦进行生成：C major + degrees [1, 5, 6, 4]
/// 预期：4 个和弦事件（I-V-vi-IV）
test "generate_chord_progression_checked_basic" {
  let key = @moonsic.key(@moonsic.c(4), @moonsic.Major)
  let degrees = [1, 5, 6, 4]
  let dur = @moonsic.Duration::Quarter
  let config = {
    mode: @moonsic.ChordsOnly,
    contour: @moonsic.StepwiseUp,
    range_low: @moonsic.c(4),
    range_high: @moonsic.c(6),
    seed: None,
    voice_leading: @moonsic.KeepInRange,
    allow_rests: false,
    max_leap: 12,
  }
  let result = @moonsic.generate_chord_progression_checked(
    key, degrees, dur, config,
  )
  assert_true(result is Ok(_))
  let track = match result {
    Ok(t) => t
    Err(e) => abort(e.to_string())
  }
  assert_eq(track.event_count(), 4)
  for evt in track.events {
    match evt {
      @moonsic.Chord(_) => ()
      _ => abort("expected Chord event")
    }
  }
}

///|
/// 错误路径：非法 degree 0 -> InvalidDegree
test "generate_chord_progression_checked_invalid_degree" {
  let key = @moonsic.key(@moonsic.c(4), @moonsic.Major)
  let degrees = [1, 0, 5]
  let dur = @moonsic.Duration::Quarter
  let config = {
    mode: @moonsic.ChordsOnly,
    contour: @moonsic.StepwiseUp,
    range_low: @moonsic.c(4),
    range_high: @moonsic.c(6),
    seed: None,
    voice_leading: @moonsic.KeepInRange,
    allow_rests: false,
    max_leap: 12,
  }
  let result = @moonsic.generate_chord_progression_checked(
    key, degrees, dur, config,
  )
  match result {
    Err(@moonsic.InvalidDegree(_)) => ()
    _ => abort("expected InvalidDegree")
  }
}

///|
/// 错误路径：空和弦进行 -> EmptyProgression
test "generate_chord_progression_checked_empty" {
  let key = @moonsic.key(@moonsic.c(4), @moonsic.Major)
  let degrees : Array[Int] = []
  let dur = @moonsic.Duration::Quarter
  let config = {
    mode: @moonsic.ChordsOnly,
    contour: @moonsic.StepwiseUp,
    range_low: @moonsic.c(4),
    range_high: @moonsic.c(6),
    seed: None,
    voice_leading: @moonsic.KeepInRange,
    allow_rests: false,
    max_leap: 12,
  }
  let result = @moonsic.generate_chord_progression_checked(
    key, degrees, dur, config,
  )
  match result {
    Err(@moonsic.EmptyProgression(_)) => ()
    _ => abort("expected EmptyProgression")
  }
}

///|
/// 低音生成：I-V-vi-IV + RootBass -> 低音轨含 4 个根音
test "generate_bass_checked_root" {
  let key = @moonsic.key(@moonsic.c(4), @moonsic.Major)
  let config = {
    mode: @moonsic.BassOnly,
    contour: @moonsic.StepwiseUp,
    range_low: @moonsic.c(2),
    range_high: @moonsic.c(4),
    seed: None,
    voice_leading: @moonsic.KeepInRange,
    allow_rests: false,
    max_leap: 12,
  }
  let prog_result = @moonsic.generate_chord_progression_checked(
    key,
    [1, 5, 6, 4],
    @moonsic.Duration::Quarter,
    config,
  )
  let progression = match prog_result {
    Ok(t) => t
    Err(e) => abort(e.to_string())
  }
  let result = @moonsic.generate_bass_checked(
    progression,
    @moonsic.RootBass,
    config,
  )
  assert_true(result is Ok(_))
  let bass = match result {
    Ok(t) => t
    Err(e) => abort(e.to_string())
  }
  assert_eq(bass.event_count(), 4)
}

///|
/// 错误路径：非低音模式 -> GenerationFailed
test "generate_bass_checked_wrong_pattern" {
  let key = @moonsic.key(@moonsic.c(4), @moonsic.Major)
  let config = {
    mode: @moonsic.BassOnly,
    contour: @moonsic.StepwiseUp,
    range_low: @moonsic.c(2),
    range_high: @moonsic.c(4),
    seed: None,
    voice_leading: @moonsic.KeepInRange,
    allow_rests: false,
    max_leap: 12,
  }
  let prog_result = @moonsic.generate_chord_progression_checked(
    key,
    [1, 4, 5, 1],
    @moonsic.Duration::Quarter,
    config,
  )
  let progression = match prog_result {
    Ok(t) => t
    Err(e) => abort(e.to_string())
  }
  let result = @moonsic.generate_bass_checked(
    progression,
    @moonsic.BlockChord,
    config,
  )
  match result {
    Err(@moonsic.GenerationFailed(_)) => ()
    _ => abort("expected GenerationFailed")
  }
}

///|
/// 伴奏生成：BlockChord -> Score 含 1 轨有声部引导的和弦
test "generate_accompaniment_checked_block_chord" {
  let key = @moonsic.key(@moonsic.c(4), @moonsic.Major)
  let config = {
    mode: @moonsic.Accompaniment,
    contour: @moonsic.StepwiseUp,
    range_low: @moonsic.c(4),
    range_high: @moonsic.c(6),
    seed: None,
    voice_leading: @moonsic.KeepInRange,
    allow_rests: false,
    max_leap: 12,
  }
  let prog_result = @moonsic.generate_chord_progression_checked(
    key,
    [1, 6, 4, 5],
    @moonsic.Duration::Quarter,
    config,
  )
  let progression = match prog_result {
    Ok(t) => t
    Err(e) => abort(e.to_string())
  }
  let result = @moonsic.generate_accompaniment_checked(
    progression,
    @moonsic.BlockChord,
    config,
  )
  assert_true(result is Ok(_))
  let score = match result {
    Ok(s) => s
    Err(e) => abort(e.to_string())
  }
  assert_eq(score.track_count(), 1)
}

///|
/// 伴奏生成：Alberti -> Score 含琶音轨（4 和弦 x 4 音 = 16 事件）
test "generate_accompaniment_checked_alberti" {
  let key = @moonsic.key(@moonsic.c(4), @moonsic.Major)
  let config = {
    mode: @moonsic.Accompaniment,
    contour: @moonsic.StepwiseUp,
    range_low: @moonsic.c(4),
    range_high: @moonsic.c(6),
    seed: None,
    voice_leading: @moonsic.KeepInRange,
    allow_rests: false,
    max_leap: 12,
  }
  let prog_result = @moonsic.generate_chord_progression_checked(
    key,
    [1, 4, 5, 1],
    @moonsic.Duration::Quarter,
    config,
  )
  let progression = match prog_result {
    Ok(t) => t
    Err(e) => abort(e.to_string())
  }
  let result = @moonsic.generate_accompaniment_checked(
    progression,
    @moonsic.Alberti,
    config,
  )
  assert_true(result is Ok(_))
  let score = match result {
    Ok(s) => s
    Err(e) => abort(e.to_string())
  }
  assert_eq(score.track_count(), 1)
  let track = score.tracks[0]
  assert_eq(track.event_count(), 16)
}

///|
/// 游戏循环生成：context + 4 bars -> Score 含 2 轨（旋律+和弦）
test "generate_game_loop_checked_basic" {
  let context = {
    key: @moonsic.key(@moonsic.c(4), @moonsic.Major),
    scale: @moonsic.build_scale(@moonsic.C, @moonsic.Major),
    progression: [1, 5, 6, 4],
    time_signature: @moonsic.four_four(),
    tempo: @moonsic.default_tempo(),
    bars: 4,
  }
  let config = {
    mode: @moonsic.GameLoop,
    contour: @moonsic.StepwiseUp,
    range_low: @moonsic.c(4),
    range_high: @moonsic.c(6),
    seed: None,
    voice_leading: @moonsic.KeepInRange,
    allow_rests: false,
    max_leap: 12,
  }
  let result = @moonsic.generate_game_loop_checked(context, 4, config)
  assert_true(result is Ok(_))
  let score = match result {
    Ok(s) => s
    Err(e) => abort(e.to_string())
  }
  assert_eq(score.track_count(), 2)
}

///|
/// 生成短语：MelodyOnly mode -> GeneratedPhrase 含旋律轨和元信息
test "generate_phrase_checked_basic" {
  let context = {
    key: @moonsic.key(@moonsic.c(4), @moonsic.Major),
    scale: @moonsic.build_scale(@moonsic.C, @moonsic.Major),
    progression: [1, 4, 5],
    time_signature: @moonsic.four_four(),
    tempo: @moonsic.default_tempo(),
    bars: 1,
  }
  let config = {
    mode: @moonsic.MelodyOnly,
    contour: @moonsic.Arch,
    range_low: @moonsic.c(4),
    range_high: @moonsic.c(5),
    seed: None,
    voice_leading: @moonsic.KeepInRange,
    allow_rests: false,
    max_leap: 12,
  }
  let result = @moonsic.generate_phrase_checked(context, config)
  assert_true(result is Ok(_))
  let phrase = match result {
    Ok(p) => p
    Err(e) => abort(e.to_string())
  }
  assert_eq(phrase.start_degree, 1)
  assert_eq(phrase.end_degree, 2)
  assert_true(phrase.total_beats > 0.0)
}

///|
/// 便捷 API：generate_melody 返回非空轨道
test "generate_melody_convenience" {
  let key = @moonsic.key(@moonsic.c(4), @moonsic.Major)
  let rhythm = @moonsic.rhythm_template(@moonsic.FourQuarters)
  let track = @moonsic.generate_melody(key, rhythm)
  assert_eq(track.event_count(), 4)
}

///|
/// 便捷 API fallback：非法输入 -> 返回空轨道
test "generate_chord_progression_convenience_fallback" {
  let key = @moonsic.key(@moonsic.c(4), @moonsic.Major)
  let track = @moonsic.generate_chord_progression(
    key,
    [0, 1, 2],
    @moonsic.Duration::Quarter,
  )
  assert_eq(track.event_count(), 0)
}

///|
/// 确定性测试：相同输入 -> 相同输出
test "generate_melody_deterministic" {
  let key = @moonsic.key(@moonsic.c(4), @moonsic.Major)
  let rhythm = @moonsic.rhythm_template(@moonsic.FourQuarters)
  let config = {
    mode: @moonsic.MelodyOnly,
    contour: @moonsic.StepwiseUp,
    range_low: @moonsic.c(4),
    range_high: @moonsic.c(6),
    seed: None,
    voice_leading: @moonsic.KeepInRange,
    allow_rests: false,
    max_leap: 12,
  }
  let r1 = @moonsic.generate_melody_checked(key, rhythm, config)
  let r2 = @moonsic.generate_melody_checked(key, rhythm, config)
  let t1 = match r1 {
    Ok(t) => t
    Err(_) => abort("r1 failed")
  }
  let t2 = match r2 {
    Ok(t) => t
    Err(_) => abort("r2 failed")
  }
  assert_eq(t1.event_count(), t2.event_count())
  for i = 0; i < t1.event_count(); i = i + 1 {
    match (t1.events[i], t2.events[i]) {
      (@moonsic.Note(n1), @moonsic.Note(n2)) =>
        assert_eq(n1.pitch.to_midi(), n2.pitch.to_midi())
      _ => abort("event mismatch")
    }
  }
}

///|
/// FFI 合法 JSON -> ok:true
test "ffi_generate_melody_json_valid" {
  let input = "{\"scale\":\"C major\",\"rhythm_kind\":\"FourQuarters\",\"contour\":\"StepwiseUp\"}"
  let result = @moonsic.ffi_generate_melody_json(input)
  assert_true(result.contains("\"ok\":true"))
  assert_true(result.contains("\"data\""))
}

///|
/// FFI 非法 JSON -> ok:false
test "ffi_generate_melody_json_invalid" {
  let result = @moonsic.ffi_generate_melody_json("not json")
  assert_true(result.contains("\"ok\":false"))
  assert_true(result.contains("\"error\""))

  let result2 = @moonsic.ffi_generate_melody_json("{}")
  assert_true(result2.contains("\"ok\":false"))
}

///|
/// FFI 伴奏生成合法 JSON -> ok:true
test "ffi_generate_accompaniment_json_valid" {
  let input = "{\"scale\":\"C major\",\"degrees\":[1,5,6,4],\"pattern\":\"Alberti\"}"
  let result = @moonsic.ffi_generate_accompaniment_json(input)
  assert_true(result.contains("\"ok\":true"))
  assert_true(result.contains("\"data\""))
}

///|
/// FFI 伴奏非法模式 -> ok:false
test "ffi_generate_accompaniment_json_invalid_pattern" {
  let input = "{\"scale\":\"C major\",\"degrees\":[1,5,6,4],\"pattern\":\"UnknownPattern\"}"
  let result = @moonsic.ffi_generate_accompaniment_json(input)
  assert_true(result.contains("\"ok\":false"))
  assert_true(result.contains("\"error\""))
}

///|
/// GenerateError::to_string 覆盖测试
test "generate_error_to_string" {
  let e1 = @moonsic.InvalidGenerationConfig("test")
  assert_true(e1.to_string().contains("生成配置无效"))

  let e2 = @moonsic.EmptyRhythmPattern("test")
  assert_true(e2.to_string().contains("节奏模板为空"))

  let e3 = @moonsic.EmptyProgression("test")
  assert_true(e3.to_string().contains("和弦进行为空"))

  let e4 = @moonsic.InvalidDegree("test")
  assert_true(e4.to_string().contains("无效音级"))

  let e5 = @moonsic.RangeTooSmall("test")
  assert_true(e5.to_string().contains("音域过小"))
}

// ============================================================
// 节奏模板与动机测试 (rhythm.mbt)
// ============================================================

///|
/// 节奏解析："q q h" → 3 cells，总拍数 4.0
test "rhythm_parse_qqh" {
  let r = @moonsic.parse_rhythm_pattern("q q h")
  assert_true(r is Ok(_))
  let p = r.unwrap()
  assert_eq(p.cells.length(), 3)
  assert_eq(p.total_beats, 4.0)
  assert_eq(p.cells[0].duration, @moonsic.Quarter)
  assert_eq(p.cells[1].duration, @moonsic.Quarter)
  assert_eq(p.cells[2].duration, @moonsic.Half)
}

///|
/// 节奏解析："8 8 q q" → 4 cells
test "rhythm_parse_88qq" {
  let r = @moonsic.parse_rhythm_pattern("8 8 q q")
  assert_true(r is Ok(_))
  let p = r.unwrap()
  assert_eq(p.cells.length(), 4)
  assert_eq(p.cells[0].duration, @moonsic.Eighth)
  assert_eq(p.cells[1].duration, @moonsic.Eighth)
  assert_eq(p.cells[2].duration, @moonsic.Quarter)
  assert_eq(p.cells[3].duration, @moonsic.Quarter)
  assert_eq(p.total_beats, 3.0)
}

///|
/// 节奏解析："R8 q q." → 3 cells，首 cell 为休止，末 cell 附点
test "rhythm_parse_rest_dotted" {
  let r = @moonsic.parse_rhythm_pattern("R8 q q.")
  assert_true(r is Ok(_))
  let p = r.unwrap()
  assert_eq(p.cells.length(), 3)
  assert_true(p.cells[0].is_rest)
  assert_eq(p.cells[0].duration, @moonsic.Eighth)
  assert_eq(p.cells[1].duration, @moonsic.Quarter)
  assert_eq(p.cells[2].duration, @moonsic.Dotted(@moonsic.Quarter))
}

///|
/// 节奏解析：空输入 → Err(MotifParseError)
test "rhythm_parse_empty_err" {
  let r = @moonsic.parse_rhythm_pattern("")
  assert_true(r is Err(_))
  match r {
    Err(@moonsic.MotifParseError(_)) => ()
    _ => abort("expected MotifParseError")
  }
}

///|
/// 内置模板：FourQuarters → 4 个 quarter，total_beats 4.0
test "rhythm_template_fourquarters" {
  let p = @moonsic.rhythm_template(@moonsic.FourQuarters)
  assert_eq(p.cells.length(), 4)
  assert_eq(p.total_beats, 4.0)
  for c in p.cells {
    assert_eq(c.duration, @moonsic.Quarter)
    assert_true(!c.is_rest)
  }
}

///|
/// 内置模板：Waltz → 3 个 quarter，total_beats 3.0
test "rhythm_template_waltz" {
  let p = @moonsic.rhythm_template(@moonsic.Waltz)
  assert_eq(p.cells.length(), 3)
  assert_eq(p.total_beats, 3.0)
}

///|
/// 内置模板：Syncopated → 5 cells
test "rhythm_template_syncopated" {
  let p = @moonsic.rhythm_template(@moonsic.Syncopated)
  assert_eq(p.cells.length(), 5)
  assert_eq(p.cells[0].duration, @moonsic.Eighth)
  assert_eq(p.cells[1].duration, @moonsic.Quarter)
}

///|
/// 动机构建：degrees [1,2,3] + rhythm [q,q,h] → 3 events
test "motif_checked_basic" {
  let cells = [
    {
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
    {
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
    {
      duration: @moonsic.Half,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
  ]
  let r = @moonsic.rhythm_pattern_checked(cells).unwrap()
  let m = @moonsic.motif_checked([1, 2, 3], r)
  assert_true(m is Ok(_))
  let motif = m.unwrap()
  assert_eq(motif.events.length(), 3)
  assert_eq(motif.events[0].degree, 1)
  assert_eq(motif.events[1].degree, 2)
  assert_eq(motif.events[2].degree, 3)
  assert_eq(motif.total_beats, 4.0)
}

///|
/// 动机构建：degree 数量与 rhythm 不匹配 → Err
test "motif_checked_mismatch_err" {
  let cells = [
    {
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
    {
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
  ]
  let r = @moonsic.rhythm_pattern_checked(cells).unwrap()
  let m = @moonsic.motif_checked([1], r)
  assert_true(m is Err(_))
  match m {
    Err(@moonsic.InvalidMotif(_)) => ()
    _ => abort("expected InvalidMotif")
  }
}

///|
/// 变换：Retrograde → degrees [1,2,3] 变为 [3,2,1]，rhythm 同步反转
test "transform_retrograde" {
  let cells = [
    {
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
    {
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
    {
      duration: @moonsic.Half,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
  ]
  let r = @moonsic.rhythm_pattern_checked(cells).unwrap()
  let m = @moonsic.motif_checked([1, 2, 3], r).unwrap()
  let result = @moonsic.transform_motif_checked(m, @moonsic.Retrograde)
  assert_true(result is Ok(_))
  let reversed = result.unwrap()
  assert_eq(reversed.events.length(), 3)
  assert_eq(reversed.events[0].degree, 3)
  assert_eq(reversed.events[1].degree, 2)
  assert_eq(reversed.events[2].degree, 1)
  assert_eq(reversed.events[0].cell.duration, @moonsic.Half)
  assert_eq(reversed.events[1].cell.duration, @moonsic.Quarter)
  assert_eq(reversed.events[2].cell.duration, @moonsic.Quarter)
}

///|
/// 变换：TransposeDegrees(1) → 所有 degree +1
test "transform_transpose_up" {
  let cells = [
    {
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
    {
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
  ]
  let r = @moonsic.rhythm_pattern_checked(cells).unwrap()
  let m = @moonsic.motif_checked([1, 3], r).unwrap()
  let result = @moonsic.transform_motif_checked(m, @moonsic.TransposeDegrees(1))
  assert_true(result is Ok(_))
  let transposed = result.unwrap()
  assert_eq(transposed.events[0].degree, 2)
  assert_eq(transposed.events[1].degree, 4)
}

///|
/// 变换：Repeat(0) → Err(InvalidRepeatCount)
test "transform_repeat_zero_err" {
  let cells = [
    {
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
  ]
  let r = @moonsic.rhythm_pattern_checked(cells).unwrap()
  let m = @moonsic.motif_checked([1], r).unwrap()
  let result = @moonsic.transform_motif_checked(m, @moonsic.Repeat(0))
  assert_true(result is Err(_))
  match result {
    Err(@moonsic.InvalidRepeatCount(_)) => ()
    _ => abort("expected InvalidRepeatCount")
  }
}

///|
/// 小节填充：PadRest → 3.0 拍 + 1 拍休止 → 4.0 拍
test "fit_padrest" {
  let cells = [
    {
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
    {
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
    {
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
  ]
  let r = @moonsic.rhythm_pattern_checked(cells).unwrap()
  let m = @moonsic.motif_checked([1, 2, 3], r).unwrap()
  let pp = @moonsic.repeat_motif_checked(m, 1).unwrap()
  let sig = @moonsic.four_four()
  let result = @moonsic.fit_pattern_to_bars_checked(
    pp,
    sig,
    1,
    @moonsic.PadRest,
  )
  assert_true(result is Ok(_))
  let fitted = result.unwrap()
  assert_eq(fitted.total_beats, 4.0)
  assert_eq(fitted.events.length(), 4)
  assert_true(fitted.events[3].cell.is_rest)
  assert_eq(fitted.events[3].cell.duration.beats(), 1.0)
}

///|
/// 小节填充：Strict 不匹配 → Err(PatternDoesNotFit)
test "fit_strict_err" {
  let cells = [
    {
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
    {
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
    {
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
  ]
  let r = @moonsic.rhythm_pattern_checked(cells).unwrap()
  let m = @moonsic.motif_checked([1, 2, 3], r).unwrap()
  let pp = @moonsic.repeat_motif_checked(m, 1).unwrap()
  let sig = @moonsic.four_four()
  let result = @moonsic.fit_pattern_to_bars_checked(pp, sig, 1, @moonsic.Strict)
  assert_true(result is Err(_))
  match result {
    Err(@moonsic.PatternDoesNotFit(_)) => ()
    _ => abort("expected PatternDoesNotFit")
  }
}

///|
/// 重复动机：count=0 → Err(InvalidRepeatCount)
test "repeat_motif_zero_err" {
  let cells = [
    {
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
  ]
  let r = @moonsic.rhythm_pattern_checked(cells).unwrap()
  let m = @moonsic.motif_checked([1], r).unwrap()
  let result = @moonsic.repeat_motif_checked(m, 0)
  assert_true(result is Err(_))
  match result {
    Err(@moonsic.InvalidRepeatCount(_)) => ()
    _ => abort("expected InvalidRepeatCount")
  }
}

///|
/// 重复动机：count=3 → 3 份原动机
test "repeat_motif_3" {
  let cells = [
    {
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
    {
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
  ]
  let r = @moonsic.rhythm_pattern_checked(cells).unwrap()
  let m = @moonsic.motif_checked([1, 2], r).unwrap()
  let result = @moonsic.repeat_motif_checked(m, 3)
  assert_true(result is Ok(_))
  let pp = result.unwrap()
  assert_eq(pp.events.length(), 6)
  assert_eq(pp.total_beats, 6.0)
}

///|
/// FFI：合法节奏字符串 → ok:true
test "ffi_parse_rhythm_pattern_valid" {
  let result = @moonsic.ffi_parse_rhythm_pattern_json("q q h")
  assert_true(result.contains("\"ok\":true"))
  assert_true(result.contains("\"data\""))
  assert_true(result.contains("total_beats"))
}

///|
/// FFI：空输入 → ok:false
test "ffi_parse_rhythm_pattern_empty_err" {
  let result = @moonsic.ffi_parse_rhythm_pattern_json("")
  assert_true(result.contains("\"ok\":false"))
  assert_true(result.contains("\"error\""))
}

///|
/// FFI 变换：合法 JSON → ok:true
test "ffi_transform_motif_valid" {
  let input = "{\"transform\":\"Retrograde\",\"degrees\":[1,2,3],\"rhythm\":\"q q h\"}"
  let result = @moonsic.ffi_transform_motif_json(input)
  assert_true(result.contains("\"ok\":true"))
}

///|
/// FFI 变换：非法 JSON → ok:false
test "ffi_transform_motif_invalid_json" {
  let result = @moonsic.ffi_transform_motif_json("not json")
  assert_true(result.contains("\"ok\":false"))
  assert_true(result.contains("\"error\""))
}

///|
/// 动机转换 Track：C major degree [1,2,3] → Track 含 C4,D4,E4
test "motif_to_track_basic" {
  let cells = [
    {
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
    {
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
    {
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
  ]
  let r = @moonsic.rhythm_pattern_checked(cells).unwrap()
  let m = @moonsic.motif_checked([1, 2, 3], r).unwrap()
  let key = @moonsic.key(@moonsic.c(4), @moonsic.Major)
  let result = @moonsic.motif_to_track_checked(m, key, 4, @moonsic.Quarter)
  assert_true(result is Ok(_))
  let t = result.unwrap()
  assert_eq(t.events.length(), 3)
  match t.events[0] {
    @moonsic.Note(n) => {
      assert_eq(n.pitch.to_string(), "C4")
      assert_eq(n.duration, @moonsic.Quarter)
    }
    _ => abort("expected Note")
  }
}

///|
/// 动机转换 Track：含休止 → MusicEvent::Rest
test "motif_to_track_with_rest" {
  let cells = [
    {
      duration: @moonsic.Quarter,
      is_rest: true,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
    {
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
  ]
  let r = @moonsic.rhythm_pattern_checked(cells).unwrap()
  let m = @moonsic.motif_checked([0, 1], r).unwrap()
  let key = @moonsic.key(@moonsic.c(4), @moonsic.Major)
  let result = @moonsic.motif_to_track_checked(m, key, 4, @moonsic.Quarter)
  assert_true(result is Ok(_))
  let t = result.unwrap()
  assert_eq(t.events.length(), 2)
  match t.events[0] {
    @moonsic.Rest(_) => ()
    _ => abort("expected Rest")
  }
  match t.events[1] {
    @moonsic.Note(n) => assert_eq(n.pitch.to_string(), "C4")
    _ => abort("expected Note")
  }
}

///|
/// 变奏：RhythmicAugmentation → 所有时值翻倍
test "vary_rhythmic_augmentation" {
  let cells = [
    {
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
    {
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
  ]
  let r = @moonsic.rhythm_pattern_checked(cells).unwrap()
  let m = @moonsic.motif_checked([1, 2], r).unwrap()
  let result = @moonsic.vary_motif_checked(m, @moonsic.RhythmicAugmentation)
  assert_true(result is Ok(_))
  let augmented = result.unwrap()
  assert_eq(augmented.events.length(), 2)
  assert_eq(augmented.events[0].cell.duration, @moonsic.Half)
  assert_eq(augmented.events[1].cell.duration, @moonsic.Half)
}

///|
/// MotifError::to_string 消息测试
test "motif_error_to_string" {
  let e = @moonsic.EmptyRhythmPattern("test")
  let msg = e.to_string()
  assert_true(msg.contains("空节奏模板"))
  assert_true(msg.contains("test"))

  let e2 = @moonsic.InvalidRepeatCount("0")
  let msg2 = e2.to_string()
  assert_true(msg2.contains("无效重复次数"))

  let e3 = @moonsic.PatternDoesNotFit("mismatch")
  let msg3 = e3.to_string()
  assert_true(msg3.contains("模式不适配"))
}

///|
/// 拼接模式：Interleave 交织两个 pattern
test "join_interleave" {
  let cells1 = [
    {
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
  ]
  let cells2 = [
    {
      duration: @moonsic.Eighth,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
  ]
  let r1 = @moonsic.rhythm_pattern_checked(cells1).unwrap()
  let r2 = @moonsic.rhythm_pattern_checked(cells2).unwrap()
  let m1 = @moonsic.motif_checked([1], r1).unwrap()
  let m2 = @moonsic.motif_checked([5], r2).unwrap()
  let pp1 = @moonsic.repeat_motif_checked(m1, 1).unwrap()
  let pp2 = @moonsic.repeat_motif_checked(m2, 1).unwrap()
  let result = @moonsic.join_patterns_checked([pp1, pp2], @moonsic.Interleave)
  assert_true(result is Ok(_))
  let joined = result.unwrap()
  assert_eq(joined.events.length(), 2)
  assert_eq(joined.events[0].degree, 1)
  assert_eq(joined.events[1].degree, 5)
}
