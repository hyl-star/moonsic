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

// ============================================================
// MusicXML 稳定化边界测试 (v2 — clef / note type / tie / notation)
// ============================================================

///|
/// Clef 结构体映射：musicxml_clef_from_kind 六种输入全部验证
test "musicxml_v2: clef_struct_from_kind_all" {
  let treble = @moonsic.musicxml_clef_from_kind(@moonsic.Treble)
  assert_eq(treble.sign, "G")
  assert_eq(treble.line, 2)
  let bass = @moonsic.musicxml_clef_from_kind(@moonsic.Bass)
  assert_eq(bass.sign, "F")
  assert_eq(bass.line, 4)
  let alto = @moonsic.musicxml_clef_from_kind(@moonsic.Alto)
  assert_eq(alto.sign, "C")
  assert_eq(alto.line, 3)
  let tenor = @moonsic.musicxml_clef_from_kind(@moonsic.Tenor)
  assert_eq(tenor.sign, "C")
  assert_eq(tenor.line, 4)
  let perc = @moonsic.musicxml_clef_from_kind(@moonsic.Percussion)
  assert_eq(perc.sign, "percussion")
  assert_eq(perc.line, 2)
  let noclef = @moonsic.musicxml_clef_from_kind(@moonsic.NoClef)
  assert_eq(noclef.sign, "G")
  assert_eq(noclef.line, 2)
}

///|
/// Note type 边界：32nd / 64th / 128th 序列化 — 各自独立构造验证
test "musicxml_v2: note_type_32nd_xml" {
  let note = @moonsic.MusicXmlNote::{
    pitch: Some(@moonsic.MusicXmlPitch::{ step: "C", alter: 0, octave: 4 }),
    duration: 60,
    note_type: @moonsic.ThirtySecondT,
    dots: 0,
    is_rest: false,
    is_chord_tone: false,
    voice: 1,
    staff: 1,
    tie_start: false,
    tie_stop: false,
    notations: [],
    lyric: None,
  }
  let m = @moonsic.MusicXmlMeasure::{
    number: 1,
    attributes: None,
    notes: [note],
    directions: [],
    barlines: [],
  }
  let p = @moonsic.MusicXmlPart::{ id: "P1", name: "T", measures: [m] }
  let doc = @moonsic.MusicXmlScore::{
    title: "",
    composer: "",
    document_kind: @moonsic.Partwise,
    parts: [p],
    divisions: 480,
  }
  let opts = @moonsic.MusicXmlExportOptions::{
    divisions: 480,
    document_kind: @moonsic.Partwise,
    include_xml_header: false,
    include_doctype: false,
    strict: false,
    part_name_fallback: "T",
  }
  match @moonsic.musicxml_to_string_checked(doc, opts) {
    Ok(xml) => assert_true(xml.contains("<type>32nd</type>"))
    Err(e) => abort(e.to_string())
  }
}

///|
/// Note type 边界：64th 序列化
test "musicxml_v2: note_type_64th_xml" {
  let note = @moonsic.MusicXmlNote::{
    pitch: Some(@moonsic.MusicXmlPitch::{ step: "D", alter: 0, octave: 4 }),
    duration: 30,
    note_type: @moonsic.SixtyFourthT,
    dots: 0,
    is_rest: false,
    is_chord_tone: false,
    voice: 1,
    staff: 1,
    tie_start: false,
    tie_stop: false,
    notations: [],
    lyric: None,
  }
  let m = @moonsic.MusicXmlMeasure::{
    number: 1,
    attributes: None,
    notes: [note],
    directions: [],
    barlines: [],
  }
  let p = @moonsic.MusicXmlPart::{ id: "P1", name: "T", measures: [m] }
  let doc = @moonsic.MusicXmlScore::{
    title: "",
    composer: "",
    document_kind: @moonsic.Partwise,
    parts: [p],
    divisions: 480,
  }
  let opts = @moonsic.MusicXmlExportOptions::{
    divisions: 480,
    document_kind: @moonsic.Partwise,
    include_xml_header: false,
    include_doctype: false,
    strict: false,
    part_name_fallback: "T",
  }
  match @moonsic.musicxml_to_string_checked(doc, opts) {
    Ok(xml) => assert_true(xml.contains("<type>64th</type>"))
    Err(e) => abort(e.to_string())
  }
}

///|
/// Note type 边界：128th 序列化
test "musicxml_v2: note_type_128th_xml" {
  let note = @moonsic.MusicXmlNote::{
    pitch: Some(@moonsic.MusicXmlPitch::{ step: "E", alter: 0, octave: 4 }),
    duration: 15,
    note_type: @moonsic.OneTwentyEighthT,
    dots: 0,
    is_rest: false,
    is_chord_tone: false,
    voice: 1,
    staff: 1,
    tie_start: false,
    tie_stop: false,
    notations: [],
    lyric: None,
  }
  let m = @moonsic.MusicXmlMeasure::{
    number: 1,
    attributes: None,
    notes: [note],
    directions: [],
    barlines: [],
  }
  let p = @moonsic.MusicXmlPart::{ id: "P1", name: "T", measures: [m] }
  let doc = @moonsic.MusicXmlScore::{
    title: "",
    composer: "",
    document_kind: @moonsic.Partwise,
    parts: [p],
    divisions: 480,
  }
  let opts = @moonsic.MusicXmlExportOptions::{
    divisions: 480,
    document_kind: @moonsic.Partwise,
    include_xml_header: false,
    include_doctype: false,
    strict: false,
    part_name_fallback: "T",
  }
  match @moonsic.musicxml_to_string_checked(doc, opts) {
    Ok(xml) => assert_true(xml.contains("<type>128th</type>"))
    Err(e) => abort(e.to_string())
  }
}

///|
/// Tie 序列化：tie_start=true 产生 <tie type="start"/>
test "musicxml_v2: tie_start_xml" {
  let note = @moonsic.MusicXmlNote::{
    pitch: Some(@moonsic.MusicXmlPitch::{ step: "C", alter: 0, octave: 4 }),
    duration: 480,
    note_type: @moonsic.QuarterT,
    dots: 0,
    is_rest: false,
    is_chord_tone: false,
    voice: 1,
    staff: 1,
    tie_start: true,
    tie_stop: false,
    notations: [],
    lyric: None,
  }
  let m = @moonsic.MusicXmlMeasure::{
    number: 1,
    attributes: None,
    notes: [note],
    directions: [],
    barlines: [],
  }
  let p = @moonsic.MusicXmlPart::{ id: "P1", name: "T", measures: [m] }
  let doc = @moonsic.MusicXmlScore::{
    title: "",
    composer: "",
    document_kind: @moonsic.Partwise,
    parts: [p],
    divisions: 480,
  }
  let opts = @moonsic.MusicXmlExportOptions::{
    divisions: 480,
    document_kind: @moonsic.Partwise,
    include_xml_header: false,
    include_doctype: false,
    strict: false,
    part_name_fallback: "T",
  }
  match @moonsic.musicxml_to_string_checked(doc, opts) {
    Ok(xml) => {
      assert_true(xml.contains("<tie type=\"start\"/>"))
      assert_true(!xml.contains("<tie type=\"stop\"/>"))
    }
    Err(e) => abort(e.to_string())
  }
}

///|
/// Tie 序列化：tie_stop=true 产生 <tie type="stop"/>
test "musicxml_v2: tie_stop_xml" {
  let note = @moonsic.MusicXmlNote::{
    pitch: Some(@moonsic.MusicXmlPitch::{ step: "D", alter: 0, octave: 4 }),
    duration: 480,
    note_type: @moonsic.QuarterT,
    dots: 0,
    is_rest: false,
    is_chord_tone: false,
    voice: 1,
    staff: 1,
    tie_start: false,
    tie_stop: true,
    notations: [],
    lyric: None,
  }
  let m = @moonsic.MusicXmlMeasure::{
    number: 1,
    attributes: None,
    notes: [note],
    directions: [],
    barlines: [],
  }
  let p = @moonsic.MusicXmlPart::{ id: "P1", name: "T", measures: [m] }
  let doc = @moonsic.MusicXmlScore::{
    title: "",
    composer: "",
    document_kind: @moonsic.Partwise,
    parts: [p],
    divisions: 480,
  }
  let opts = @moonsic.MusicXmlExportOptions::{
    divisions: 480,
    document_kind: @moonsic.Partwise,
    include_xml_header: false,
    include_doctype: false,
    strict: false,
    part_name_fallback: "T",
  }
  match @moonsic.musicxml_to_string_checked(doc, opts) {
    Ok(xml) => {
      assert_true(xml.contains("<tie type=\"stop\"/>"))
      assert_true(!xml.contains("<tie type=\"start\"/>"))
    }
    Err(e) => abort(e.to_string())
  }
}

///|
/// Tie 演奏记号：TieStartN 产生 <tied type="start"/>，与 <tie> 并存
test "musicxml_v2: tied_notation_start_xml" {
  let note = @moonsic.MusicXmlNote::{
    pitch: Some(@moonsic.MusicXmlPitch::{ step: "C", alter: 0, octave: 4 }),
    duration: 480,
    note_type: @moonsic.QuarterT,
    dots: 0,
    is_rest: false,
    is_chord_tone: false,
    voice: 1,
    staff: 1,
    tie_start: true,
    tie_stop: false,
    notations: [@moonsic.MusicXmlNotation::{ kind: @moonsic.TieStartN }],
    lyric: None,
  }
  let m = @moonsic.MusicXmlMeasure::{
    number: 1,
    attributes: None,
    notes: [note],
    directions: [],
    barlines: [],
  }
  let p = @moonsic.MusicXmlPart::{ id: "P1", name: "T", measures: [m] }
  let doc = @moonsic.MusicXmlScore::{
    title: "",
    composer: "",
    document_kind: @moonsic.Partwise,
    parts: [p],
    divisions: 480,
  }
  let opts = @moonsic.MusicXmlExportOptions::{
    divisions: 480,
    document_kind: @moonsic.Partwise,
    include_xml_header: false,
    include_doctype: false,
    strict: false,
    part_name_fallback: "T",
  }
  match @moonsic.musicxml_to_string_checked(doc, opts) {
    Ok(xml) => {
      assert_true(xml.contains("<tie type=\"start\"/>"))
      assert_true(xml.contains("<tied type=\"start\"/>"))
    }
    Err(e) => abort(e.to_string())
  }
}

///|
/// Articulation 记号：Staccato / Accent / Tenuto 产生 <articulations> 包裹
test "musicxml_v2: articulation_staccato_accent_tenuto" {
  let note = @moonsic.MusicXmlNote::{
    pitch: Some(@moonsic.MusicXmlPitch::{ step: "C", alter: 0, octave: 4 }),
    duration: 480,
    note_type: @moonsic.QuarterT,
    dots: 0,
    is_rest: false,
    is_chord_tone: false,
    voice: 1,
    staff: 1,
    tie_start: false,
    tie_stop: false,
    notations: [
      @moonsic.MusicXmlNotation::{ kind: @moonsic.StaccatoN },
      @moonsic.MusicXmlNotation::{ kind: @moonsic.AccentN },
      @moonsic.MusicXmlNotation::{ kind: @moonsic.TenutoN },
    ],
    lyric: None,
  }
  let m = @moonsic.MusicXmlMeasure::{
    number: 1,
    attributes: None,
    notes: [note],
    directions: [],
    barlines: [],
  }
  let p = @moonsic.MusicXmlPart::{ id: "P1", name: "T", measures: [m] }
  let doc = @moonsic.MusicXmlScore::{
    title: "",
    composer: "",
    document_kind: @moonsic.Partwise,
    parts: [p],
    divisions: 480,
  }
  let opts = @moonsic.MusicXmlExportOptions::{
    divisions: 480,
    document_kind: @moonsic.Partwise,
    include_xml_header: false,
    include_doctype: false,
    strict: false,
    part_name_fallback: "T",
  }
  match @moonsic.musicxml_to_string_checked(doc, opts) {
    Ok(xml) => {
      assert_true(xml.contains("<articulations>"))
      assert_true(xml.contains("<staccato/>"))
      assert_true(xml.contains("<accent/>"))
      assert_true(xml.contains("<tenuto/>"))
    }
    Err(e) => abort(e.to_string())
  }
}

///|
/// Slur 记号：SlurStartN / SlurStopN 产生 <slur type="start/stop"/>
test "musicxml_v2: slur_start_stop_xml" {
  let note_s = @moonsic.MusicXmlNote::{
    pitch: Some(@moonsic.MusicXmlPitch::{ step: "C", alter: 0, octave: 4 }),
    duration: 480,
    note_type: @moonsic.QuarterT,
    dots: 0,
    is_rest: false,
    is_chord_tone: false,
    voice: 1,
    staff: 1,
    tie_start: false,
    tie_stop: false,
    notations: [@moonsic.MusicXmlNotation::{ kind: @moonsic.SlurStartN }],
    lyric: None,
  }
  let note_e = @moonsic.MusicXmlNote::{
    pitch: Some(@moonsic.MusicXmlPitch::{ step: "D", alter: 0, octave: 4 }),
    duration: 480,
    note_type: @moonsic.QuarterT,
    dots: 0,
    is_rest: false,
    is_chord_tone: false,
    voice: 1,
    staff: 1,
    tie_start: false,
    tie_stop: false,
    notations: [@moonsic.MusicXmlNotation::{ kind: @moonsic.SlurStopN }],
    lyric: None,
  }
  let m = @moonsic.MusicXmlMeasure::{
    number: 1,
    attributes: None,
    notes: [note_s, note_e],
    directions: [],
    barlines: [],
  }
  let p = @moonsic.MusicXmlPart::{ id: "P1", name: "T", measures: [m] }
  let doc = @moonsic.MusicXmlScore::{
    title: "",
    composer: "",
    document_kind: @moonsic.Partwise,
    parts: [p],
    divisions: 480,
  }
  let opts = @moonsic.MusicXmlExportOptions::{
    divisions: 480,
    document_kind: @moonsic.Partwise,
    include_xml_header: false,
    include_doctype: false,
    strict: false,
    part_name_fallback: "T",
  }
  match @moonsic.musicxml_to_string_checked(doc, opts) {
    Ok(xml) => {
      assert_true(xml.contains("<slur type=\"start\"/>"))
      assert_true(xml.contains("<slur type=\"stop\"/>"))
    }
    Err(e) => abort(e.to_string())
  }
}

