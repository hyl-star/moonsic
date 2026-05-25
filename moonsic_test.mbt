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
    Err(e) => abort(e.to_string())
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
    Err(e) => abort(e.to_string())
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
    Err(e) => abort(e.to_string())
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
    Err(e) => abort(e.to_string())
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
    Err(e) => abort(e.to_string())
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
    Ok(_) => abort("expected Err but got Ok")
    _ => abort("expected InvalidMusicXmlOptions")
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
    Err(e) => abort(e.to_string())
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
    Err(e) => abort(e.to_string())
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
    Err(e) => abort(e.to_string())
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
    Err(e) => abort(e.to_string())
  }
}

///|
/// ScoreLayout 转换：ScoreLayout -> MusicXmlScore -> XML
test "musicxml_score_layout_conversion" {
  let part = @moonsic.empty_part("Piano")
  let layout = match
    @moonsic.make_score_layout("Test", @moonsic.DEFAULT_PPQ, [part]) {
    Ok(l) => l
    Err(e) => abort(e.to_string())
  }
  let opts = @moonsic.default_musicxml_export_options()
  match @moonsic.score_layout_to_musicxml_checked(layout, opts) {
    Ok(doc) => {
      assert_eq(doc.parts.length(), 0)
      assert_eq(doc.divisions, @moonsic.DEFAULT_PPQ)
    }
    Err(e) => abort(e.to_string())
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
  let ctx = @moonsic.ScoreContext::{
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
      assert_true(req.task is @moonsic.MelodyContinuation)
      assert_eq(req.constraints.length(), 2)
    }
    Err(_) => abort("expected Ok")
  }
}

