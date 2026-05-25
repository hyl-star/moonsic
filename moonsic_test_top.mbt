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
    include_doctype: true,
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
    include_doctype: true,
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
    include_doctype: true,
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
    include_doctype: false,
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