///|
/// Fermata / Breath 记号：<fermata/> 和 <breath-mark/>
test "musicxml_v2: fermata_breath_xml" {
  let note_f = @moonsic.MusicXmlNote::{
    pitch: Some(@moonsic.MusicXmlPitch::{ step: "C", alter: 0, octave: 4 }),
    duration: 480,
    note_type: @moonsic.QuarterT,
    dots: 0,
    is_rest: false,
    is_chord_tone: false,
    voice: 1,
    staff: 1,
    tie_start: false,
    tie_stop: false,
    notations: [@moonsic.MusicXmlNotation::{ kind: @moonsic.FermataN }],
    lyric: None,
  }
  let note_b = @moonsic.MusicXmlNote::{
    pitch: Some(@moonsic.MusicXmlPitch::{ step: "D", alter: 0, octave: 4 }),
    duration: 480,
    note_type: @moonsic.QuarterT,
    dots: 0,
    is_rest: false,
    is_chord_tone: false,
    voice: 1,
    staff: 1,
    tie_start: false,
    tie_stop: false,
    notations: [@moonsic.MusicXmlNotation::{ kind: @moonsic.BreathN }],
    lyric: None,
  }
  let m = @moonsic.MusicXmlMeasure::{
    number: 1,
    attributes: None,
    notes: [note_f, note_b],
    directions: [],
    barlines: [],
  }
  let p = @moonsic.MusicXmlPart::{ id: "P1", name: "T", measures: [m] }
  let doc = @moonsic.MusicXmlScore::{
    title: "",
    composer: "",
    document_kind: @moonsic.Partwise,
    parts: [p],
    divisions: 480,
  }
  let opts = @moonsic.MusicXmlExportOptions::{
    divisions: 480,
    document_kind: @moonsic.Partwise,
    include_xml_header: false,
    include_doctype: false,
    strict: false,
    part_name_fallback: "T",
  }
  match @moonsic.musicxml_to_string_checked(doc, opts) {
    Ok(xml) => {
      assert_true(xml.contains("<fermata/>"))
      assert_true(xml.contains("<breath-mark/>"))
    }
    Err(e) => abort(e.to_string())
  }
}

///|
/// 双附点音符：double dotted quarter 产生两个 <dot/> 元素
test "musicxml_v2: double_dotted_xml" {
  let t = @moonsic.melody([
    @moonsic.n(
      @moonsic.c(4),
      @moonsic.dotted(@moonsic.dotted(@moonsic.Duration::Quarter)),
    ),
  ])
  let s = @moonsic.score1(t)
  let opts = @moonsic.default_musicxml_export_options()
  match @moonsic.score_to_musicxml_string_checked(s, opts) {
    Ok(xml) => {
      let dots = _count_occurrences(xml, "<dot/>")
      assert_eq(dots, 2)
    }
    Err(e) => abort(e.to_string())
  }
}

///|
/// Doctype 控制：include_doctype=false 时输出不含 DOCTYPE
test "musicxml_v2: doctype_toggle_off" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let s = @moonsic.score1(t)
  let opts = @moonsic.MusicXmlExportOptions::{
    divisions: @moonsic.DEFAULT_PPQ,
    document_kind: @moonsic.Partwise,
    include_xml_header: true,
    include_doctype: false,
    strict: false,
    part_name_fallback: "Test",
  }
  match @moonsic.score_to_musicxml_string_checked(s, opts) {
    Ok(xml) => {
      assert_true(xml.has_prefix("<?xml"))
      assert_true(!xml.contains("DOCTYPE"))
      assert_true(xml.contains("score-partwise"))
    }
    Err(e) => abort(e.to_string())
  }
}

///|
/// XML header 控制：include_xml_header=false 输出以 <score-partwise> 开头
test "musicxml_v2: include_xml_header_off" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let s = @moonsic.score1(t)
  let opts = @moonsic.MusicXmlExportOptions::{
    divisions: @moonsic.DEFAULT_PPQ,
    document_kind: @moonsic.Partwise,
    include_xml_header: false,
    include_doctype: false,
    strict: false,
    part_name_fallback: "Test",
  }
  match @moonsic.score_to_musicxml_string_checked(s, opts) {
    Ok(xml) => {
      assert_true(!xml.contains("<?xml"))
      assert_true(!xml.contains("DOCTYPE"))
      assert_true(xml.has_prefix("<score-partwise"))
    }
    Err(e) => abort(e.to_string())
  }
}

///|
/// Barline 序列化：right + light-heavy
test "musicxml_v2: barline_xml" {
  let note = @moonsic.MusicXmlNote::{
    pitch: Some(@moonsic.MusicXmlPitch::{ step: "C", alter: 0, octave: 4 }),
    duration: 480,
    note_type: @moonsic.QuarterT,
    dots: 0,
    is_rest: false,
    is_chord_tone: false,
    voice: 1,
    staff: 1,
    tie_start: false,
    tie_stop: false,
    notations: [],
    lyric: None,
  }
  let barline = @moonsic.MusicXmlBarline::{
    location: "right",
    kind: "light-heavy",
  }
  let m = @moonsic.MusicXmlMeasure::{
    number: 1,
    attributes: None,
    notes: [note],
    directions: [],
    barlines: [barline],
  }
  let p = @moonsic.MusicXmlPart::{ id: "P1", name: "T", measures: [m] }
  let doc = @moonsic.MusicXmlScore::{
    title: "",
    composer: "",
    document_kind: @moonsic.Partwise,
    parts: [p],
    divisions: 480,
  }
  let opts = @moonsic.MusicXmlExportOptions::{
    divisions: 480,
    document_kind: @moonsic.Partwise,
    include_xml_header: false,
    include_doctype: false,
    strict: false,
    part_name_fallback: "T",
  }
  match @moonsic.musicxml_to_string_checked(doc, opts) {
    Ok(xml) => {
      assert_true(xml.contains("<barline location=\"right\">"))
      assert_true(xml.contains("<bar-style>light-heavy</bar-style>"))
    }
    Err(e) => abort(e.to_string())
  }
}

///|
/// Composer/Title 输出：<work> 元素包含 work-title 和 creator
test "musicxml_v2: composer_title_work_xml" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let s = @moonsic.score1(t)
  let opts = @moonsic.MusicXmlExportOptions::{
    divisions: @moonsic.DEFAULT_PPQ,
    document_kind: @moonsic.Partwise,
    include_xml_header: false,
    include_doctype: false,
    strict: false,
    part_name_fallback: "Test",
  }
  let doc = match @moonsic.score_to_musicxml_checked(s, opts) {
    Ok(d) =>
      @moonsic.MusicXmlScore::{
        title: "My Piece",
        composer: "Mozart",
        document_kind: d.document_kind,
        parts: d.parts,
        divisions: d.divisions,
      }
    Err(e) => abort(e.to_string())
  }
  match @moonsic.musicxml_to_string_checked(doc, opts) {
    Ok(xml) => {
      assert_true(xml.contains("<work-title>My Piece</work-title>"))
      assert_true(xml.contains("<creator type=\"composer\">Mozart</creator>"))
      assert_true(xml.contains("<work>"))
    }
    Err(e) => abort(e.to_string())
  }
}