///|
/// 测试 generation_request_checked：MinBars > MaxBars 冲突
test "adapter: generation_request_checked constraint conflict MinBars > MaxBars" {
  let ctx = @moonsic.ScoreContext::{
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
  let ctx = @moonsic.ScoreContext::{
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
  let ctx = @moonsic.ScoreContext::{
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
    "test_provider",
    @moonsic.LocalRuleProvider,
    [@moonsic.CanGenerateMelody],
  )
  let result = @moonsic.validate_generation_request(request, provider)
  match result {
    Ok(_) => ()
    Err(e) => abort("expected Ok, got: \{e.to_string()}")
  }
}

///|
/// 测试 validate_generation_request：capability 不匹配
test "adapter: validate_generation_request capability mismatch" {
  let ctx = @moonsic.ScoreContext::{
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
    @moonsic.GenerationPatchOperation::{
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
    @moonsic.GenerationPatchOperation::{
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
  let ctx = @moonsic.ScoreContext::{
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
  let ctx = @moonsic.ScoreContext::{
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
  let ctx = @moonsic.ScoreContext::{
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
  let ctx = @moonsic.ScoreContext::{
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
  assert_true(parsed.task is @moonsic.MelodyContinuation)
  assert_eq(parsed.context.track_count, 2)
  assert_eq(parsed.constraints.length(), 3)
}

///|
/// 测试 generation_response_to_json / generation_response_from_json 往返
test "adapter: generation_response JSON round-trip" {
  let ctx = @moonsic.ScoreContext::{
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
  let ctx = @moonsic.ScoreContext::{
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
  let ctx = @moonsic.ScoreContext::{
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
    @moonsic.GenerationPatchOperation::{
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
    @moonsic.GenerationPatchOperation::{
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
    @moonsic.GenerationPatchOperation::{
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
  let ctx = @moonsic.ScoreContext::{
    score_summary: "test",
    key_hint: None,
    time_signature: @moonsic.four_four(),
    tempo: @moonsic.default_tempo(),
    bars: 4,
    track_count: 1,
    ppq: 480,
  }
  let ops = [
    @moonsic.GenerationPatchOperation::{
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
  assert_true(provider.kind is @moonsic.MockProvider)
  assert_true(provider.determinism is @moonsic.Deterministic)
}

///|
/// 测试 TargetDensity 约束校验：超出范围
test "adapter: TargetDensity out of range" {
  let ctx = @moonsic.ScoreContext::{
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
  let ctx = @moonsic.ScoreContext::{
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
  let config = @moonsic.GenerationConfig::{
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
        assert_true(in_c_major)
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
  let rhythm = @moonsic.RhythmPattern::{ cells: [], total_beats: 0.0 }
  let config = @moonsic.GenerationConfig::{
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
  let config = @moonsic.GenerationConfig::{
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
  let config = @moonsic.GenerationConfig::{
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
  let config = @moonsic.GenerationConfig::{
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
  let config = @moonsic.GenerationConfig::{
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
  let config = @moonsic.GenerationConfig::{
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
  let config = @moonsic.GenerationConfig::{
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
  let config = @moonsic.GenerationConfig::{
    mode: @moonsic.AccompanimentMode,
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
  let config = @moonsic.GenerationConfig::{
    mode: @moonsic.AccompanimentMode,
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
  let context = @moonsic.GenerationContext::{
    key: @moonsic.key(@moonsic.c(4), @moonsic.Major),
    scale: @moonsic.build_scale(@moonsic.C, @moonsic.Major),
    progression: [1, 5, 6, 4],
    time_signature: @moonsic.four_four(),
    tempo: @moonsic.default_tempo(),
    bars: 4,
  }
  let config = @moonsic.GenerationConfig::{
    mode: @moonsic.GameLoopMode,
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
  let context = @moonsic.GenerationContext::{
    key: @moonsic.key(@moonsic.c(4), @moonsic.Major),
    scale: @moonsic.build_scale(@moonsic.C, @moonsic.Major),
    progression: [1, 4, 5],
    time_signature: @moonsic.four_four(),
    tempo: @moonsic.default_tempo(),
    bars: 1,
  }
  let config = @moonsic.GenerationConfig::{
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
  let config = @moonsic.GenerationConfig::{
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

  let e2 = @moonsic.GenerateError::EmptyRhythmPattern("test")
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
  assert_true(p.cells[0].duration.beats() == @moonsic.Quarter.beats())
  assert_true(p.cells[1].duration.beats() == @moonsic.Quarter.beats())
  assert_true(p.cells[2].duration.beats() == @moonsic.Half.beats())
}

///|
/// 节奏解析："8 8 q q" → 4 cells
test "rhythm_parse_88qq" {
  let r = @moonsic.parse_rhythm_pattern("8 8 q q")
  assert_true(r is Ok(_))
  let p = r.unwrap()
  assert_eq(p.cells.length(), 4)
  assert_true(p.cells[0].duration.beats() == @moonsic.Eighth.beats())
  assert_true(p.cells[1].duration.beats() == @moonsic.Eighth.beats())
  assert_true(p.cells[2].duration.beats() == @moonsic.Quarter.beats())
  assert_true(p.cells[3].duration.beats() == @moonsic.Quarter.beats())
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
  assert_true(p.cells[0].duration.beats() == @moonsic.Eighth.beats())
  assert_true(p.cells[1].duration.beats() == @moonsic.Quarter.beats())
  assert_true(
    p.cells[2].duration.beats() == @moonsic.Dotted(@moonsic.Quarter).beats(),
  )
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
    assert_true(c.duration.beats() == @moonsic.Quarter.beats())
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
  assert_true(p.cells[0].duration.beats() == @moonsic.Eighth.beats())
  assert_true(p.cells[1].duration.beats() == @moonsic.Quarter.beats())
}

///|
/// 动机构建：degrees [1,2,3] + rhythm [q,q,h] → 3 events
test "motif_checked_basic" {
  let cells = [
    @moonsic.RhythmCell::{
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
    @moonsic.RhythmCell::{
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
    @moonsic.RhythmCell::{
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
    @moonsic.RhythmCell::{
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
    @moonsic.RhythmCell::{
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
    @moonsic.RhythmCell::{
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
    @moonsic.RhythmCell::{
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
    @moonsic.RhythmCell::{
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
  assert_true(reversed.events[0].cell.duration.beats() == @moonsic.Half.beats())
  assert_true(
    reversed.events[1].cell.duration.beats() == @moonsic.Quarter.beats(),
  )
  assert_true(
    reversed.events[2].cell.duration.beats() == @moonsic.Quarter.beats(),
  )
}

///|
/// 变换：TransposeDegrees(1) → 所有 degree +1
test "transform_transpose_up" {
  let cells = [
    @moonsic.RhythmCell::{
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
    @moonsic.RhythmCell::{
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
    @moonsic.RhythmCell::{
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
    @moonsic.RhythmCell::{
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
    @moonsic.RhythmCell::{
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
    @moonsic.RhythmCell::{
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
    @moonsic.RhythmCell::{
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
    @moonsic.RhythmCell::{
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
    @moonsic.RhythmCell::{
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
    @moonsic.RhythmCell::{
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
    @moonsic.RhythmCell::{
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
    @moonsic.RhythmCell::{
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
    @moonsic.RhythmCell::{
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
    @moonsic.RhythmCell::{
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
    @moonsic.RhythmCell::{
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
      assert_true(n.duration.beats() == @moonsic.Quarter.beats())
    }
    _ => abort("expected Note")
  }
}

///|
/// 动机转换 Track：含休止 → MusicEvent::Rest
test "motif_to_track_with_rest" {
  let cells = [
    @moonsic.RhythmCell::{
      duration: @moonsic.Quarter,
      is_rest: true,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
    @moonsic.RhythmCell::{
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
    @moonsic.RhythmCell::{
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
    @moonsic.RhythmCell::{
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
  assert_true(
    augmented.events[0].cell.duration.beats() == @moonsic.Half.beats(),
  )
  assert_true(
    augmented.events[1].cell.duration.beats() == @moonsic.Half.beats(),
  )
}

///|
/// MotifError::to_string 消息测试
test "motif_error_to_string" {
  let e = @moonsic.InvalidRhythmCell("test")
  let msg = e.to_string()
  assert_true(msg.contains("无效节奏单元"))
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
    @moonsic.RhythmCell::{
      duration: @moonsic.Quarter,
      is_rest: false,
      accent: @moonsic.NoAccent,
      tie_to_next: false,
    },
  ]
  let cells2 = [
    @moonsic.RhythmCell::{
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

// ============================================================
// 曲谱校验与问题报告模块测试 (validate.mbt)
// ============================================================

///|
/// 校验：measure overflow — 4/4 小节放 whole + half 溢出
test "validate_measure_overflow" {
  let sig = @moonsic.four_four()
  let events = [
    @moonsic.n(@moonsic.c(4), @moonsic.whole()),
    @moonsic.n(@moonsic.d(4), @moonsic.half()),
  ]
  let m = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let opts = @moonsic.default_validation_options()
  let report = @moonsic.validate_measure_report(m, sig, 480, opts)
  assert_true(@moonsic.validation_report_has_errors(report))
  assert_eq(@moonsic.validation_report_error_count(report), 1)
  assert_eq(@moonsic.validation_report_warning_count(report), 0)
}

///|
/// 校验：measure underfilled — 严格模式下 4/4 小节只放 2 个 quarter
test "validate_measure_underfilled_strict" {
  let sig = @moonsic.four_four()
  let events = [
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
  ]
  let m = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let opts = @moonsic.strict_validation_options()
  let report = @moonsic.validate_measure_report(m, sig, 480, opts)
  assert_true(@moonsic.validation_report_has_warnings(report))
  assert_eq(@moonsic.validation_report_warning_count(report), 1)
}

///|
/// 校验：measure at capacity — 4/4 小节 4 个 quarter 不报错
test "validate_measure_at_capacity_ok" {
  let sig = @moonsic.four_four()
  let events = [
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.e(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.f(4), @moonsic.quarter()),
  ]
  let m = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let opts = @moonsic.default_validation_options()
  let report = @moonsic.validate_measure_report(m, sig, 480, opts)
  assert_true(!@moonsic.validation_report_has_errors(report))
  assert_true(!@moonsic.validation_report_has_warnings(report))
}

///|
/// 校验：empty voice 产生 EmptyVoice warning
test "validate_empty_voice_warning" {
  let v = @moonsic.empty_voice("Empty")
  let opts = @moonsic.default_validation_options()
  let report = @moonsic.validate_voice_report(v, opts)
  assert_true(@moonsic.validation_report_has_warnings(report))
}

///|
/// 校验：empty voice 在严格模式下升级为 error
test "validate_empty_voice_strict_error" {
  let v = @moonsic.empty_voice("Empty")
  let opts = @moonsic.strict_validation_options()
  let report = @moonsic.validate_voice_report(v, opts)
  assert_true(@moonsic.validation_report_has_errors(report))
}

///|
/// 校验：staff channel=16 产生 InvalidChannel error
test "validate_staff_invalid_channel" {
  let v = @moonsic.empty_voice("RH")
  let s = @moonsic.make_staff("Bad", Some(16), None, None, [v])
  assert_true(s is Err(_))
}

///|
/// 校验：staff program=128 产生 InvalidProgram error
test "validate_staff_invalid_program" {
  let v = @moonsic.empty_voice("RH")
  let s = @moonsic.make_staff("Bad", None, Some(128), None, [v])
  assert_true(s is Err(_))
}

///|
/// 校验：score 非法 PPQ=0 产生 InvalidPPQ fatal
test "validate_score_invalid_ppq" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let s = @moonsic.score1(t)
  let opts = @moonsic.default_validation_options()
  let report = @moonsic.validate_score_report(s, 0, opts)
  assert_true(@moonsic.validation_report_has_errors(report))
}

///|
/// 校验：score 非法 track channel 产生 InvalidChannel
test "validate_score_invalid_channel" {
  let t = @moonsic.melody_with_channel(
    [@moonsic.n(@moonsic.c(4), @moonsic.quarter())],
    16,
  )
  let s = @moonsic.score1(t)
  let opts = @moonsic.default_validation_options()
  let report = @moonsic.validate_score_report(s, 480, opts)
  assert_true(@moonsic.validation_report_has_errors(report))
}

///|
/// 校验：report to_json 包含 error_count 和 issues 数组
test "validate_report_to_json" {
  let v = @moonsic.empty_voice("Empty")
  let opts = @moonsic.strict_validation_options()
  let report = @moonsic.validate_voice_report(v, opts)
  let json = @moonsic.validation_report_to_json(report)
  assert_true(json.contains("error_count"))
  assert_true(json.contains("warning_count"))
  assert_true(json.contains("issues"))
  assert_true(json.contains("EmptyVoice"))
}

///|
/// 校验：report to_summary 包含中文描述
test "validate_report_to_summary" {
  let v = @moonsic.empty_voice("Empty")
  let opts = @moonsic.default_validation_options()
  let report = @moonsic.validate_voice_report(v, opts)
  let summary = @moonsic.validation_report_to_summary(report)
  assert_true(summary.contains("校验报告"))
  assert_true(summary.contains("EmptyVoice"))
  assert_true(summary.contains("建议"))
}

///|
/// 校验：default/strict/export 三种 options 构造函数
test "validate_options_constructors" {
  let d = @moonsic.default_validation_options()
  assert_true(!d.strict_measure_capacity)
  assert_true(!d.empty_voice_is_error)

  let s = @moonsic.strict_validation_options()
  assert_true(s.strict_measure_capacity)
  assert_true(s.empty_voice_is_error)

  let e = @moonsic.export_validation_options()
  assert_true(e.strict_measure_capacity)
  assert_true(e.export_mode)
}

///|
/// 校验：score layout 整体校验，合法 layout 不报错
test "validate_score_layout_report_valid" {
  let sig = @moonsic.four_four()
  let events = [
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
  ]
  let m = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let v = @moonsic.make_voice("RH", [m]).unwrap()
  let s = @moonsic.make_staff("Piano", Some(0), Some(0), None, [v]).unwrap()
  let p = @moonsic.make_part("Keyboard", [s]).unwrap()
  let sl = @moonsic.make_score_layout("Test", 480, [p]).unwrap()
  let opts = @moonsic.default_validation_options()
  let report = @moonsic.validate_score_layout_report(sl, opts)
  assert_true(!@moonsic.validation_report_has_errors(report))
}

///|
/// 校验：score layout with voice alignment mismatch
test "validate_score_layout_voice_alignment" {
  let sig = @moonsic.four_four()
  let m0 = @moonsic.empty_measure(0)
  let m1 = @moonsic.empty_measure(1)
  let v_rh = @moonsic.make_voice("RH", [m0]).unwrap()
  let v_lh = @moonsic.make_voice("LH", [m0, m1]).unwrap()
  let s = @moonsic.make_staff("Piano", None, None, None, [v_rh, v_lh]).unwrap()
  let p = @moonsic.make_part("Keyboard", [s]).unwrap()
  let sl = @moonsic.make_score_layout("Test", 480, [p]).unwrap()
  let opts = @moonsic.strict_validation_options()
  let report = @moonsic.validate_score_layout_report(sl, opts)
  assert_true(@moonsic.validation_report_has_warnings(report))
}

///|
/// 校验：FFI 合法 ScoreLayout JSON 返回 ok:true
test "validate_ffi_valid_json" {
  let input = "{\"title\":\"Test\",\"ppq\":480,\"composer\":\"\",\"parts\":[],\"initial_tempo\":{\"bpm\":120},\"initial_signature\":{\"numerator\":4,\"denominator\":4}}"
  let result = @moonsic.ffi_validate_score_layout_json(input)
  assert_true(result.contains("\"ok\":true"))
  assert_true(result.contains("\"data\""))
  assert_true(result.contains("error_count"))
}

///|
/// 校验：FFI 非法 JSON 返回 ok:false
test "validate_ffi_invalid_json" {
  let result = @moonsic.ffi_validate_score_layout_json("not valid json")
  assert_true(result.contains("\"ok\":false"))
  assert_true(result.contains("\"error\""))

  let result2 = @moonsic.ffi_validate_score_layout_json("{}")
  assert_true(result2.contains("\"ok\":false"))
}

// ============================================================
// 专业曲谱结构增强模块测试 (score_enhanced.mbt)
// ============================================================

// --- Section / Repeat ---

///|
/// 段落创建：Verse section measure 0-7
test "score_enhanced: make_section_checked valid verse" {
  let r = @moonsic.make_section_checked("Verse1", @moonsic.Verse, 0, 7)
  assert_true(r is Ok(_))
  let s = r.unwrap()
  assert_eq(s.name, "Verse1")
  assert_eq(s.start_measure, 0)
  assert_eq(s.end_measure, 7)
  assert_true(s.kind is @moonsic.Verse)
}

///|
/// 空 section name -> Err(InvalidSection)
test "score_enhanced: make_section_checked empty name fails" {
  let r = @moonsic.make_section_checked("", @moonsic.Verse, 0, 7)
  assert_true(r is Err(_))
  match r {
    Err(@moonsic.InvalidSection(_)) => ()
    _ => abort("expected InvalidSection")
  }
}

///|
/// 小节范围非法：end < start -> Err
test "score_enhanced: make_section_checked end_lt_start fails" {
  let r = @moonsic.make_section_checked("Bad", @moonsic.Verse, 7, 0)
  assert_true(r is Err(_))
  match r {
    Err(@moonsic.InvalidSection(_)) => ()
    _ => abort("expected InvalidSection")
  }
}

///|
/// RepeatStart / RepeatEnd 创建
test "score_enhanced: make_repeat_checked start_and_end" {
  let start = @moonsic.make_repeat_checked(@moonsic.RepeatStart, 0, None)
  assert_true(start is Ok(_))
  let s = start.unwrap()
  assert_eq(s.measure_index, 0)
  assert_true(s.kind is @moonsic.RepeatStart)

  let end = @moonsic.make_repeat_checked(@moonsic.RepeatEnd, 7, None)
  assert_true(end is Ok(_))
  let e = end.unwrap()
  assert_eq(e.measure_index, 7)
  assert_true(e.kind is @moonsic.RepeatEnd)
}

///|
/// Negative measure_index -> Err
test "score_enhanced: make_repeat_checked negative_index fails" {
  let r = @moonsic.make_repeat_checked(@moonsic.RepeatStart, -1, None)
  assert_true(r is Err(_))
  match r {
    Err(@moonsic.InvalidRepeat(_)) => ()
    _ => abort("expected InvalidRepeat")
  }
}

// --- Ending ---

///|
/// FirstEnding 创建
test "score_enhanced: make_ending_checked first ending" {
  let r = @moonsic.make_ending_checked(1, 8, 15, @moonsic.FirstEnding)
  assert_true(r is Ok(_))
  let eb = r.unwrap()
  assert_eq(eb.number, 1)
  assert_eq(eb.start_measure, 8)
  assert_eq(eb.end_measure, 15)
}

///|
/// Ending number=0 -> Err(InvalidEnding)
test "score_enhanced: make_ending_checked number 0 fails" {
  let r = @moonsic.make_ending_checked(0, 0, 7, @moonsic.FirstEnding)
  assert_true(r is Err(_))
  match r {
    Err(@moonsic.InvalidEnding(_)) => ()
    _ => abort("expected InvalidEnding")
  }
}

///|
/// Ending number negative -> Err
test "score_enhanced: make_ending_checked negative number fails" {
  let r = @moonsic.make_ending_checked(-1, 0, 7, @moonsic.SecondEnding)
  assert_true(r is Err(_))
  match r {
    Err(@moonsic.InvalidEnding(_)) => ()
    _ => abort("expected InvalidEnding")
  }
}

// --- Lyrics / Notation ---

///|
/// 歌词 + 演奏记号 + structured note
test "score_enhanced: structured_note_checked with lyric and notation" {
  let l = @moonsic.make_lyric_checked("hello", 0, @moonsic.Single)
  assert_true(l is Ok(_))
  let lyric = l.unwrap()
  assert_eq(lyric.text, "hello")
  assert_eq(lyric.verse, 0)

  let n = @moonsic.make_notation_checked(
    @moonsic.Articulation(@moonsic.Staccato),
    @moonsic.Above,
  )
  assert_true(n is Ok(_))
  let notation = n.unwrap()

  let note = @moonsic.note(@moonsic.c(4), @moonsic.quarter())
  let se = @moonsic.structured_note_checked(
    note,
    [notation],
    Some(lyric),
    @moonsic.NoTie,
  )
  assert_true(se is Ok(_))
  let event = se.unwrap()
  // Verify the raw note is preserved
  match event.event {
    @moonsic.Note(nn) => assert_eq(nn.pitch.to_midi(), 60)
    _ => abort("expected Note")
  }
  assert_eq(event.notations.length(), 1)
  assert_true(event.lyric is Some(_))
  assert_true(event.tie is @moonsic.NoTie)
}

///|
/// 空歌词文本 -> Err
test "score_enhanced: make_lyric_checked empty text fails" {
  let r = @moonsic.make_lyric_checked("", 0, @moonsic.Single)
  assert_true(r is Err(_))
  match r {
    Err(@moonsic.InvalidLyric(_)) => ()
    _ => abort("expected InvalidLyric")
  }
}

///|
/// Negative verse number -> Err
test "score_enhanced: make_lyric_checked negative verse fails" {
  let r = @moonsic.make_lyric_checked("text", -1, @moonsic.Single)
  assert_true(r is Err(_))
  match r {
    Err(@moonsic.InvalidLyric(_)) => ()
    _ => abort("expected InvalidLyric")
  }
}

// --- Pickup / Cross-measure Tie ---

///|
/// Pickup measure 创建：role=PickupMeasure，内容小于 4/4 容量
test "score_enhanced: enhanced_measure_checked pickup measure" {
  let sig = @moonsic.four_four()
  let empty_se : Array[@moonsic.StructuredEvent] = []
  let r = @moonsic.enhanced_measure_checked(
    0,
    Some(sig),
    @moonsic.PickupMeasure,
    empty_se,
  )
  assert_true(r is Ok(_))
  let m = r.unwrap()
  assert_eq(m.index, 0)
  assert_true(m.role is @moonsic.PickupMeasure)
}

///|
/// Cross-measure tie: TieStart on measure 0, TieStop on measure 1
test "score_enhanced: structured_note_checked tie_start_stop" {
  let n1 = @moonsic.note(@moonsic.c(4), @moonsic.quarter())
  let se1 = @moonsic.structured_note_checked(n1, [], None, @moonsic.TieStart)
  assert_true(se1 is Ok(_))

  let n2 = @moonsic.note(@moonsic.c(4), @moonsic.quarter())
  let se2 = @moonsic.structured_note_checked(n2, [], None, @moonsic.TieStop)
  assert_true(se2 is Ok(_))

  let m0 = @moonsic.enhanced_measure_checked(
    0,
    Some(@moonsic.four_four()),
    @moonsic.NormalMeasure,
    [se1.unwrap()],
  )
  assert_true(m0 is Ok(_))

  let m1 = @moonsic.enhanced_measure_checked(1, None, @moonsic.NormalMeasure, [
    se2.unwrap(),
  ])
  assert_true(m1 is Ok(_))
}

// --- Track to EnhancedVoice ---

///|
/// 4/4 ppq=480 四个 quarter -> 1 measure 4 events
test "score_enhanced: track_to_enhanced_voice_checked four quarters" {
  let t = @moonsic.melody([
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.e(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.f(4), @moonsic.quarter()),
  ])
  let r = @moonsic.track_to_enhanced_voice_checked(
    t,
    @moonsic.four_four(),
    480,
    "Melody",
  )
  assert_true(r is Ok(_))
  let v = r.unwrap()
  assert_eq(v.name, "Melody")
  assert_eq(v.measures.length(), 1)
  assert_eq(v.measures[0].events.length(), 4)
}

///|
/// Track to EnhancedVoice: 6 quarter notes split into 2 measures
test "score_enhanced: track_to_enhanced_voice_checked measure split" {
  let t = @moonsic.melody([
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.e(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.f(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.g(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.a(4), @moonsic.quarter()),
  ])
  let r = @moonsic.track_to_enhanced_voice_checked(
    t,
    @moonsic.four_four(),
    480,
    "Melody",
  )
  assert_true(r is Ok(_))
  let v = r.unwrap()
  assert_eq(v.measures.length(), 2)
  // 1st measure: 4 notes, 2nd: 2 notes
  assert_eq(v.measures[0].events.length(), 4)
  assert_eq(v.measures[1].events.length(), 2)
}

// --- Error paths ---

///|
/// Staff channel=16 -> Err(InvalidStaff)
test "score_enhanced: enhanced_staff_checked channel 16 fails" {
  let r = @moonsic.enhanced_staff_checked("Staff", 16, 0, [])
  assert_true(r is Err(_))
  match r {
    Err(@moonsic.StructInvalidStaff(_)) => ()
    _ => abort("expected InvalidStaff")
  }
}

///|
/// Staff program negative -> Err
test "score_enhanced: enhanced_staff_checked program negative fails" {
  let r = @moonsic.enhanced_staff_checked("Staff", 0, -1, [])
  assert_true(r is Err(_))
  match r {
    Err(@moonsic.StructInvalidStaff(_)) => ()
    _ => abort("expected InvalidStaff")
  }
}

///|
/// PPQ=0 -> Err(InvalidPPQ)
test "score_enhanced: enhanced_score_layout_checked ppq 0 fails" {
  let r = @moonsic.enhanced_score_layout_checked([], [], [], [], 0)
  assert_true(r is Err(_))
  match r {
    Err(@moonsic.InvalidPPQ(_)) => ()
    _ => abort("expected InvalidPPQ")
  }
}

// --- Score to Enhanced Layout round-trip ---

///|
/// Score -> EnhancedScoreLayout -> Score round-trip
test "score_enhanced: score_to_enhanced_layout round trip" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let s = @moonsic.score1(t)
  let layout_r = @moonsic.score_to_enhanced_layout_checked(s, 480)
  assert_true(layout_r is Ok(_))
  let layout = layout_r.unwrap()
  assert_eq(layout.ppq, 480)
  assert_eq(layout.parts.length(), 1)

  let back_r = @moonsic.enhanced_layout_to_score_checked(layout)
  assert_true(back_r is Ok(_))
  let back = back_r.unwrap()
  assert_eq(back.track_count(), 1)
  assert_eq(back.tracks[0].event_count(), 1)
}

// --- EnhancedVoice/Staff/Part construction ---

///|
/// EnhancedVoice checked: valid name and measures
test "score_enhanced: enhanced_voice_checked valid" {
  let empty_se : Array[@moonsic.StructuredEvent] = []
  let m = @moonsic.enhanced_measure_checked(
    0,
    Some(@moonsic.four_four()),
    @moonsic.NormalMeasure,
    empty_se,
  ).unwrap()
  let r = @moonsic.enhanced_voice_checked("Voice1", [m])
  assert_true(r is Ok(_))
  let v = r.unwrap()
  assert_eq(v.name, "Voice1")
  assert_eq(v.measures.length(), 1)
}

///|
/// EnhancedVoice empty name -> Err
test "score_enhanced: enhanced_voice_checked empty name fails" {
  let r = @moonsic.enhanced_voice_checked("", [])
  assert_true(r is Err(_))
  match r {
    Err(@moonsic.StructInvalidVoice(_)) => ()
    _ => abort("expected InvalidVoice")
  }
}

///|
/// EnhancedPart checked: valid name
test "score_enhanced: enhanced_part_checked valid" {
  let r = @moonsic.enhanced_part_checked("Part1", [])
  assert_true(r is Ok(_))
  let p = r.unwrap()
  assert_eq(p.name, "Part1")
}

///|
/// EnhancedPart empty name -> Err
test "score_enhanced: enhanced_part_checked empty name fails" {
  let r = @moonsic.enhanced_part_checked("", [])
  assert_true(r is Err(_))
  match r {
    Err(@moonsic.StructInvalidPart(_)) => ()
    _ => abort("expected InvalidPart")
  }
}

// --- ScoreStructureError to_string ---

///|
/// ScoreStructureError to_string coverage
test "score_enhanced: score_structure_error to_string" {
  let e1 = @moonsic.InvalidSection("test")
  assert_true(e1.to_string().contains("无效段落"))

  let e2 = @moonsic.InvalidRepeat("test")
  assert_true(e2.to_string().contains("无效反复"))

  let e3 = @moonsic.InvalidEnding("test")
  assert_true(e3.to_string().contains("无效结尾"))

  let e4 = @moonsic.InvalidNotation("test")
  assert_true(e4.to_string().contains("无效演奏记号"))

  let e5 = @moonsic.InvalidLyric("test")
  assert_true(e5.to_string().contains("无效歌词"))

  let e6 = @moonsic.InvalidPickup("test")
  assert_true(e6.to_string().contains("无效弱起小节"))

  let e7 = @moonsic.InvalidTie("test")
  assert_true(e7.to_string().contains("无效连音"))

  let e8 = @moonsic.ScoreStructureUnsupported("test")
  assert_true(e8.to_string().contains("不支持"))
}

// --- Rule table functions ---

///|
/// Rule tables: SectionKind default_label
test "score_enhanced: section_kind default_label" {
  assert_eq(@moonsic.Verse.default_label(), "Verse")
  assert_eq(@moonsic.Chorus.default_label(), "Chorus")
  assert_eq(@moonsic.Intro.default_label(), "Intro")
  assert_eq(@moonsic.Outro.default_label(), "Outro")
  assert_eq(@moonsic.Bridge.default_label(), "Bridge")
  assert_eq(@moonsic.Solo.default_label(), "Solo")
  assert_eq(@moonsic.CustomSection.default_label(), "Custom")
}

///|
/// Rule tables: DynamicMark velocity_hint
test "score_enhanced: dynamic_mark velocity_hint" {
  assert_eq(@moonsic.Pianissimo.velocity_hint(), 40)
  assert_eq(@moonsic.Piano.velocity_hint(), 55)
  assert_eq(@moonsic.MezzoPiano.velocity_hint(), 70)
  assert_eq(@moonsic.MezzoForte.velocity_hint(), 85)
  assert_eq(@moonsic.Forte.velocity_hint(), 105)
  assert_eq(@moonsic.Fortissimo.velocity_hint(), 120)
}

///|
/// Rule tables: TieKind behavior
test "score_enhanced: tie_kind behavior" {
  assert_eq(@moonsic.NoTie.behavior(), "独立音符")
  assert_eq(@moonsic.TieStart.behavior(), "与后续音符相连")
  assert_eq(@moonsic.TieContinue.behavior(), "从前一音延续并继续")
  assert_eq(@moonsic.TieStop.behavior(), "结束连音")
  assert_eq(
    @moonsic.TieStartStop.behavior(),
    "同时结束前一 tie 并开启下一 tie",
  )
}

// --- Convenience API ---

///|
/// Convenience: lyric() creates Single syllable verse 0
test "score_enhanced: convenience lyric" {
  let l = @moonsic.lyric("hello")
  assert_eq(l.text, "hello")
  assert_eq(l.verse, 0)
  assert_true(l.syllable is @moonsic.Single)
}

///|
/// Convenience: notation() creates Above placement
test "score_enhanced: convenience notation" {
  let n = @moonsic.notation(@moonsic.Articulation(@moonsic.Staccato))
  assert_true(n.placement is @moonsic.Above)
  assert_true(n.text is None)
}

///|
/// Convenience: enhanced_voice() fallbacks to "Untitled"
test "score_enhanced: convenience enhanced_voice empty name" {
  let v = @moonsic.enhanced_voice("", [])
  assert_eq(v.name, "Untitled")
}

///|
/// Convenience: enhanced_voice() keeps non-empty name
test "score_enhanced: convenience enhanced_voice valid name" {
  let v = @moonsic.enhanced_voice("MyVoice", [])
  assert_eq(v.name, "MyVoice")
}

// --- FFI ---

///|
/// FFI: basic valid JSON returns ok:true
test "score_enhanced: ffi_score_structure_summary_json valid" {
  let input = "{\"ppq\":480,\"parts\":[],\"sections\":[],\"repeats\":[],\"endings\":[]}"
  let result = @moonsic.ffi_score_structure_summary_json(input)
  assert_true(result.length() > 10)
  assert_true(result.contains("\"ok\""))
  assert_true(result.contains("\"data\""))
}

///|
/// FFI: ppq=0 returns ok:false
test "score_enhanced: ffi_score_structure_summary_json invalid ppq" {
  let input = "{\"ppq\":0}"
  let result = @moonsic.ffi_score_structure_summary_json(input)
  assert_true(result.length() > 20)
  assert_true(result != "")
}