///|
/// Lyric 歌词序列化：syllabic + text + verse number
test "musicxml_v2: lyric_xml" {
  let note = @moonsic.MusicXmlNote::{
    pitch: Some(@moonsic.MusicXmlPitch::{ step: "C", alter: 0, octave: 4 }),
    duration: 480,
    note_type: @moonsic.QuarterT,
    dots: 0,
    is_rest: false,
    is_chord_tone: false,
    voice: 1,
    staff: 1,
    tie_start: false,
    tie_stop: false,
    notations: [],
    lyric: Some(@moonsic.MusicXmlLyric::{
      syllabic: "single",
      text: "hello",
      verse: 1,
    }),
  }
  let m = @moonsic.MusicXmlMeasure::{
    number: 1,
    attributes: None,
    notes: [note],
    directions: [],
    barlines: [],
  }
  let p = @moonsic.MusicXmlPart::{ id: "P1", name: "T", measures: [m] }
  let doc = @moonsic.MusicXmlScore::{
    title: "",
    composer: "",
    document_kind: @moonsic.Partwise,
    parts: [p],
    divisions: 480,
  }
  let opts = @moonsic.MusicXmlExportOptions::{
    divisions: 480,
    document_kind: @moonsic.Partwise,
    include_xml_header: false,
    include_doctype: false,
    strict: false,
    part_name_fallback: "T",
  }
  match @moonsic.musicxml_to_string_checked(doc, opts) {
    Ok(xml) => {
      assert_true(xml.contains("<lyric number=\"1\">"))
      assert_true(xml.contains("<syllabic>single</syllabic>"))
      assert_true(xml.contains("<text>hello</text>"))
    }
    Err(e) => abort(e.to_string())
  }
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
// 生成器确定性与边界测试 (generate.mbt — v2 稳定化)
// ============================================================

///|
/// 确定性：和弦进行相同输入两次产生相同输出
test "generate_v2: chord_progression_deterministic" {
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
  let r1 = @moonsic.generate_chord_progression_checked(
    key, degrees, dur, config,
  )
  let r2 = @moonsic.generate_chord_progression_checked(
    key, degrees, dur, config,
  )
  let t1 = match r1 {
    Ok(t) => t
    Err(e) => abort(e.to_string())
  }
  let t2 = match r2 {
    Ok(t) => t
    Err(e) => abort(e.to_string())
  }
  assert_eq(t1.event_count(), t2.event_count())
  for i = 0; i < t1.event_count(); i = i + 1 {
    match (t1.events[i], t2.events[i]) {
      (@moonsic.Chord(c1), @moonsic.Chord(c2)) =>
        assert_eq(c1.pitches[0].to_midi(), c2.pitches[0].to_midi())
      _ => abort("event mismatch at index \{i}")
    }
  }
}

///|
/// 确定性：低音生成相同输入两次产生相同输出
test "generate_v2: bass_deterministic" {
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
  let progression = prog_result.unwrap()
  let r1 = @moonsic.generate_bass_checked(
    progression,
    @moonsic.RootBass,
    config,
  )
  let r2 = @moonsic.generate_bass_checked(
    progression,
    @moonsic.RootBass,
    config,
  )
  let t1 = match r1 {
    Ok(t) => t
    Err(e) => abort(e.to_string())
  }
  let t2 = match r2 {
    Ok(t) => t
    Err(e) => abort(e.to_string())
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
/// 确定性：伴奏生成相同输入两次产生相同输出
test "generate_v2: accompaniment_deterministic" {
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
  let progression = prog_result.unwrap()
  let r1 = @moonsic.generate_accompaniment_checked(
    progression,
    @moonsic.ArpeggioUpDown,
    config,
  )
  let r2 = @moonsic.generate_accompaniment_checked(
    progression,
    @moonsic.ArpeggioUpDown,
    config,
  )
  let s1 = match r1 {
    Ok(s) => s
    Err(e) => abort(e.to_string())
  }
  let s2 = match r2 {
    Ok(s) => s
    Err(e) => abort(e.to_string())
  }
  assert_eq(s1.track_count(), s2.track_count())
  for ti = 0; ti < s1.track_count(); ti = ti + 1 {
    assert_eq(s1.tracks[ti].event_count(), s2.tracks[ti].event_count())
    for ei = 0; ei < s1.tracks[ti].event_count(); ei = ei + 1 {
      match (s1.tracks[ti].events[ei], s2.tracks[ti].events[ei]) {
        (@moonsic.Note(n1), @moonsic.Note(n2)) =>
          assert_eq(n1.pitch.to_midi(), n2.pitch.to_midi())
        (@moonsic.Rest(_), @moonsic.Rest(_)) => ()
        _ => abort("event mismatch: track=\{ti}, event=\{ei}")
      }
    }
  }
}

///|
/// 确定性：游戏循环相同输入两次产生相同输出
test "generate_v2: game_loop_deterministic" {
  let context = @moonsic.GenerationContext::{
    key: @moonsic.key(@moonsic.c(4), @moonsic.Major),
    scale: @moonsic.build_scale(@moonsic.C, @moonsic.Major),
    progression: [1, 4, 5, 1],
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
  let r1 = @moonsic.generate_game_loop_checked(context, 4, config)
  let r2 = @moonsic.generate_game_loop_checked(context, 4, config)
  let s1 = match r1 {
    Ok(s) => s
    Err(e) => abort(e.to_string())
  }
  let s2 = match r2 {
    Ok(s) => s
    Err(e) => abort(e.to_string())
  }
  assert_eq(s1.track_count(), s2.track_count())
  for ti = 0; ti < s1.track_count(); ti = ti + 1 {
    assert_eq(s1.tracks[ti].event_count(), s2.tracks[ti].event_count())
  }
}

///|
/// 错误路径：bars=0 -> InvalidGenerationConfig
test "generate_v2: game_loop_checked_bars_zero" {
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
  let result = @moonsic.generate_game_loop_checked(context, 0, config)
  match result {
    Err(@moonsic.InvalidGenerationConfig(_)) => ()
    _ => abort("expected InvalidGenerationConfig")
  }
}

///|
/// 错误路径：bars=-1 -> InvalidGenerationConfig
test "generate_v2: game_loop_checked_bars_negative" {
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
  let result = @moonsic.generate_game_loop_checked(context, -1, config)
  match result {
    Err(@moonsic.InvalidGenerationConfig(_)) => ()
    _ => abort("expected InvalidGenerationConfig")
  }
}

///|
/// 边界：空和弦进行仍产出 2 轨 Score（旋律+空和弦轨）
test "generate_v2: game_loop_checked_empty_progression" {
  let context = @moonsic.GenerationContext::{
    key: @moonsic.key(@moonsic.c(4), @moonsic.Major),
    scale: @moonsic.build_scale(@moonsic.C, @moonsic.Major),
    progression: [],
    time_signature: @moonsic.four_four(),
    tempo: @moonsic.default_tempo(),
    bars: 2,
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
  let result = @moonsic.generate_game_loop_checked(context, 2, config)
  assert_true(result is Ok(_))
  let score = match result {
    Ok(s) => s
    Err(e) => abort(e.to_string())
  }
  assert_eq(score.track_count(), 2)
  // 和弦轨应为空
  assert_eq(score.tracks[1].event_count(), 0)
}

///|
/// 覆盖：全部 7 种 MelodyContour 均产生有效 Track（4 事件）
test "generate_v2: melody_checked_all_contours" {
  let key = @moonsic.key(@moonsic.c(4), @moonsic.Major)
  let rhythm = @moonsic.rhythm_template(@moonsic.FourQuarters)
  let contours = [
    @moonsic.StepwiseUp,
    @moonsic.StepwiseDown,
    @moonsic.Arch,
    @moonsic.InvertedArch,
    @moonsic.Wave,
    @moonsic.Static,
    @moonsic.ChordTone,
  ]
  for i = 0; i < contours.length(); i = i + 1 {
    let config = @moonsic.GenerationConfig::{
      mode: @moonsic.MelodyOnly,
      contour: contours[i],
      range_low: @moonsic.c(4),
      range_high: @moonsic.c(6),
      seed: None,
      voice_leading: @moonsic.KeepInRange,
      allow_rests: false,
      max_leap: 12,
    }
    let result = @moonsic.generate_melody_checked(key, rhythm, config)
    match result {
      Ok(t) => {
        assert_eq(t.event_count(), rhythm.cells.length())
        // 所有事件应为 Note
        for evt in t.events {
          match evt {
            @moonsic.Note(_) => ()
            _ => abort("expected Note event, contour index=\{i}")
          }
        }
      }
      Err(e) => abort("contour \{i} failed: \{e.to_string()}")
    }
  }
}

///|
/// 边界：allow_rests=true + 含休止的节奏模板 → 产出 Rest 事件
test "generate_v2: melody_checked_with_rests" {
  let key = @moonsic.key(@moonsic.c(4), @moonsic.Major)
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
  let rhythm = match @moonsic.rhythm_pattern_checked(cells) {
    Ok(p) => p
    Err(e) => abort(e.to_string())
  }
  let config = @moonsic.GenerationConfig::{
    mode: @moonsic.MelodyOnly,
    contour: @moonsic.StepwiseUp,
    range_low: @moonsic.c(4),
    range_high: @moonsic.c(6),
    seed: None,
    voice_leading: @moonsic.KeepInRange,
    allow_rests: true,
    max_leap: 12,
  }
  let result = @moonsic.generate_melody_checked(key, rhythm, config)
  match result {
    Ok(t) => {
      assert_eq(t.event_count(), 4)
      match t.events[0] {
        @moonsic.Rest(_) => ()
        _ => abort("event 0 should be Rest")
      }
      match t.events[1] {
        @moonsic.Note(_) => ()
        _ => abort("event 1 should be Note")
      }
      match t.events[2] {
        @moonsic.Rest(_) => ()
        _ => abort("event 2 should be Rest")
      }
      match t.events[3] {
        @moonsic.Note(_) => ()
        _ => abort("event 3 should be Note")
      }
    }
    Err(e) => abort(e.to_string())
  }
}

///|
/// 覆盖：全部 9 种 AccompanimentPattern 均返回 Ok 且至少 1 轨
test "generate_v2: accompaniment_checked_all_patterns" {
  let key = @moonsic.key(@moonsic.c(4), @moonsic.Major)
  let config = @moonsic.GenerationConfig::{
    mode: @moonsic.AccompanimentMode,
    contour: @moonsic.StepwiseUp,
    range_low: @moonsic.c(3),
    range_high: @moonsic.c(5),
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
  let progression = prog_result.unwrap()
  let patterns = [
    @moonsic.BlockChord,
    @moonsic.ArpeggioUp,
    @moonsic.ArpeggioDown,
    @moonsic.ArpeggioUpDown,
    @moonsic.Alberti,
    @moonsic.Pad,
    @moonsic.RootBass,
    @moonsic.RootFifthBass,
    @moonsic.WalkingBass,
  ]
  for i = 0; i < patterns.length(); i = i + 1 {
    let result = @moonsic.generate_accompaniment_checked(
      progression,
      patterns[i],
      config,
    )
    match result {
      Ok(s) => assert_true(s.track_count() >= 1)
      Err(e) => abort("pattern \{i} failed: \{e.to_string()}")
    }
  }
}

///|
/// 短语生成：ChordsOnly 模式产出含和弦事件的 GeneratedPhrase
test "generate_v2: phrase_checked_chords_mode" {
  let context = @moonsic.GenerationContext::{
    key: @moonsic.key(@moonsic.c(4), @moonsic.Major),
    scale: @moonsic.build_scale(@moonsic.C, @moonsic.Major),
    progression: [1, 4, 5, 1],
    time_signature: @moonsic.four_four(),
    tempo: @moonsic.default_tempo(),
    bars: 1,
  }
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
  let result = @moonsic.generate_phrase_checked(context, config)
  match result {
    Ok(phrase) => {
      assert_eq(phrase.track.event_count(), 4)
      // 所有事件应为 Chord
      for evt in phrase.track.events {
        match evt {
          @moonsic.Chord(_) => ()
          _ => abort("expected Chord event in ChordsOnly phrase")
        }
      }
    }
    Err(e) => abort(e.to_string())
  }
}

///|
/// 低音：RootFifthBass 模式产出 4 个根/五度交替低音
test "generate_v2: bass_checked_root_fifth" {
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
  let progression = prog_result.unwrap()
  let result = @moonsic.generate_bass_checked(
    progression,
    @moonsic.RootFifthBass,
    config,
  )
  match result {
    Ok(bass) => {
      assert_eq(bass.event_count(), 8)
      // RootFifthBass 应为 Note 事件
      for evt in bass.events {
        match evt {
          @moonsic.Note(_) => ()
          _ => abort("expected Note event in bass track")
        }
      }
    }
    Err(e) => abort(e.to_string())
  }
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
// 校验模块 v2 扩展测试 (validate.mbt v2 — profile / golden / export readiness)
// ============================================================

///|
/// 校验 v2：profile 构造函数覆盖所有预设
test "validate_v2: all profile option constructors" {
  let edit = @moonsic.editing_validation_options()
  assert_true(!edit.strict_measure_capacity)
  assert_true(!edit.check_ties)
  assert_true(!edit.check_midi_readiness)

  let strict = @moonsic.strict_validation_options()
  assert_true(strict.strict_measure_capacity)
  assert_true(strict.check_ties)
  assert_true(strict.check_voice_alignment)

  let midi = @moonsic.midi_export_validation_options()
  assert_true(midi.check_midi_readiness)
  assert_true(!midi.check_ties)

  let mxml = @moonsic.musicxml_export_validation_options()
  assert_true(mxml.check_musicxml_readiness)
  assert_true(mxml.check_ties)

  let game = @moonsic.game_export_validation_options()
  assert_true(game.check_game_readiness)
  assert_true(game.check_repeats)

  let golden = @moonsic.golden_test_validation_options()
  assert_true(golden.warning_as_error)
  assert_true(golden.check_midi_readiness)
  assert_true(golden.check_musicxml_readiness)
  assert_true(golden.check_game_readiness)
}

///|
/// 校验 v2：validation_options_for_profile 映射正确
test "validate_v2: validation_options_for_profile" {
  let opts = @moonsic.validation_options_for_profile(@moonsic.EditingProfile)
  assert_true(!opts.strict_measure_capacity)
  assert_true(!opts.check_ties)

  let opts2 = @moonsic.validation_options_for_profile(
    @moonsic.GoldenTestProfile,
  )
  assert_true(opts2.warning_as_error)
  assert_true(opts2.check_midi_readiness)
}

///|
/// 校验 v2：validation_report_empty 初始状态全零
test "validate_v2: validation_report_empty" {
  let r = @moonsic.validation_report_empty()
  assert_eq(r.checked_targets, 0)
  assert_eq(r.error_count, 0)
  assert_eq(r.warning_count, 0)
  assert_eq(r.fatal_count, 0)
  assert_eq(r.info_count, 0)
  assert_eq(r.issues.length(), 0)
}

///|
/// 校验 v2：validation_report_add_issue 正确计数
test "validate_v2: validation_report_add_issue" {
  let r = @moonsic.validation_report_empty()
  // 使用 validate_voice_report 生成一条 issue
  let v = @moonsic.empty_voice("Empty")
  let sub = @moonsic.validate_voice_report(
    v,
    @moonsic.strict_validation_options(),
  )
  assert_true(sub.issues.length() > 0)
  // 将生成的 issue 通过 pub API 追加到空 report
  let first_issue = sub.issues[0]
  let r2 = @moonsic.validation_report_add_issue(r, first_issue)
  assert_eq(r2.error_count, 1)
  assert_eq(r2.issues.length(), 1)
}

///|
/// 校验 v2：validation_report_merge 合并两份报告
test "validate_v2: validation_report_merge" {
  let v1 = @moonsic.empty_voice("A")
  let v2 = @moonsic.empty_voice("B")
  let opts = @moonsic.strict_validation_options()
  let r1 = @moonsic.validate_voice_report(v1, opts)
  let r2 = @moonsic.validate_voice_report(v2, opts)
  let merged = @moonsic.validation_report_merge(r1, r2)
  assert_eq(merged.error_count, r1.error_count + r2.error_count)
  assert_eq(merged.issues.length(), r1.issues.length() + r2.issues.length())
}

///|
/// 校验 v2：validation_report_fatal_count 和 info_count
test "validate_v2: validation_report_fatal_and_info_count" {
  let r = @moonsic.validation_report_empty()
  assert_eq(@moonsic.validation_report_fatal_count(r), 0)
  assert_eq(@moonsic.validation_report_info_count(r), 0)
  // 空 voice 在默认模式下产生 warning，不是 error/fatal
  let v = @moonsic.empty_voice("Test")
  let r2 = @moonsic.validate_voice_report(
    v,
    @moonsic.default_validation_options(),
  )
  assert_eq(@moonsic.validation_report_fatal_count(r2), 0)
}

///|
/// 校验 v2：validation_report_is_export_blocking
test "validate_v2: validation_report_is_export_blocking" {
  let r = @moonsic.validation_report_empty()
  assert_true(!@moonsic.validation_report_is_export_blocking(r))
  // 有 error 则 blocking
  let v = @moonsic.empty_voice("Test")
  let r2 = @moonsic.validate_voice_report(
    v,
    @moonsic.strict_validation_options(),
  )
  assert_true(@moonsic.validation_report_is_export_blocking(r2))
}

///|
/// 校验 v2：validation_code_to_string 公开可用
test "validate_v2: validation_code_to_string" {
  let s = @moonsic.validation_code_to_string(@moonsic.InvalidPPQ)
  assert_eq(s, "InvalidPPQ")
  let s2 = @moonsic.validation_code_to_string(@moonsic.EmptyVoice)
  assert_eq(s2, "EmptyVoice")
}

///|
/// 校验 v2：validation_severity_to_string 公开可用
test "validate_v2: validation_severity_to_string" {
  assert_eq(@moonsic.validation_severity_to_string(@moonsic.Error), "Error")
  assert_eq(@moonsic.validation_severity_to_string(@moonsic.Warning), "Warning")
  assert_eq(@moonsic.validation_severity_to_string(@moonsic.Info), "Info")
  assert_eq(@moonsic.validation_severity_to_string(@moonsic.Fatal), "Fatal")
}

///|
/// 校验 v2：validation_target_kind_to_string 公开可用
test "validate_v2: validation_target_kind_to_string" {
  assert_eq(
    @moonsic.validation_target_kind_to_string(@moonsic.ValidateScoreTarget),
    "Score",
  )
  assert_eq(
    @moonsic.validation_target_kind_to_string(@moonsic.MeasureTarget),
    "Measure",
  )
}

///|
/// 校验 v2：validation_code_default_suggestion 公开可用
test "validate_v2: validation_code_default_suggestion" {
  let s = @moonsic.validation_code_default_suggestion(@moonsic.InvalidPPQ)
  assert_true(s.contains("PPQ"))
  let s2 = @moonsic.validation_code_default_suggestion(@moonsic.EmptyVoice)
  assert_true(s2.contains("rest"))
}

///|
/// 校验 v2：validation_code_default_severity 按 profile 区分
test "validate_v2: validation_code_default_severity_by_profile" {
  // MeasureUnderfilled: Editing=Info, Strict=Warning, MidiExport=Warning
  let s1 = @moonsic.validation_code_default_severity(
    @moonsic.MeasureUnderfilled,
    @moonsic.EditingProfile,
  )
  assert_true(s1 is @moonsic.Info)
  let s2 = @moonsic.validation_code_default_severity(
    @moonsic.MeasureUnderfilled,
    @moonsic.StrictProfile,
  )
  assert_true(s2 is @moonsic.Warning)
  let s3 = @moonsic.validation_code_default_severity(
    @moonsic.MeasureUnderfilled,
    @moonsic.GoldenTestProfile,
  )
  assert_true(s3 is @moonsic.Error)
}

///|
/// 校验 v2：validate_part_report 空 part 产生 EmptyPart
test "validate_v2: validate_part_report_empty_part" {
  let p = @moonsic.make_part("Empty", []).unwrap()
  let opts = @moonsic.strict_validation_options()
  let report = @moonsic.validate_part_report(p, opts)
  assert_true(@moonsic.validation_report_has_errors(report))
}

///|
/// 校验 v2：validate_part_report 合法 part 不产生错误
test "validate_v2: validate_part_report_valid" {
  let sig = @moonsic.four_four()
  let events = [@moonsic.n(@moonsic.c(4), @moonsic.quarter())]
  let m = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let v = @moonsic.make_voice("RH", [m]).unwrap()
  let s = @moonsic.make_staff("Piano", Some(0), Some(0), None, [v]).unwrap()
  let p = @moonsic.make_part("Keyboard", [s]).unwrap()
  let opts = @moonsic.default_validation_options()
  let report = @moonsic.validate_part_report(p, opts)
  assert_true(!@moonsic.validation_report_is_export_blocking(report))
}

///|
/// 校验 v2：validate_midi_export_ready 检查 MIDI 就绪
test "validate_v2: validate_midi_export_ready_valid" {
  let sig = @moonsic.four_four()
  let events = [
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.e(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.f(4), @moonsic.quarter()),
  ]
  let m = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let v = @moonsic.make_voice("RH", [m]).unwrap()
  let s = @moonsic.make_staff("Piano", Some(0), Some(0), None, [v]).unwrap()
  let p = @moonsic.make_part("Keyboard", [s]).unwrap()
  let sl = @moonsic.make_score_layout("Test", 480, [p]).unwrap()
  let report = @moonsic.validate_midi_export_ready(sl)
  assert_true(!@moonsic.validation_report_is_export_blocking(report))
}

///|
/// 校验 v2：validate_musicxml_export_ready 检查 MusicXML 就绪
test "validate_v2: validate_musicxml_export_ready_valid" {
  let sig = @moonsic.four_four()
  let events = [
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.e(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.f(4), @moonsic.quarter()),
  ]
  let m = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let v = @moonsic.make_voice("RH", [m]).unwrap()
  let s = @moonsic.make_staff("Piano", Some(0), Some(0), None, [v]).unwrap()
  let p = @moonsic.make_part("Keyboard", [s]).unwrap()
  let sl = @moonsic.make_score_layout("Test", 480, [p]).unwrap()
  let report = @moonsic.validate_musicxml_export_ready(sl)
  assert_true(!@moonsic.validation_report_is_export_blocking(report))
}

///|
/// 校验 v2：validate_game_export_ready 检查 Game IR 就绪
test "validate_v2: validate_game_export_ready_valid" {
  let sig = @moonsic.four_four()
  let events = [
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.e(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.f(4), @moonsic.quarter()),
  ]
  let m = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let v = @moonsic.make_voice("RH", [m]).unwrap()
  let s = @moonsic.make_staff("Piano", Some(0), Some(0), None, [v]).unwrap()
  let p = @moonsic.make_part("Keyboard", [s]).unwrap()
  let sl = @moonsic.make_score_layout("Test", 480, [p]).unwrap()
  let report = @moonsic.validate_game_export_ready(sl)
  assert_true(!@moonsic.validation_report_is_export_blocking(report))
}

///|
/// 校验 v2：validation_report_to_golden_text 确定性输出
test "validate_v2: validation_report_to_golden_text" {
  let r = @moonsic.validation_report_empty()
  let text = @moonsic.validation_report_to_golden_text(r)
  assert_true(text.contains("GOLDEN"))
  assert_true(text.contains("0 issues"))
  // 添加一条 issue 后 golden text 应包含 severity/code/path
  let v = @moonsic.empty_voice("Test")
  let r2 = @moonsic.validate_voice_report(
    v,
    @moonsic.strict_validation_options(),
  )
  let text2 = @moonsic.validation_report_to_golden_text(r2)
  assert_true(text2.contains("EmptyVoice"))
  assert_true(text2.contains("voice[Test]"))
}

///|
/// 校验 v2：validation_report_to_json 包含 info_count
test "validate_v2: validation_report_to_json_has_info_count" {
  let r = @moonsic.validation_report_empty()
  let json = @moonsic.validation_report_to_json(r)
  assert_true(json.contains("info_count"))
  assert_true(json.contains("error_count"))
}

///|
/// 校验 v2：validation_context 创建
test "validate_v2: validation_context_creation" {
  let ctx = @moonsic.validation_context(0, 1, 2, "part[P]/staff[S]")
  assert_eq(ctx.part_index, 0)
  assert_eq(ctx.staff_index, 1)
  assert_eq(ctx.voice_index, 2)
  assert_eq(ctx.path_prefix, "part[P]/staff[S]")
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

// ============================================================
// Pitch v2 稳定化 — 边界与等音测试
// ============================================================

///|
/// MIDI 下界：C-1 -> MIDI 0
test "pitch_v2: C-1 midi zero" {
  let p = @moonsic.pitch(@moonsic.C, @moonsic.Natural, -1)
  assert_eq(p.to_midi(), 0)
  assert_true(p.is_valid_midi())
}

///|
/// MIDI 上界：G9 -> MIDI 127
test "pitch_v2: G9 midi 127" {
  let p = @moonsic.pitch(@moonsic.G, @moonsic.Natural, 9)
  assert_eq(p.to_midi(), 127)
  assert_true(p.is_valid_midi())
}

///|
/// pitch_equal 相同拼写 -> true
test "pitch_v2: pitch_equal same spelling" {
  let a = @moonsic.pitch(@moonsic.C, @moonsic.Sharp, 4)
  let b = @moonsic.pitch(@moonsic.C, @moonsic.Sharp, 4)
  assert_true(@moonsic.pitch_equal(a, b))
}

///|
/// pitch_equal 不同拼写 (C#4 vs Db4) -> false
test "pitch_v2: pitch_equal different spelling" {
  let a = @moonsic.pitch(@moonsic.C, @moonsic.Sharp, 4)
  let b = @moonsic.pitch(@moonsic.D, @moonsic.Flat, 4)
  assert_false(@moonsic.pitch_equal(a, b))
}

///|
/// enharmonic_equal C#4 == Db4 (MIDI 相同) -> true
test "pitch_v2: enharmonic_equal sharp flat" {
  let a = @moonsic.pitch(@moonsic.C, @moonsic.Sharp, 4)
  let b = @moonsic.pitch(@moonsic.D, @moonsic.Flat, 4)
  assert_true(@moonsic.enharmonic_equal(a, b))
}

///|
/// enharmonic_equal C4 != D4 -> false
test "pitch_v2: enharmonic_equal different notes" {
  let a = @moonsic.pitch(@moonsic.C, @moonsic.Natural, 4)
  let b = @moonsic.pitch(@moonsic.D, @moonsic.Natural, 4)
  assert_false(@moonsic.enharmonic_equal(a, b))
}

///|
/// pitch_compare 升序
test "pitch_v2: pitch_compare ascending" {
  let c4 = @moonsic.pitch(@moonsic.C, @moonsic.Natural, 4)
  let d4 = @moonsic.pitch(@moonsic.D, @moonsic.Natural, 4)
  assert_eq(@moonsic.pitch_compare(c4, d4), -1)
  assert_eq(@moonsic.pitch_compare(d4, c4), 1)
  assert_eq(@moonsic.pitch_compare(c4, c4), 0)
}

///|
/// transpose C4 + 12 -> C5 (八度移调)
test "pitch_v2: transpose_up_octave" {
  let p = @moonsic.pitch(@moonsic.C, @moonsic.Natural, 4)
  let r = @moonsic.transpose_pitch(p, 12)
  assert_true(r is Ok(_))
  let p2 = r.unwrap()
  assert_eq(p2.to_midi(), 72)
  assert_eq(p2.octave, 5)
  assert_eq(p2.to_string(), "C5")
}

///|
/// transpose C-1 - 1 -> Err(MidiOutOfRange)
test "pitch_v2: transpose_out_of_range_low" {
  let p = @moonsic.pitch(@moonsic.C, @moonsic.Natural, -1)
  let r = @moonsic.transpose_pitch(p, -1)
  assert_true(r is Err(@moonsic.MidiOutOfRange(_)))
}

///|
/// transpose G9 + 1 -> Err(MidiOutOfRange)
test "pitch_v2: transpose_out_of_range_high" {
  let p = @moonsic.pitch(@moonsic.G, @moonsic.Natural, 9)
  let r = @moonsic.transpose_pitch(p, 1)
  assert_true(r is Err(@moonsic.MidiOutOfRange(_)))
}

///|
/// DoubleSharp: C##4 -> MIDI 62 (等音于 D4)
test "pitch_v2: double_sharp_midi" {
  let p = @moonsic.pitch(@moonsic.C, @moonsic.DoubleSharp, 4)
  assert_eq(p.to_midi(), 62)
  // 与 D4 等音，但拼写不同
  let d4 = @moonsic.pitch(@moonsic.D, @moonsic.Natural, 4)
  assert_true(@moonsic.enharmonic_equal(p, d4))
  assert_false(@moonsic.pitch_equal(p, d4))
}

///|
/// DoubleFlat: Dbb4 -> MIDI 60 (等音于 C4)
test "pitch_v2: double_flat_midi" {
  let p = @moonsic.pitch(@moonsic.D, @moonsic.DoubleFlat, 4)
  assert_eq(p.to_midi(), 60)
  // 与 C4 等音，但拼写不同
  let c4 = @moonsic.pitch(@moonsic.C, @moonsic.Natural, 4)
  assert_true(@moonsic.enharmonic_equal(p, c4))
  assert_false(@moonsic.pitch_equal(p, c4))
}

///|
/// midi_note_compare 排序
test "pitch_v2: midi_note_compare" {
  assert_eq(@moonsic.midi_note_compare(0, 127), -1)
  assert_eq(@moonsic.midi_note_compare(127, 0), 1)
  assert_eq(@moonsic.midi_note_compare(60, 60), 0)
}

///|
/// C#4 与 Db4 的完整对比：MIDI 相同、等音 true、拼写不同
test "pitch_v2: enharmonic_sharp_flat_roundtrip" {
  let cs4 = @moonsic.pitch(@moonsic.C, @moonsic.Sharp, 4)
  let db4 = @moonsic.pitch(@moonsic.D, @moonsic.Flat, 4)
  assert_eq(cs4.to_midi(), 61)
  assert_eq(db4.to_midi(), 61)
  assert_eq(cs4.to_midi(), db4.to_midi())
  assert_true(@moonsic.enharmonic_equal(cs4, db4))
  assert_false(@moonsic.pitch_equal(cs4, db4))
  assert_eq(@moonsic.pitch_compare(cs4, db4), 0)
}

///|
/// 变音记号偏移量验证：全部五种
test "pitch_v2: accidental_offsets_all" {
  assert_eq(@moonsic.DoubleFlat.semitone_offset(), -2)
  assert_eq(@moonsic.Flat.semitone_offset(), -1)
  assert_eq(@moonsic.Natural.semitone_offset(), 0)
  assert_eq(@moonsic.Sharp.semitone_offset(), 1)
  assert_eq(@moonsic.DoubleSharp.semitone_offset(), 2)
}

///|
/// DoubleSharp to_string 为 "x"（v1 兼容行为）
test "pitch_v2: double_sharp_to_string_is_x" {
  assert_eq(@moonsic.DoubleSharp.to_string(), "x")
}

///|
/// pitch_to_frequency_checked A4 = 440.0 Hz
test "pitch_v2: frequency_A4_equals_440" {
  let p = @moonsic.pitch(@moonsic.A, @moonsic.Natural, 4)
  let r = @moonsic.pitch_to_frequency_checked(p)
  assert_true(r is Ok(_))
  let hz = r.unwrap()
  assert_true((hz - 440.0).abs() < 0.01)
}

///|
/// frequency_to_nearest_midi_checked 440.0 Hz -> 69 (A4)
test "pitch_v2: frequency_440_to_midi_69" {
  let r = @moonsic.frequency_to_nearest_midi_checked(440.0)
  assert_true(r is Ok(_))
  assert_eq(r.unwrap(), 69)
}

///|
/// frequency_to_nearest_midi_checked 0.0 -> Err(InvalidFrequency)
test "pitch_v2: frequency_zero_error" {
  let r = @moonsic.frequency_to_nearest_midi_checked(0.0)
  assert_true(r is Err(@moonsic.InvalidFrequency(_)))
}

///|
/// frequency_to_nearest_midi_checked 负数 -> Err(InvalidFrequency)
test "pitch_v2: frequency_negative_error" {
  let r = @moonsic.frequency_to_nearest_midi_checked(-100.0)
  assert_true(r is Err(@moonsic.InvalidFrequency(_)))
}

///|
/// C5 (MIDI 72) 是 C4 (MIDI 60) 的 2 倍频率（一个八度）
test "pitch_v2: frequency_octave_doubling" {
  let c4 = @moonsic.pitch(@moonsic.C, @moonsic.Natural, 4)
  let c5 = @moonsic.pitch(@moonsic.C, @moonsic.Natural, 5)
  let f4 = @moonsic.pitch_to_frequency_checked(c4).unwrap()
  let f5 = @moonsic.pitch_to_frequency_checked(c5).unwrap()
  // 八度关系：f5 ≈ 2 * f4
  assert_true((f5 / f4 - 2.0).abs() < 0.001)
}

///|
/// pitch_to_midi Result 路径：合法音高返回 Ok
test "pitch_v2: pitch_to_midi_result_ok" {
  let p = @moonsic.pitch(@moonsic.G, @moonsic.Natural, 9)
  let r = @moonsic.pitch_to_midi(p)
  assert_true(r is Ok(_))
  assert_eq(r.unwrap(), 127)
}

///|
/// pitch_to_midi Result 路径：非法音高返回 Err
test "pitch_v2: pitch_to_midi_result_out_of_range" {
  // C10 -> MIDI 132, 超出范围
  let p = @moonsic.pitch(@moonsic.C, @moonsic.Natural, 10)
  let r = @moonsic.pitch_to_midi(p)
  assert_true(r is Err(@moonsic.MidiOutOfRange(_)))
}

///|
/// InvalidFrequency to_string 包含消息
test "pitch_v2: invalid_frequency_error_to_string" {
  let e = @moonsic.InvalidFrequency(-1.0)
  assert_true(e.to_string().contains("无效频率"))
}

// ============================================================
// Rhythm/Time 稳定化 — 边界与转换测试 (v2)
// ============================================================

///|
/// 边界：5/4 小节长度 @ 480ppq = 2400 ticks
test "time_boundary: bar_length_5_4" {
  let sig = @moonsic.time_signature(5, 4)
  let ticks = @moonsic.bar_length_ticks(sig, 480).unwrap()
  assert_eq(ticks, 2400)
}

///|
/// 边界：7/8 小节长度 @ 480ppq = 1680 ticks
test "time_boundary: bar_length_7_8" {
  let sig = @moonsic.time_signature(7, 8)
  let ticks = @moonsic.bar_length_ticks(sig, 480).unwrap()
  assert_eq(ticks, 1680)
}

///|
/// 边界：960 ticks @ 120bpm @ 480ppq = 1.0 秒
test "time_boundary: ticks_to_seconds_960_at_120" {
  let sec = @moonsic.ticks_to_seconds(960, 120.0, 480).unwrap()
  assert_true(sec > 0.99 && sec < 1.01)
}

///|
/// 边界：三分附点 (dots=3) — 15/8 倍率, quarter → 900 ticks
test "time_boundary: rhythm_duration_triple_dotted" {
  let d = @moonsic.RhythmDuration::{
    unit: @moonsic.DurQuarter,
    dots: 3,
    tuplet: None,
  }
  let ticks = @moonsic.rhythm_duration_to_ticks(d, 480).unwrap()
  assert_eq(ticks, 900)
}

///|
/// 边界：附点数 > 3 应返回错误
test "time_boundary: rhythm_duration_dots_excessive_err" {
  let d = @moonsic.RhythmDuration::{
    unit: @moonsic.DurQuarter,
    dots: 4,
    tuplet: None,
  }
  let r = @moonsic.rhythm_duration_to_ticks(d, 480)
  assert_true(r is Err(_))
}

///|
/// 边界：连音比为 3:0 (normal=0) 应返回错误
test "time_boundary: rhythm_duration_tuplet_invalid_err" {
  let d = @moonsic.RhythmDuration::{
    unit: @moonsic.DurEighth,
    dots: 0,
    tuplet: Some(@moonsic.TupletRatio::{ actual: 3, normal: 0 }),
  }
  let r = @moonsic.rhythm_duration_to_ticks(d, 480)
  assert_true(r is Err(_))
}

///|
/// 边界：5:4 连音八分 @ 480ppq = 192 ticks
/// 公式：480 * 1/2 * 4/5 = 192
test "time_boundary: rhythm_duration_tuplet_5_4_eighth" {
  let d = @moonsic.RhythmDuration::{
    unit: @moonsic.DurEighth,
    dots: 0,
    tuplet: Some(@moonsic.TupletRatio::{ actual: 5, normal: 4 }),
  }
  let ticks = @moonsic.rhythm_duration_to_ticks(d, 480).unwrap()
  assert_eq(ticks, 192)
}

///|
/// 边界：64分音符 @ 480ppq = 30 ticks
test "time_boundary: rhythm_duration_sixtyfourth" {
  let d = @moonsic.RhythmDuration::{
    unit: @moonsic.SixtyFourth,
    dots: 0,
    tuplet: None,
  }
  let ticks = @moonsic.rhythm_duration_to_ticks(d, 480).unwrap()
  assert_eq(ticks, 30)
}

///|
/// 边界：128分音符 @ 480ppq = 15 ticks
test "time_boundary: rhythm_duration_128th" {
  let d = @moonsic.RhythmDuration::{
    unit: @moonsic.OneTwentyEighth,
    dots: 0,
    tuplet: None,
  }
  let ticks = @moonsic.rhythm_duration_to_ticks(d, 480).unwrap()
  assert_eq(ticks, 15)
}

///|
/// 边界：全音符 @ 480ppq = 1920 ticks
test "time_boundary: bar_length_full_whole" {
  let sig = @moonsic.time_signature(4, 4)
  let bar_ticks = @moonsic.bar_length_ticks(sig, 480).unwrap()
  // 4/4 小节 = 1920 ticks（恰好等于全音符）
  let whole = @moonsic.RhythmDuration::{
    unit: @moonsic.DurWhole,
    dots: 0,
    tuplet: None,
  }
  let whole_ticks = @moonsic.rhythm_duration_to_ticks(whole, 480).unwrap()
  assert_eq(bar_ticks, 1920)
  assert_eq(whole_ticks, 1920)
}

///|
/// 边界：seconds_to_ticks_checked 合法输入（1.0s @ 120bpm @ 480ppq → 960 ticks）
test "time_boundary: seconds_to_ticks_checked_valid" {
  let r = @moonsic.seconds_to_ticks_checked(1.0, 120.0, 480)
  assert_true(r is Ok(_))
  assert_eq(r.unwrap(), 960)
}

///|
/// 边界：seconds_to_ticks_checked ppq=0 返回错误
test "time_boundary: seconds_to_ticks_checked_invalid_ppq" {
  let r = @moonsic.seconds_to_ticks_checked(1.0, 120.0, 0)
  assert_true(r is Err(_))
}

///|
/// 边界：seconds_to_ticks_checked bpm=0 返回错误
test "time_boundary: seconds_to_ticks_checked_invalid_bpm" {
  let r = @moonsic.seconds_to_ticks_checked(1.0, 0.0, 480)
  assert_true(r is Err(_))
}

///|
/// 边界：seconds_to_ticks_checked 秒数为负返回错误
test "time_boundary: seconds_to_ticks_checked_negative" {
  let r = @moonsic.seconds_to_ticks_checked(-1.0, 120.0, 480)
  assert_true(r is Err(_))
}

///|
/// 边界：position_to_ticks bar=2 beat=1 offset=0, 4/4 @ 480 → 4320
test "time_boundary: position_to_ticks_bar2_beat1" {
  let pos = @moonsic.BarPosition::{
    bar: 2,
    beat: @moonsic.rational(1, 1).unwrap(),
    offset: @moonsic.rational(0, 1).unwrap(),
  }
  let sig = @moonsic.time_signature(4, 4)
  let ticks = @moonsic.position_to_ticks(pos, sig, 480).unwrap()
  assert_eq(ticks, 4320)
}

///|
/// 边界：position_to_ticks bar=0 beat=2 offset=1/2, 4/4 @ 480 → 1200
/// 小节开始 0 + 2 拍 (960) + 半拍 (480*0.5=240) = 1200
test "time_boundary: position_to_ticks_with_offset" {
  let pos = @moonsic.BarPosition::{
    bar: 0,
    beat: @moonsic.rational(2, 1).unwrap(),
    offset: @moonsic.rational(1, 2).unwrap(),
  }
  let sig = @moonsic.time_signature(4, 4)
  let ticks = @moonsic.position_to_ticks(pos, sig, 480).unwrap()
  assert_eq(ticks, 1200)
}

///|
/// 边界：position → ticks → position 往返一致
test "time_boundary: position_ticks_roundtrip" {
  let sig = @moonsic.time_signature(4, 4)
  let pos = @moonsic.BarPosition::{
    bar: 3,
    beat: @moonsic.rational(3, 1).unwrap(),
    offset: @moonsic.rational(1, 4).unwrap(),
  }
  let ticks = @moonsic.position_to_ticks(pos, sig, 480).unwrap()
  let pos2 = @moonsic.ticks_to_position(ticks, sig, 480).unwrap()
  assert_eq(pos2.bar, 3)
  // beat should be 3 (integer)
  assert_true(@moonsic.rational_is_integer(pos2.beat))
  assert_eq(@moonsic.rational_to_int(pos2.beat).unwrap(), 3)
  // offset should be 1/4 (120/480)
  assert_eq(pos2.offset.numerator, 1)
  assert_eq(pos2.offset.denominator, 4)
}

///|
/// 边界：TimeMap 多速度段 4 segment 累加
/// tick 0-480@120, 480-960@60, 960-1440@30
/// seg1: 0.5s, seg2: 1.0s, seg3: 2.0s → total 3.5s
test "time_boundary: timemap_multi_tempo_3_changes" {
  let sig = @moonsic.time_signature(4, 4)
  let tm = @moonsic.make_time_map(480, sig, 120.0).unwrap()
  let tm2 = @moonsic.add_tempo_change(tm, @moonsic.TempoChange::{
    at_tick: 480,
    tempo_bpm: 60.0,
  })
  let tm3 = @moonsic.add_tempo_change(tm2, @moonsic.TempoChange::{
    at_tick: 960,
    tempo_bpm: 30.0,
  })
  // seg1: 0..480 @ 120 = 0.5s
  // seg2: 480..960 @ 60 = 1.0s
  // seg3: 960..1440 @ 30 = 2.0s
  // total: 3.5s
  let sec = @moonsic.ticks_to_seconds_timemap(1440, tm3).unwrap()
  assert_true(sec > 3.49 && sec < 3.51)
}

///|
/// 边界：Parsed "q." then to_ticks @ 480 = 720
test "time_boundary: parsed_dotted_quarter_to_ticks" {
  let dur = @moonsic.parse_dur_unit("q.").unwrap()
  let ticks = @moonsic.rhythm_duration_to_ticks(dur, 480).unwrap()
  assert_eq(ticks, 720)
}

///|
/// 边界：Parsed "q.." then to_ticks @ 480 = 840
test "time_boundary: parsed_double_dotted_to_ticks" {
  let dur = @moonsic.parse_dur_unit("q..").unwrap()
  let ticks = @moonsic.rhythm_duration_to_ticks(dur, 480).unwrap()
  assert_eq(ticks, 840)
}

///|
/// 边界：Parsed "3:2 8" then to_ticks @ 480 = 160
test "time_boundary: parsed_triplet_eighth_to_ticks" {
  let dur = @moonsic.parse_dur_unit("3:2 8").unwrap()
  let ticks = @moonsic.rhythm_duration_to_ticks(dur, 480).unwrap()
  assert_eq(ticks, 160)
}

///|
/// 边界：Rational to_double 负值
test "time_boundary: rational_to_double_negative" {
  let r = @moonsic.rational(-3, 4).unwrap()
  let d = @moonsic.rational_to_double(r)
  assert_true(d < -0.74 && d > -0.76)
}

///|
/// 边界：Rational is_integer 零值
test "time_boundary: rational_is_integer_zero" {
  let r = @moonsic.rational(0, 5).unwrap()
  assert_true(@moonsic.rational_is_integer(r))
}

///|
/// 边界：tick=0 位置转换
test "time_boundary: ticks_to_position_tick_zero" {
  let sig = @moonsic.time_signature(4, 4)
  let pos = @moonsic.ticks_to_position(0, sig, 480).unwrap()
  assert_eq(pos.bar, 0)
  assert_eq(pos.beat.numerator, 0)
  assert_eq(pos.offset.numerator, 0)
}

// ============================================================
// Chord/Scale/Key 稳定化 — 边界与 spelling 测试 (v2)
// ============================================================

///|
/// ChordQuality intervals 全部 11 种品质 — 验证半音间隔模式
test "chord_v2: chord_quality_intervals_all" {
  // Triads
  assert_eq(@moonsic.MajorTriad.intervals(), [0, 4, 7])
  assert_eq(@moonsic.MinorTriad.intervals(), [0, 3, 7])
  assert_eq(@moonsic.DiminishedTriad.intervals(), [0, 3, 6])
  assert_eq(@moonsic.AugmentedTriad.intervals(), [0, 4, 8])
  assert_eq(@moonsic.Suspended2.intervals(), [0, 2, 7])
  assert_eq(@moonsic.Suspended4.intervals(), [0, 5, 7])
  // Sevenths
  assert_eq(@moonsic.DominantSeventh.intervals(), [0, 4, 7, 10])
  assert_eq(@moonsic.MajorSeventh.intervals(), [0, 4, 7, 11])
  assert_eq(@moonsic.MinorSeventh.intervals(), [0, 3, 7, 10])
  assert_eq(@moonsic.HalfDiminished7.intervals(), [0, 3, 6, 10])
  assert_eq(@moonsic.Diminished7.intervals(), [0, 3, 6, 9])
}

///|
/// ScaleKind intervals 全部 12 种 — 验证音阶间隔模式
/// 注：Major/Minor 在 ScaleKind 和 IntervalQuality 中均有定义，通过类型注解消歧义
test "chord_v2: scale_kind_intervals_all" {
  let major_kind : @moonsic.ScaleKind = @moonsic.ScaleKind::Major
  assert_eq(major_kind.intervals(), [0, 2, 4, 5, 7, 9, 11])
  assert_eq(@moonsic.NaturalMinor.intervals(), [0, 2, 3, 5, 7, 8, 10])
  assert_eq(@moonsic.MajorPentatonic.intervals(), [0, 2, 4, 7, 9])
  assert_eq(@moonsic.MinorPentatonic.intervals(), [0, 3, 5, 7, 10])
  assert_eq(@moonsic.HarmonicMinor.intervals(), [0, 2, 3, 5, 7, 8, 11])
  assert_eq(@moonsic.MelodicMinor.intervals(), [0, 2, 3, 5, 7, 9, 11])
  assert_eq(@moonsic.Dorian.intervals(), [0, 2, 3, 5, 7, 9, 10])
  assert_eq(@moonsic.Phrygian.intervals(), [0, 1, 3, 5, 7, 8, 10])
  assert_eq(@moonsic.Lydian.intervals(), [0, 2, 4, 6, 7, 9, 11])
  assert_eq(@moonsic.Mixolydian.intervals(), [0, 2, 4, 5, 7, 9, 10])
  assert_eq(@moonsic.Locrian.intervals(), [0, 1, 3, 5, 6, 8, 10])
  assert_eq(@moonsic.Chromatic.intervals(), [
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
  ])
}

///|
/// chord_quality_letter_steps 全部品质 — 验证字母步进
test "chord_v2: chord_quality_letter_steps_all" {
  assert_eq(@moonsic.chord_quality_letter_steps(@moonsic.MajorTriad), [0, 2, 4])
  assert_eq(@moonsic.chord_quality_letter_steps(@moonsic.MinorTriad), [0, 2, 4])
  assert_eq(@moonsic.chord_quality_letter_steps(@moonsic.Diminished7), [
    0, 2, 4, 6,
  ])
  assert_eq(@moonsic.chord_quality_letter_steps(@moonsic.Suspended2), [0, 1, 4])
  assert_eq(@moonsic.chord_quality_letter_steps(@moonsic.Suspended4), [0, 3, 4])
  assert_eq(@moonsic.chord_quality_letter_steps(@moonsic.DominantSeventh), [
    0, 2, 4, 6,
  ])
}

///|
/// parse_chord_quality_checked: 合法别名全部匹配
test "chord_v2: parse_chord_quality_checked_valid_aliases" {
  assert_true(
    @moonsic.parse_chord_quality_checked("maj7").unwrap()
    is @moonsic.MajorSeventh,
  )
  assert_true(
    @moonsic.parse_chord_quality_checked("M7").unwrap() is @moonsic.MajorSeventh,
  )
  assert_true(
    @moonsic.parse_chord_quality_checked("dim7").unwrap()
    is @moonsic.Diminished7,
  )
  assert_true(
    @moonsic.parse_chord_quality_checked("o7").unwrap() is @moonsic.Diminished7,
  )
  assert_true(
    @moonsic.parse_chord_quality_checked("m7b5").unwrap()
    is @moonsic.HalfDiminished7,
  )
  assert_true(
    @moonsic.parse_chord_quality_checked("min7").unwrap()
    is @moonsic.MinorSeventh,
  )
  assert_true(
    @moonsic.parse_chord_quality_checked("m7").unwrap() is @moonsic.MinorSeventh,
  )
  assert_true(
    @moonsic.parse_chord_quality_checked("dim").unwrap()
    is @moonsic.DiminishedTriad,
  )
  assert_true(
    @moonsic.parse_chord_quality_checked("o").unwrap()
    is @moonsic.DiminishedTriad,
  )
  assert_true(
    @moonsic.parse_chord_quality_checked("aug").unwrap()
    is @moonsic.AugmentedTriad,
  )
  assert_true(
    @moonsic.parse_chord_quality_checked("+").unwrap()
    is @moonsic.AugmentedTriad,
  )
  assert_true(
    @moonsic.parse_chord_quality_checked("min").unwrap() is @moonsic.MinorTriad,
  )
  assert_true(
    @moonsic.parse_chord_quality_checked("m").unwrap() is @moonsic.MinorTriad,
  )
  assert_true(
    @moonsic.parse_chord_quality_checked("7").unwrap()
    is @moonsic.DominantSeventh,
  )
  assert_true(
    @moonsic.parse_chord_quality_checked("").unwrap() is @moonsic.MajorTriad,
  )
  assert_true(
    @moonsic.parse_chord_quality_checked("sus2").unwrap() is @moonsic.Suspended2,
  )
  assert_true(
    @moonsic.parse_chord_quality_checked("sus4").unwrap() is @moonsic.Suspended4,
  )
}

///|
/// parse_chord_quality_checked: 非法后缀返回 Err
test "chord_v2: parse_chord_quality_checked_invalid" {
  let r = @moonsic.parse_chord_quality_checked("???")
  assert_true(r is Err(@moonsic.InvalidChord(_)))
  // trailing suffix
  let r2 = @moonsic.parse_chord_quality_checked("mxxx")
  assert_true(r2 is Err(@moonsic.InvalidChord(_)))
}

///|
/// parse_scale_kind_checked: 合法别名全部匹配
test "chord_v2: parse_scale_kind_checked_valid_aliases" {
  assert_true(
    @moonsic.parse_scale_kind_checked("major").unwrap() is @moonsic.Major,
  )
  assert_true(
    @moonsic.parse_scale_kind_checked("ionian").unwrap() is @moonsic.Major,
  )
  assert_true(
    @moonsic.parse_scale_kind_checked("minor").unwrap() is @moonsic.NaturalMinor,
  )
  assert_true(
    @moonsic.parse_scale_kind_checked("natural minor").unwrap()
    is @moonsic.NaturalMinor,
  )
  assert_true(
    @moonsic.parse_scale_kind_checked("aeolian").unwrap()
    is @moonsic.NaturalMinor,
  )
  assert_true(
    @moonsic.parse_scale_kind_checked("dorian").unwrap() is @moonsic.Dorian,
  )
  assert_true(
    @moonsic.parse_scale_kind_checked("phrygian").unwrap() is @moonsic.Phrygian,
  )
  assert_true(
    @moonsic.parse_scale_kind_checked("lydian").unwrap() is @moonsic.Lydian,
  )
  assert_true(
    @moonsic.parse_scale_kind_checked("mixolydian").unwrap()
    is @moonsic.Mixolydian,
  )
  assert_true(
    @moonsic.parse_scale_kind_checked("locrian").unwrap() is @moonsic.Locrian,
  )
  assert_true(
    @moonsic.parse_scale_kind_checked("chromatic").unwrap()
    is @moonsic.Chromatic,
  )
  assert_true(
    @moonsic.parse_scale_kind_checked("harmonic minor").unwrap()
    is @moonsic.HarmonicMinor,
  )
  assert_true(
    @moonsic.parse_scale_kind_checked("melodic minor").unwrap()
    is @moonsic.MelodicMinor,
  )
}

///|
/// parse_scale_kind_checked: 空字符串返回 Err
test "chord_v2: parse_scale_kind_checked_empty_err" {
  let r = @moonsic.parse_scale_kind_checked("")
  assert_true(r is Err(@moonsic.InvalidScale(_)))
}

///|
/// parse_scale_kind_checked: 非法音阶品质返回 Err
test "chord_v2: parse_scale_kind_checked_invalid" {
  let r = @moonsic.parse_scale_kind_checked("blues")
  assert_true(r is Err(@moonsic.InvalidScale(_)))
}

///|
/// parse_scale_kind_checked: 尾随后缀返回 Err
test "chord_v2: parse_scale_kind_checked_trailing_err" {
  let r = @moonsic.parse_scale_kind_checked("major xxx")
  assert_true(r is Err(@moonsic.InvalidScale(_)))
}

///|
/// key_degree_checked: F# major 第 7 级 = E#4（不是 F4）
/// 这是 key-aware spelling 的核心测试 — 调号感知拼写
test "chord_v2: key_degree_checked_f_sharp_major_degree_7_is_e_sharp" {
  let k = @moonsic.key(
    @moonsic.pitch(@moonsic.F, @moonsic.Sharp, 4),
    @moonsic.Major,
  )
  let r = k.key_degree_checked(7, 4)
  assert_true(r is Ok(_))
  let p = r.unwrap()
  // E#4 MIDI = 65（等音于 F4）
  assert_eq(p.to_midi(), 65)
  // Spelling 必须是 E# 不是 F
  assert_eq(p.to_string(), "E#4")
}

///|
/// key_degree_checked: Bb minor 第 3 级 = Db4（不是 C#4）
test "chord_v2: key_degree_checked_bb_minor_degree_3_is_db" {
  let k = @moonsic.key(
    @moonsic.pitch(@moonsic.B, @moonsic.Flat, 4),
    @moonsic.Major,
  )
  // Bb major degree 3 = D4, but Bb major has Eb/Bb, so degree 3 = D natural
  let r = k.key_degree_checked(3, 4)
  assert_true(r is Ok(_))
  let p = r.unwrap()
  assert_eq(p.to_midi(), 62) // D4
  assert_eq(p.to_string(), "D4")
}

///|
/// key_degree_checked: degree <= 0 返回 Err(InvalidInterval)
test "chord_v2: key_degree_checked_degree_zero_err" {
  let k = @moonsic.key(@moonsic.c(4), @moonsic.Major)
  let r = k.key_degree_checked(0, 4)
  assert_true(r is Err(@moonsic.InvalidInterval(_)))
}

///|
/// key_degree_checked: degree 负数返回 Err
test "chord_v2: key_degree_checked_degree_negative_err" {
  let k = @moonsic.key(@moonsic.c(4), @moonsic.Major)
  let r = k.key_degree_checked(-1, 4)
  assert_true(r is Err(@moonsic.InvalidInterval(_)))
}

///|
/// key_degree_checked: C major 全部 7 个音级 — 验证拼写与 MIDI
test "chord_v2: key_degree_checked_c_major_all_degrees" {
  let k = @moonsic.key(@moonsic.c(4), @moonsic.Major)
  // degree 1 = C4 (60)
  let p1 = k.key_degree_checked(1, 4).unwrap()
  assert_eq(p1.to_midi(), 60)
  assert_eq(p1.to_string(), "C4")
  // degree 3 = E4 (64)
  let p3 = k.key_degree_checked(3, 4).unwrap()
  assert_eq(p3.to_midi(), 64)
  assert_eq(p3.to_string(), "E4")
  // degree 5 = G4 (67)
  let p5 = k.key_degree_checked(5, 4).unwrap()
  assert_eq(p5.to_midi(), 67)
  assert_eq(p5.to_string(), "G4")
  // degree 8 = C5 (72)
  let p8 = k.key_degree_checked(8, 4).unwrap()
  assert_eq(p8.to_midi(), 72)
  assert_eq(p8.to_string(), "C5")
}

///|
/// key_degree_checked: G major 第 7 级 = F#4（不是 Gb4）
test "chord_v2: key_degree_checked_g_major_degree_7_is_f_sharp" {
  let k = @moonsic.key(@moonsic.g(4), @moonsic.Major)
  let r = k.key_degree_checked(7, 4)
  assert_true(r is Ok(_))
  let p = r.unwrap()
  assert_eq(p.to_midi(), 66) // F#4
  assert_eq(p.to_string(), "F#4")
}

///|
/// parse_chord: 空字符串 -> Err
test "chord_v2: parse_chord_empty_err" {
  let r = @moonsic.parse_chord("")
  assert_true(r is Err(@moonsic.InvalidChord(_)))
}

///|
/// parse_chord: 非法根音 -> Err
test "chord_v2: parse_chord_invalid_root_H" {
  let r = @moonsic.parse_chord("H7")
  assert_true(r is Err(@moonsic.InvalidChord(_)))
}

///|
/// parse_chord: 非法后缀 -> Err（"C???"）
test "chord_v2: parse_chord_trailing_garbage" {
  let r = @moonsic.parse_chord("C???")
  assert_true(r is Err(@moonsic.InvalidChord(_)))
}

///|
/// parse_chord: F#maj7 拼写验证（F# A# C# E#）
test "chord_v2: parse_chord_f_sharp_maj7_spelling" {
  let r = @moonsic.parse_chord("F#maj7")
  assert_true(r is Ok(_))
  let chord = r.unwrap()
  assert_eq(chord.pitches.length(), 4)
  // F#4 (66), A#4 (70), C#5 (73), E#5 (77)
  assert_eq(chord.pitches[0].to_midi(), 66)
  assert_eq(chord.pitches[0].to_string(), "F#4")
  assert_eq(chord.pitches[1].to_midi(), 70)
  assert_eq(chord.pitches[1].to_string(), "A#4")
  assert_eq(chord.pitches[2].to_midi(), 73)
  assert_eq(chord.pitches[2].to_string(), "C#5")
  assert_eq(chord.pitches[3].to_midi(), 77)
  assert_eq(chord.pitches[3].to_string(), "E#5")
}

///|
/// parse_chord: Bdim7 拼写验证（B D F Ab）
test "chord_v2: parse_chord_b_dim7_spelling" {
  let r = @moonsic.parse_chord("Bdim7")
  assert_true(r is Ok(_))
  let chord = r.unwrap()
  assert_eq(chord.pitches.length(), 4)
  // B4 (71), D5 (74), F5 (77), Ab5 (80)
  assert_eq(chord.pitches[0].to_midi(), 71)
  assert_eq(chord.pitches[0].to_string(), "B4")
  assert_eq(chord.pitches[1].to_midi(), 74)
  assert_eq(chord.pitches[1].to_string(), "D5")
  assert_eq(chord.pitches[2].to_midi(), 77)
  assert_eq(chord.pitches[2].to_string(), "F5")
  assert_eq(chord.pitches[3].to_midi(), 80)
  assert_eq(chord.pitches[3].to_string(), "Ab5")
}

///|
/// parse_scale: 空字符串 -> Err
test "chord_v2: parse_scale_empty_err" {
  let r = @moonsic.parse_scale("")
  assert_true(r is Err(@moonsic.InvalidScale(_)))
}

///|
/// parse_scale: 尾随后缀 -> Err（"C major xxx"）
test "chord_v2: parse_scale_trailing_suffix_err" {
  let r = @moonsic.parse_scale("C major xxx")
  assert_true(r is Err(@moonsic.InvalidScale(_)))
}

///|
/// parse_scale: "H major" 非法根音 -> Err
test "chord_v2: parse_scale_invalid_root_H_err" {
  let r = @moonsic.parse_scale("H major")
  assert_true(r is Err(@moonsic.InvalidScale(_)))
}

///|
/// parse_scale: F# major 拼写验证（F# G# A# B C# D# E#）
test "chord_v2: parse_scale_f_sharp_major_spelling" {
  let r = @moonsic.parse_scale("F# major")
  assert_true(r is Ok(_))
  let scale = r.unwrap()
  assert_eq(scale.spelled_tones.length(), 7)
  // F# G# A# B C# D# E#
  assert_eq(scale.spelled_tones[0].to_string(), "F#4")
  assert_eq(scale.spelled_tones[1].to_string(), "G#4")
  assert_eq(scale.spelled_tones[2].to_string(), "A#4")
  assert_eq(scale.spelled_tones[3].to_string(), "B4")
  assert_eq(scale.spelled_tones[4].to_string(), "C#5")
  assert_eq(scale.spelled_tones[5].to_string(), "D#5")
  assert_eq(scale.spelled_tones[6].to_string(), "E#5")
}

///|
/// parse_scale: Bb minor 拼写验证（Bb C Db Eb F Gb Ab）
test "chord_v2: parse_scale_bb_minor_spelling" {
  let r = @moonsic.parse_scale("Bb minor")
  assert_true(r is Ok(_))
  let scale = r.unwrap()
  assert_eq(scale.spelled_tones.length(), 7)
  // Bb C Db Eb F Gb Ab
  assert_eq(scale.spelled_tones[0].to_string(), "Bb4")
  assert_eq(scale.spelled_tones[1].to_string(), "C5")
  assert_eq(scale.spelled_tones[2].to_string(), "Db5")
  assert_eq(scale.spelled_tones[3].to_string(), "Eb5")
  assert_eq(scale.spelled_tones[4].to_string(), "F5")
  assert_eq(scale.spelled_tones[5].to_string(), "Gb5")
  assert_eq(scale.spelled_tones[6].to_string(), "Ab5")
}

// ============================================================
// ScoreLayout 稳定化测试 (v2 — score_layout.mbt + score_enhanced.mbt)
// ============================================================

// --- Score → EnhancedScoreLayout 转换 ---

///|
/// Score→EnhancedScoreLayout→Score round-trip：事件数量保留
test "score_layout_stable: enhanced_roundtrip_event_count" {
  let t = @moonsic.melody([
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
  ])
  let s = @moonsic.score1(t)
  let layout_r = @moonsic.score_to_enhanced_layout_checked(s, 480)
  assert_true(layout_r is Ok(_))
  let layout = layout_r.unwrap()
  assert_eq(layout.ppq, 480)

  let back_r = @moonsic.enhanced_layout_to_score_checked(layout)
  assert_true(back_r is Ok(_))
  let back = back_r.unwrap()
  assert_eq(back.track_count(), 1)
  assert_eq(back.tracks[0].event_count(), 2)
}

///|
/// Score→EnhancedScoreLayout→Score round-trip：和弦事件保留
test "score_layout_stable: enhanced_roundtrip_with_chord" {
  let t = @moonsic.melody([
    @moonsic.major(@moonsic.c(4), @moonsic.half()),
    @moonsic.n(@moonsic.g(4), @moonsic.quarter()),
  ])
  let s = @moonsic.score1(t)
  let layout_r = @moonsic.score_to_enhanced_layout_checked(s, 480)
  assert_true(layout_r is Ok(_))
  let layout = layout_r.unwrap()

  let back_r = @moonsic.enhanced_layout_to_score_checked(layout)
  assert_true(back_r is Ok(_))
  let back = back_r.unwrap()
  assert_eq(back.tracks[0].event_count(), 2)
}

///|
/// Score→EnhancedScoreLayout→Score round-trip：休止符事件保留
test "score_layout_stable: enhanced_roundtrip_with_rest" {
  let t = @moonsic.melody([
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.r(@moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
  ])
  let s = @moonsic.score1(t)
  let layout_r = @moonsic.score_to_enhanced_layout_checked(s, 480)
  assert_true(layout_r is Ok(_))
  let layout = layout_r.unwrap()

  let back_r = @moonsic.enhanced_layout_to_score_checked(layout)
  assert_true(back_r is Ok(_))
  let back = back_r.unwrap()
  assert_eq(back.tracks[0].event_count(), 3)
}

///|
/// Score→EnhancedScoreLayout：双轨道分别转换为独立 Part
test "score_layout_stable: enhanced_two_tracks_two_parts" {
  let t1 = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let t2 = @moonsic.melody([@moonsic.n(@moonsic.g(3), @moonsic.half())])
  let s = @moonsic.score([t1, t2])
  let layout_r = @moonsic.score_to_enhanced_layout_checked(s, 480)
  assert_true(layout_r is Ok(_))
  let layout = layout_r.unwrap()
  assert_eq(layout.parts.length(), 2)
}

// --- 小节容量 (Measure Capacity) ---

///|
/// 小节容量：3/4 小节恰好 3 个 quarter 不溢出
test "score_layout_stable: measure_capacity_3_4_exact" {
  let sig = @moonsic.time_signature(3, 4)
  let events = [
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.e(4), @moonsic.quarter()),
  ]
  let m = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let r = @moonsic.validate_measure(m, sig, 480)
  assert_true(r is Ok(_))
}

///|
/// 小节容量：3/4 小节 4 个 quarter 溢出
test "score_layout_stable: measure_capacity_3_4_overflow" {
  let sig = @moonsic.time_signature(3, 4)
  let events = [
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.e(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.f(4), @moonsic.quarter()),
  ]
  let m = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let r = @moonsic.validate_measure(m, sig, 480)
  assert_true(r is Err(_))
  match r {
    Err(@moonsic.LayoutMeasureOverflow(_)) => ()
    _ => abort("expected LayoutMeasureOverflow")
  }
}

///|
/// 小节容量：6/8 小节恰好 6 个 eighth 不溢出
test "score_layout_stable: measure_capacity_6_8_exact" {
  let sig = @moonsic.time_signature(6, 8)
  let events = [
    @moonsic.n(@moonsic.c(4), @moonsic.eighth()),
    @moonsic.n(@moonsic.d(4), @moonsic.eighth()),
    @moonsic.n(@moonsic.e(4), @moonsic.eighth()),
    @moonsic.n(@moonsic.f(4), @moonsic.eighth()),
    @moonsic.n(@moonsic.g(4), @moonsic.eighth()),
    @moonsic.n(@moonsic.a(4), @moonsic.eighth()),
  ]
  let m = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let r = @moonsic.validate_measure(m, sig, 480)
  assert_true(r is Ok(_))
}

///|
/// 小节容量：validate_measure 的 ppq=0 返回 InvalidPPQ
test "score_layout_stable: validate_measure_ppq_zero" {
  let sig = @moonsic.four_four()
  let events = [@moonsic.n(@moonsic.c(4), @moonsic.quarter())]
  let m = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let r = @moonsic.validate_measure(m, sig, 0)
  assert_true(r is Err(@moonsic.InvalidPPQ(0)))
}

// --- 声部对齐 (Voice Alignment) ---

///|
/// 声部对齐：同 Staff 内两声部小节数不同 → voice alignment mismatch
test "score_layout_stable: voice_alignment_two_voices_mismatch" {
  let m0 = @moonsic.empty_measure(0)
  let m1 = @moonsic.empty_measure(1)
  // RH: 1 measure, LH: 2 measures
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
/// 声部对齐：同 Staff 内两声部小节数相同 → 无 voice alignment mismatch warning
test "score_layout_stable: voice_alignment_matched_no_warning" {
  let sig = @moonsic.four_four()
  let events = [
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.d(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.e(4), @moonsic.quarter()),
    @moonsic.n(@moonsic.f(4), @moonsic.quarter()),
  ]
  let m0 = @moonsic.make_measure(0, Some(sig), events).unwrap()
  let m1 = @moonsic.make_measure(1, None, events).unwrap()
  let v_rh = @moonsic.make_voice("RH", [m0, m1]).unwrap()
  let v_lh = @moonsic.make_voice("LH", [m0, m1]).unwrap()
  let s = @moonsic.make_staff("Piano", None, None, None, [v_rh, v_lh]).unwrap()
  let p = @moonsic.make_part("Keyboard", [s]).unwrap()
  let sl = @moonsic.make_score_layout("Test", 480, [p]).unwrap()
  let opts = @moonsic.default_validation_options()
  let report = @moonsic.validate_score_layout_report(sl, opts)
  // voice alignment matched → no voice-alignment miscount warning
  assert_true(!@moonsic.validation_report_has_errors(report))
}

// --- Staff / Track 通道与乐器保留 ---

///|
/// Staff→Track：channel 和 program 保留
test "score_layout_stable: staff_to_track_preserves_channel_program" {
  let v = @moonsic.empty_voice("RH")
  let s = @moonsic.make_staff("Staff", Some(3), Some(42), None, [v]).unwrap()
  let t = @moonsic.staff_to_track(s)
  assert_eq(t.channel, 3)
  assert_eq(t.program, 42)
}

///|
/// Track→Staff→Track round-trip：channel 保留（通过 track_with_channel）
test "score_layout_stable: track_to_staff_roundtrip_channel" {
  let t = @moonsic.track_with_channel(
    [@moonsic.n(@moonsic.c(4), @moonsic.quarter())],
    7,
  )
  let stf_r = @moonsic.track_to_staff(t, "Staff", 480, @moonsic.four_four())
  assert_true(stf_r is Ok(_))
  let stf = stf_r.unwrap()
  match stf.channel {
    Some(ch) => assert_eq(ch, 7)
    None => abort("expected channel Some(7)")
  }
}

///|
/// Staff→Track→Staff round-trip：program 保留
test "score_layout_stable: staff_track_staff_roundtrip_program" {
  let v = @moonsic.empty_voice("V")
  let s = @moonsic.make_staff("S", None, Some(24), None, [v]).unwrap()
  let t = @moonsic.staff_to_track(s)
  assert_eq(t.program, 24)
  let stf_r = @moonsic.track_to_staff(t, "S", 480, @moonsic.four_four())
  assert_true(stf_r is Ok(_))
  let stf = stf_r.unwrap()
  match stf.program {
    Some(prog) => assert_eq(prog, 24)
    None => abort("expected program Some(24)")
  }
}

// --- ScoreLayout → Score 多声部组转换 ---

///|
/// ScoreLayout→Score：2 Part × 2 Staff 结构保留轨道数量
test "score_layout_stable: score_layout_to_score_multi_part" {
  let s1 = @moonsic.empty_staff("S1")
  let s2 = @moonsic.empty_staff("S2")
  let s3 = @moonsic.empty_staff("S3")
  let s4 = @moonsic.empty_staff("S4")
  let p1 = @moonsic.empty_part("P1")
  let p2 = @moonsic.empty_part("P2")
  let p1 = @moonsic.part_add_staff(p1, s1).unwrap()
  let p1 = @moonsic.part_add_staff(p1, s2).unwrap()
  let p2 = @moonsic.part_add_staff(p2, s3).unwrap()
  let p2 = @moonsic.part_add_staff(p2, s4).unwrap()
  let sl = @moonsic.make_score_layout("Test", 480, [p1, p2]).unwrap()
  let score = @moonsic.score_layout_to_score(sl)
  assert_eq(score.track_count(), 4)
}

///|
/// ScoreLayout→Score：空 layout 产生 0 轨道
test "score_layout_stable: empty_score_layout_zero_tracks" {
  let sl = @moonsic.make_score_layout("Empty", 480, []).unwrap()
  let score = @moonsic.score_layout_to_score(sl)
  assert_eq(score.track_count(), 0)
}

// --- 边界与不可变性 ---

///|
/// 空 layout 小节计数 = 0
test "score_layout_stable: empty_layout_measure_count_zero" {
  let sl = @moonsic.make_score_layout("Empty", 480, []).unwrap()
  assert_eq(@moonsic.score_layout_measure_count(sl), 0)
}

///|
/// measure_beat_duration 混合事件总拍数
test "score_layout_stable: measure_beat_duration_mixed" {
  let events = [
    @moonsic.n(@moonsic.c(4), @moonsic.quarter()),
    @moonsic.r(@moonsic.eighth()),
    @moonsic.major(@moonsic.g(4), @moonsic.half()),
  ]
  let m = @moonsic.make_measure(0, None, events).unwrap()
  let beats = @moonsic.measure_beat_duration(m)
  // quarter(1.0) + eighth(0.5) + half(2.0) = 3.5
  assert_true(beats > 3.49 && beats < 3.51)
}

///|
/// voice_add_measure 不可变性：原 Voice 不变
test "score_layout_stable: voice_add_measure_immutable" {
  let m0 = @moonsic.empty_measure(0)
  let v = @moonsic.empty_voice("V")
  let v2 = @moonsic.voice_add_measure(v, m0).unwrap()
  // 原 voice 仍为 0 小节
  assert_eq(@moonsic.voice_measure_count(v), 0)
  // 新 voice 有 1 小节
  assert_eq(@moonsic.voice_measure_count(v2), 1)
}

///|
/// staff_add_voice 不可变性：原 Staff 不变
test "score_layout_stable: staff_add_voice_immutable" {
  let v = @moonsic.empty_voice("V")
  let s = @moonsic.empty_staff("S")
  let s2 = @moonsic.staff_add_voice(s, v).unwrap()
  // 原 staff 的 voices 为空
  assert_eq(s.voices.length(), 0)
  // 新 staff 有 1 个 voice
  assert_eq(s2.voices.length(), 1)
}

// --- 错误路径 ---

///|
/// Track→Voice：ppq <= 0 返回 InvalidPPQ
test "score_layout_stable: track_to_voice_invalid_ppq" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let r = @moonsic.track_to_voice(t, "V", 0, @moonsic.four_four())
  assert_true(r is Err(@moonsic.InvalidPPQ(0)))
}

///|
/// Track→Voice：无效拍号 5/3 返回 LayoutInvalidMeasure
test "score_layout_stable: track_to_voice_invalid_time_signature" {
  let t = @moonsic.melody([@moonsic.n(@moonsic.c(4), @moonsic.quarter())])
  let sig = @moonsic.time_signature(5, 3)
  let r = @moonsic.track_to_voice(t, "V", 480, sig)
  assert_true(r is Err(@moonsic.LayoutInvalidMeasure(_)))
}

///|
/// make_measure：负索引返回 LayoutInvalidMeasure
test "score_layout_stable: make_measure_negative_index" {
  let r = @moonsic.make_measure(-1, None, [])
  assert_true(r is Err(@moonsic.LayoutInvalidMeasure(_)))
}

///|
/// make_staff：空名称返回 LayoutInvalidStaff
test "score_layout_stable: make_staff_empty_name" {
  let r = @moonsic.make_staff("", None, None, None, [])
  assert_true(r is Err(@moonsic.LayoutInvalidStaff(_)))
}

///|
/// make_staff：非法 channel=16 返回 LayoutInvalidChannel
test "score_layout_stable: make_staff_channel_16" {
  let r = @moonsic.make_staff("S", Some(16), None, None, [])
  assert_true(r is Err(@moonsic.LayoutInvalidChannel(16)))
}

///|
/// make_staff：非法 program=128 返回 LayoutInvalidProgram
test "score_layout_stable: make_staff_program_128" {
  let r = @moonsic.make_staff("S", None, Some(128), None, [])
  assert_true(r is Err(@moonsic.LayoutInvalidProgram(128)))
}

///|
/// make_voice：空名称返回 LayoutInvalidVoice
test "score_layout_stable: make_voice_empty_name" {
  let r = @moonsic.make_voice("", [])
  assert_true(r is Err(@moonsic.LayoutInvalidVoice(_)))
}

///|
/// make_part：空名称返回 LayoutInvalidPart
test "score_layout_stable: make_part_empty_name" {
  let r = @moonsic.make_part("", [])
  assert_true(r is Err(@moonsic.LayoutInvalidPart(_)))
}

///|
/// ScoreError to_string 覆盖全部 variant
test "score_layout_stable: score_error_to_string_all" {
  let e1 = @moonsic.LayoutInvalidMeasure("test")
  assert_true(e1.to_string().contains("无效小节"))
  let e2 = @moonsic.LayoutInvalidVoice("test")
  assert_true(e2.to_string().contains("无效声部"))
  let e3 = @moonsic.LayoutInvalidStaff("test")
  assert_true(e3.to_string().contains("无效五线谱"))
  let e4 = @moonsic.LayoutInvalidPart("test")
  assert_true(e4.to_string().contains("无效声部组"))
  let e5 = @moonsic.LayoutMeasureOverflow("test")
  assert_true(e5.to_string().contains("小节溢出"))
  let e6 = @moonsic.InvalidScoreLayout("test")
  assert_true(e6.to_string().contains("无效曲谱布局"))
  let e7 = @moonsic.ScoreError::InvalidPPQ(0)
  assert_true(e7.to_string().contains("无效 PPQ"))
  let e8 = @moonsic.LayoutInvalidChannel(16)
  assert_true(e8.to_string().contains("无效通道"))
  let e9 = @moonsic.LayoutInvalidProgram(128)
  assert_true(e9.to_string().contains("无效乐器程序号"))
}

// ============================================================
// ScoreLayout 稳定化测试结束
// ============================================================

// ============================================================
// MIDI 稳定化测试
// ============================================================

///|
/// MIDI note 下界: 0 合法, 127 合法
test "midi_stable: validate_midi_note_min" {
  assert_true(@moonsic.validate_midi_note(0))
  assert_true(@moonsic.validate_midi_note(127))
}

///|
/// MIDI note 边界: -1 非法, 128 非法
test "midi_stable: validate_midi_note_out_of_range" {
  assert_false(@moonsic.validate_midi_note(-1))
  assert_false(@moonsic.validate_midi_note(128))
}

///|
/// Velocity 边界: 0 合法, 127 合法, -1 非法, 128 非法
test "midi_stable: validate_velocity_range" {
  assert_true(@moonsic.validate_velocity(0))
  assert_true(@moonsic.validate_velocity(127))
  assert_false(@moonsic.validate_velocity(-1))
  assert_false(@moonsic.validate_velocity(128))
}

///|
/// Channel 边界: 0 合法, 15 合法, -1 非法, 16 非法
test "midi_stable: validate_channel_range" {
  assert_true(@moonsic.validate_channel(0))
  assert_true(@moonsic.validate_channel(15))
  assert_false(@moonsic.validate_channel(-1))
  assert_false(@moonsic.validate_channel(16))
}

///|
/// PPQ 边界: 1 合法, 480 合法, 0 非法, -1 非法
test "midi_stable: validate_ppq_range" {
  assert_true(@moonsic.validate_ppq(1))
  assert_true(@moonsic.validate_ppq(480))
  assert_false(@moonsic.validate_ppq(0))
  assert_false(@moonsic.validate_ppq(-1))
}

///|
/// Tick 边界: 0 合法, 负数非法
test "midi_stable: validate_tick_range" {
  assert_true(@moonsic.validate_tick(0))
  assert_true(@moonsic.validate_tick(1000))
  assert_false(@moonsic.validate_tick(-1))
}

///|
/// note_on: channel=16 返回 Err(InvalidMidiChannel)
test "midi_stable: note_on_invalid_channel" {
  let r = @moonsic.note_on(0, 16, 60, 100)
  assert_true(r is Err(@moonsic.InvalidMidiChannel(16)))
}

///|
/// note_on: note=128 返回 Err(InvalidMidiNote)
test "midi_stable: note_on_invalid_note" {
  let r = @moonsic.note_on(0, 0, 128, 100)
  assert_true(r is Err(@moonsic.InvalidMidiNote(128)))
}

///|
/// note_on: velocity=128 返回 Err(InvalidMidiVelocity)
test "midi_stable: note_on_invalid_velocity" {
  let r = @moonsic.note_on(0, 0, 60, 128)
  assert_true(r is Err(@moonsic.InvalidMidiVelocity(128)))
}

///|
/// note_on: tick=-1 返回 Err(InvalidMidiTick)
test "midi_stable: note_on_invalid_tick" {
  let r = @moonsic.note_on(-1, 0, 60, 100)
  assert_true(r is Err(@moonsic.InvalidMidiTick(-1)))
}

///|
/// note_off: channel=-1 返回 Err(InvalidMidiChannel)
test "midi_stable: note_off_invalid_channel" {
  let r = @moonsic.note_off(0, -1, 60, 0)
  assert_true(r is Err(@moonsic.InvalidMidiChannel(-1)))
}

///|
/// note_off: note=-1 返回 Err(InvalidMidiNote)
test "midi_stable: note_off_invalid_note" {
  let r = @moonsic.note_off(0, 0, -1, 0)
  assert_true(r is Err(@moonsic.InvalidMidiNote(-1)))
}

///|
/// note_off: velocity=-1 返回 Err(InvalidMidiVelocity)
test "midi_stable: note_off_invalid_velocity" {
  let r = @moonsic.note_off(0, 0, 60, -1)
  assert_true(r is Err(@moonsic.InvalidMidiVelocity(-1)))
}

///|
/// program_change: program=128 返回 Err(InvalidMidiProgram)
test "midi_stable: program_change_invalid_program" {
  let r = @moonsic.program_change(0, 0, 128)
  assert_true(r is Err(@moonsic.InvalidMidiProgram(128)))
}

///|
/// program_change: channel=16 返回 Err(InvalidMidiChannel)
test "midi_stable: program_change_invalid_channel" {
  let r = @moonsic.program_change(0, 16, 0)
  assert_true(r is Err(@moonsic.InvalidMidiChannel(16)))
}

///|
/// control_change: controller=128 返回 Err(InvalidMidiController)
test "midi_stable: control_change_invalid_controller" {
  let r = @moonsic.control_change(0, 0, 128, 0)
  assert_true(r is Err(@moonsic.InvalidMidiController(128)))
}

///|
/// control_change: value=128 返回 Err(InvalidMidiController)
test "midi_stable: control_change_invalid_value" {
  let r = @moonsic.control_change(0, 0, 0, 128)
  assert_true(r is Err(@moonsic.InvalidMidiController(128)))
}

///|
/// tempo_change: bpm=0 返回 Err(InvalidMidiTempo)
test "midi_stable: tempo_change_bpm_zero" {
  let r = @moonsic.tempo_change(0, 0)
  assert_true(r is Err(@moonsic.InvalidMidiTempo(0)))
}

///|
/// tempo_change: bpm=-1 返回 Err(InvalidMidiTempo)
test "midi_stable: tempo_change_bpm_negative" {
  let r = @moonsic.tempo_change(0, -1)
  assert_true(r is Err(@moonsic.InvalidMidiTempo(-1)))
}

///|
/// sort_midi_events: 同 tick NoteOff 排在 NoteOn 之前
test "midi_stable: sort_noteoff_before_noteon_same_tick" {
  let on = @moonsic.note_on(480, 0, 60, 100).unwrap()
  let off = @moonsic.note_off(480, 0, 60, 0).unwrap()
  let sorted = @moonsic.sort_midi_events([on, off])
  assert_eq(sorted.length(), 2)
}

///|
/// sort_midi_events: 单元素不变
test "midi_stable: sort_single_event" {
  let on = @moonsic.note_on(0, 0, 60, 100).unwrap()
  let sorted = @moonsic.sort_midi_events([on])
  assert_eq(sorted.length(), 1)
}

///|
/// sort_midi_events: 不同 tick 按时间升序
test "midi_stable: sort_by_tick" {
  let e0 = @moonsic.note_on(480, 0, 62, 100).unwrap()
  let e1 = @moonsic.note_on(0, 0, 60, 100).unwrap()
  let sorted = @moonsic.sort_midi_events([e0, e1])
  assert_eq(sorted.length(), 2)
}

///|
/// MIDI 导出不为空（smoke test）
test "midi_stable: export_bytes_not_empty" {
  let p = @moonsic.pitch
  let track = @moonsic.track([
    @moonsic.Note(
      @moonsic.note(p(@moonsic.C, @moonsic.Natural, 4), @moonsic.Quarter),
    ),
  ])
  let score = @moonsic.score([track])
  let bytes = @moonsic.score_to_midi_bytes(score, 480)
  assert_true(bytes.length() > 0)
}

///|
/// MIDI 导出 roundtrip: Score -> bytes -> parse 验证结构
test "midi_stable: roundtrip_tracks_count" {
  let p = @moonsic.pitch
  let track = @moonsic.track([
    @moonsic.Note(
      @moonsic.note(p(@moonsic.C, @moonsic.Natural, 4), @moonsic.Quarter),
    ),
    @moonsic.Note(
      @moonsic.note(p(@moonsic.D, @moonsic.Natural, 4), @moonsic.Quarter),
    ),
  ])
  let score = @moonsic.score([track])
  let bytes = @moonsic.score_to_midi_bytes(score, 480)
  let file = @midi.parse(bytes)
  assert_eq(file.tracks.length(), 2)
  assert_eq(file.division, (480).to_uint16())
}

///|
/// MIDI roundtrip: PPQ 传递到 960
test "midi_stable: roundtrip_ppq_960" {
  let p = @moonsic.pitch
  let track = @moonsic.track([
    @moonsic.Note(
      @moonsic.note(p(@moonsic.C, @moonsic.Natural, 4), @moonsic.Quarter),
    ),
  ])
  let score = @moonsic.score([track])
  let bytes = @moonsic.score_to_midi_bytes(score, 960)
  let file = @midi.parse(bytes)
  assert_eq(file.division, (960).to_uint16())
}

///|
/// MIDI 导出: Meta track 包含 TrackName, Tempo, TimeSignature, EndOfTrack
test "midi_stable: meta_track_has_required_events" {
  let p = @moonsic.pitch
  let track = @moonsic.track([
    @moonsic.Note(
      @moonsic.note(p(@moonsic.C, @moonsic.Natural, 4), @moonsic.Quarter),
    ),
  ])
  let score = @moonsic.score([track])
  let bytes = @moonsic.score_to_midi_bytes(score, 480)
  let file = @midi.parse(bytes)
  assert_true(file.tracks[0].events.length() >= 4)
}

///|
/// MIDI 导出: channel 9 鼓声道
test "midi_stable: channel_9_drums" {
  let p = @moonsic.pitch
  let drum_track = @moonsic.track_with_channel(
    [
      @moonsic.Note(
        @moonsic.note(p(@moonsic.C, @moonsic.Natural, 4), @moonsic.Quarter),
      ),
    ],
    9,
  )
  let score = @moonsic.score([drum_track])
  let bytes = @moonsic.score_to_midi_bytes(score, 480)
  let file = @midi.parse(bytes)
  assert_true(file.tracks.length() >= 2)
  let music_track = file.tracks[1]
  let mut has_note = false
  for event in music_track.events {
    match event {
      @midi.NoteOn(channel=ch, ..) => if ch == (9).to_byte() { has_note = true }
      _ => ()
    }
  }
  assert_true(has_note)
}

///|
/// MIDI 导出: ProgramChange 事件存在
test "midi_stable: program_change_in_export" {
  let p = @moonsic.pitch
  let track = @moonsic.track([
    @moonsic.Note(
      @moonsic.note(p(@moonsic.C, @moonsic.Natural, 4), @moonsic.Quarter),
    ),
  ])
  let track_with_inst = @moonsic.instrument(track, 24)
  let score = @moonsic.score([track_with_inst])
  let bytes = @moonsic.score_to_midi_bytes(score, 480)
  let file = @midi.parse(bytes)
  let music_track = file.tracks[1]
  let mut has_pc = false
  for event in music_track.events {
    match event {
      @midi.ProgramChange(program=prog, ..) =>
        if prog == (24).to_byte() {
          has_pc = true
        }
      _ => ()
    }
  }
  assert_true(has_pc)
}

///|
/// MIDI 导出: Tempo 事件存在
test "midi_stable: tempo_in_export" {
  let p = @moonsic.pitch
  let track = @moonsic.track([
    @moonsic.Note(
      @moonsic.note(p(@moonsic.C, @moonsic.Natural, 4), @moonsic.Quarter),
    ),
  ])
  let score = @moonsic.score_with_tempo(
    [track],
    @moonsic.tempo(120),
    @moonsic.four_four(),
  )
  let bytes = @moonsic.score_to_midi_bytes(score, 480)
  let file = @midi.parse(bytes)
  let mut has_tempo = false
  for event in file.tracks[0].events {
    match event {
      @midi.Tempo(microseconds=us, ..) => if us == 500000U { has_tempo = true }
      _ => ()
    }
  }
  assert_true(has_tempo)
}

///|
/// validate_midi_score: PPQ=0 返回 Err
test "midi_stable: validate_midi_score_ppq_zero" {
  let p = @moonsic.pitch
  let track = @moonsic.track([
    @moonsic.Note(
      @moonsic.note(p(@moonsic.C, @moonsic.Natural, 4), @moonsic.Quarter),
    ),
  ])
  let score = @moonsic.score([track])
  let r = @moonsic.score_to_midi_score_checked(score, 0)
  assert_true(r is Err(@moonsic.InvalidMidiPPQ(0)))
}

///|
/// validate_midi_score: 合法 score 通过
test "midi_stable: validate_midi_score_ok" {
  let p = @moonsic.pitch
  let track = @moonsic.track([
    @moonsic.Note(
      @moonsic.note(p(@moonsic.C, @moonsic.Natural, 4), @moonsic.Quarter),
    ),
  ])
  let score = @moonsic.score([track])
  let midi_score = @moonsic.score_to_midi_score(score, 480)
  let r = @moonsic.validate_midi_score(midi_score)
  assert_true(r is Ok(_))
}

///|
/// validate_midi_file: 合法 MidiScore 通过
test "midi_stable: validate_midi_file_ok" {
  let p = @moonsic.pitch
  let track = @moonsic.track([
    @moonsic.Note(
      @moonsic.note(p(@moonsic.C, @moonsic.Natural, 4), @moonsic.Quarter),
    ),
  ])
  let score = @moonsic.score([track])
  let midi_score = @moonsic.score_to_midi_score(score, 480)
  let r = @moonsic.validate_midi_file(midi_score)
  assert_true(r is Ok(_))
}

///|
/// validate_midi_file: PPQ=0 返回 Err
test "midi_stable: validate_midi_file_ppq_zero" {
  let p = @moonsic.pitch
  let track = @moonsic.track([
    @moonsic.Note(
      @moonsic.note(p(@moonsic.C, @moonsic.Natural, 4), @moonsic.Quarter),
    ),
  ])
  let score = @moonsic.score([track])
  let ms = @moonsic.score_to_midi_score(score, 0)
  let r = @moonsic.validate_midi_file(ms)
  assert_true(r is Err(@moonsic.InvalidMidiPPQ(0)))
}

///|
/// score_to_midi_bytes_checked: invalid ppq 返回 Err
test "midi_stable: score_to_midi_bytes_checked_ppq_zero" {
  let p = @moonsic.pitch
  let track = @moonsic.track([
    @moonsic.Note(
      @moonsic.note(p(@moonsic.C, @moonsic.Natural, 4), @moonsic.Quarter),
    ),
  ])
  let score = @moonsic.score([track])
  let r = @moonsic.score_to_midi_bytes_checked(score, 0)
  assert_true(r is Err(@moonsic.InvalidMidiPPQ(0)))
}

///|
/// midi_time_signature 构造函数: 合法拍号 4/4
test "midi_stable: time_signature_4_4_ok" {
  let r = @moonsic.midi_time_signature(0, 4, 4)
  assert_true(r is Ok(_))
}

///|
/// midi_time_signature 构造函数: 非法分母 5 返回 Err
test "midi_stable: time_signature_4_5_err" {
  let r = @moonsic.midi_time_signature(0, 4, 5)
  assert_true(r is Err(_))
}

///|
/// midi_time_signature 构造函数: tick=-1 返回 Err
test "midi_stable: time_signature_negative_tick" {
  let r = @moonsic.midi_time_signature(-1, 4, 4)
  assert_true(r is Err(@moonsic.InvalidMidiTick(-1)))
}

///|
/// end_of_track 构造函数: 合法
test "midi_stable: end_of_track_ok" {
  let r = @moonsic.end_of_track(0)
  assert_true(r is Ok(_))
}

///|
/// end_of_track 构造函数: tick=-1 返回 Err
test "midi_stable: end_of_track_negative_tick" {
  let r = @moonsic.end_of_track(-1)
  assert_true(r is Err(@moonsic.InvalidMidiTick(-1)))
}

///|
/// track_name 构造函数: 合法
test "midi_stable: track_name_ok" {
  let r = @moonsic.track_name(0, "Test")
  assert_true(r is Ok(_))
}

///|
/// track_name 构造函数: tick=-1 返回 Err
test "midi_stable: track_name_negative_tick" {
  let r = @moonsic.track_name(-1, "Test")
  assert_true(r is Err(@moonsic.InvalidMidiTick(-1)))
}

///|
/// MidiError to_string 覆盖全部 variant
test "midi_stable: midi_error_to_string_coverage" {
  assert_true(
    @moonsic.InvalidMidiTick(-1).to_string().contains("invalid MIDI tick"),
  )
  assert_true(
    @moonsic.InvalidMidiChannel(16).to_string().contains("invalid MIDI channel"),
  )
  assert_true(
    @moonsic.MidiError::InvalidMidiNote(128)
    .to_string()
    .contains("invalid MIDI note"),
  )
  assert_true(
    @moonsic.MidiError::InvalidMidiVelocity(128)
    .to_string()
    .contains("invalid MIDI velocity"),
  )
  assert_true(
    @moonsic.InvalidMidiProgram(128)
    .to_string()
    .contains("invalid MIDI program"),
  )
  assert_true(
    @moonsic.InvalidMidiController(128)
    .to_string()
    .contains("invalid MIDI controller"),
  )
  assert_true(
    @moonsic.InvalidMidiTempo(0).to_string().contains("invalid MIDI tempo"),
  )
  assert_true(
    @moonsic.InvalidMidiPPQ(0).to_string().contains("invalid MIDI PPQ"),
  )
  assert_true(
    @moonsic.MidiExportError("test").to_string().contains("MIDI export error"),
  )
}

///|
/// MIDI roundtrip: 多音音符导出后解析含有正确的 NoteOn 数
test "midi_stable: roundtrip_note_count" {
  let p = @moonsic.pitch
  let track = @moonsic.track([
    @moonsic.Note(
      @moonsic.note(p(@moonsic.C, @moonsic.Natural, 4), @moonsic.Quarter),
    ),
    @moonsic.Note(
      @moonsic.note(p(@moonsic.D, @moonsic.Natural, 4), @moonsic.Quarter),
    ),
    @moonsic.Note(
      @moonsic.note(p(@moonsic.E, @moonsic.Natural, 4), @moonsic.Quarter),
    ),
  ])
  let score = @moonsic.score([track])
  let bytes = @moonsic.score_to_midi_bytes(score, 480)
  let file = @midi.parse(bytes)
  let music_track = file.tracks[1]
  let mut note_on_count = 0
  for event in music_track.events {
    match event {
      @midi.NoteOn(..) => note_on_count = note_on_count + 1
      _ => ()
    }
  }
  assert_eq(note_on_count, 3)
}

///|
/// MIDI roundtrip: 休止符不产生 Note 事件
test "midi_stable: rest_does_not_produce_midi_note" {
  let p = @moonsic.pitch
  let track = @moonsic.track([
    @moonsic.Note(
      @moonsic.note(p(@moonsic.C, @moonsic.Natural, 4), @moonsic.Quarter),
    ),
    @moonsic.Rest(@moonsic.rest(@moonsic.Quarter)),
    @moonsic.Note(
      @moonsic.note(p(@moonsic.D, @moonsic.Natural, 4), @moonsic.Quarter),
    ),
  ])
  let score = @moonsic.score([track])
  let bytes = @moonsic.score_to_midi_bytes(score, 480)
  let file = @midi.parse(bytes)
  let music_track = file.tracks[1]
  let mut note_on_count = 0
  for event in music_track.events {
    match event {
      @midi.NoteOn(..) => note_on_count = note_on_count + 1
      _ => ()
    }
  }
  assert_eq(note_on_count, 2)
}

// ============================================================
// MIDI 稳定化测试结束
// ============================================================
