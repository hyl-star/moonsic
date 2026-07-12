// ============================================================
// v2 musicxml 包测试 (blackbox)
// ============================================================

///|
fn make_simple_score() -> @score.SimpleScore {
  let dur = @time.rhythm_duration(@time.DurQuarter, 0, None)
  let vel = @score.velocity_checked(100).unwrap()
  let evts = [
    @score.simple_note_checked(@pitch.c(4), dur, Some(vel)).unwrap(),
    @score.simple_note_checked(@pitch.d(4), dur, Some(vel)).unwrap(),
    @score.simple_note_checked(@pitch.e(4), dur, Some(vel)).unwrap(),
    @score.simple_note_checked(@pitch.f(4), dur, Some(vel)).unwrap(),
  ]
  let ch = @score.midi_channel_checked(0).unwrap()
  let track = @score.simple_track_checked(evts, Some(ch), None).unwrap()
  let tempo = @score.tempo_checked(120).unwrap()
  let sig = @time.time_signature(4, 4)
  @score.simple_score_checked([track], tempo, sig).unwrap()
}

///|
test "convert_basic" {
  let score = make_simple_score()
  let opts = @musicxml.default_musicxml_export_options()
  assert_true(@musicxml.simple_score_to_musicxml_checked(score, opts) is Ok(_))
}

///|
test "convert_bad_divisions" {
  let score = make_simple_score()
  let opts = @musicxml.MusicXmlExportOptions::{
    divisions: 0,
    include_xml_header: false,
    include_doctype: false,
    part_name_fallback: "X",
  }
  assert_true(@musicxml.simple_score_to_musicxml_checked(score, opts) is Err(_))
}

///|
test "xml_output_contains_partwise" {
  let score = make_simple_score()
  let opts = @musicxml.default_musicxml_export_options()
  let doc = @musicxml.simple_score_to_musicxml_checked(score, opts).unwrap()
  let xml = @musicxml.musicxml_score_to_string(doc, opts)
  assert_true(xml.contains("score-partwise"))
}

///|
test "xml_output_has_xml_header" {
  let score = make_simple_score()
  let opts = @musicxml.default_musicxml_export_options()
  let doc = @musicxml.simple_score_to_musicxml_checked(score, opts).unwrap()
  let xml = @musicxml.musicxml_score_to_string(doc, opts)
  assert_true(xml.contains("<?xml"))
}

///|
test "xml_output_no_header" {
  let score = make_simple_score()
  let opts = @musicxml.MusicXmlExportOptions::{
    divisions: 480,
    include_xml_header: false,
    include_doctype: false,
    part_name_fallback: "I",
  }
  let doc = @musicxml.simple_score_to_musicxml_checked(score, opts).unwrap()
  let xml = @musicxml.musicxml_score_to_string(doc, opts)
  assert_false(xml.contains("<?xml"))
}

///|
test "xml_contains_measure" {
  let score = make_simple_score()
  let opts = @musicxml.default_musicxml_export_options()
  let doc = @musicxml.simple_score_to_musicxml_checked(score, opts).unwrap()
  let xml = @musicxml.musicxml_score_to_string(doc, opts)
  assert_true(xml.contains("<measure"))
}

///|
test "xml_contains_note_elements" {
  let score = make_simple_score()
  let opts = @musicxml.default_musicxml_export_options()
  let doc = @musicxml.simple_score_to_musicxml_checked(score, opts).unwrap()
  let xml = @musicxml.musicxml_score_to_string(doc, opts)
  assert_true(xml.contains("<step>C</step>"))
}

///|
test "chord_export" {
  let dur = @time.rhythm_duration(@time.DurHalf, 0, None)
  let vel = @score.velocity_checked(100).unwrap()
  let evt = @score.simple_chord_checked(
    [@pitch.c(4), @pitch.e(4), @pitch.g(4)],
    dur,
    Some(vel),
  ).unwrap()
  let ch = @score.midi_channel_checked(0).unwrap()
  let track = @score.simple_track_checked([evt], Some(ch), None).unwrap()
  let tempo = @score.tempo_checked(120).unwrap()
  let sig = @time.time_signature(4, 4)
  let score = @score.simple_score_checked([track], tempo, sig).unwrap()
  let opts = @musicxml.default_musicxml_export_options()
  let doc = @musicxml.simple_score_to_musicxml_checked(score, opts).unwrap()
  let xml = @musicxml.musicxml_score_to_string(doc, opts)
  assert_true(xml.contains("<chord/>"))
}

///|
test "error_to_string" {
  let e = @musicxml.MusicXmlError::MusicXmlUnsupported("test")
  assert_true(e.to_string().contains("不支持"))
}

// ============================================================
// golden tests — 确定性输出验证（assert_eq）
// ============================================================

///|
/// 构造 C 大调音阶 SimpleScore（与 midi golden 复用同一结构）
fn make_c_major_scale_score() -> @score.SimpleScore {
  let dur = @time.rhythm_duration(@time.DurQuarter, 0, None)
  let vel = @score.velocity_checked(100).unwrap()
  let scale = [
    @pitch.c(4),
    @pitch.d(4),
    @pitch.e(4),
    @pitch.f(4),
    @pitch.g(4),
    @pitch.a(4),
    @pitch.b(4),
    @pitch.c(5),
  ]
  let evts : Array[@score.SimpleEvent] = []
  for p in scale {
    evts.push(@score.simple_note_checked(p, dur, Some(vel)).unwrap())
  }
  let ch = @score.midi_channel_checked(0).unwrap()
  let track = @score.simple_track_checked(evts, Some(ch), None).unwrap()
  let tempo = @score.tempo_checked(120).unwrap()
  let sig = @time.time_signature(4, 4)
  @score.simple_score_checked([track], tempo, sig).unwrap()
}

///|
/// golden: C 大调音阶 MusicXML 输出确定性（两次运行一致）
test "golden_c_major_scale_xml_deterministic" {
  let score = make_c_major_scale_score()
  let opts = @musicxml.default_musicxml_export_options()
  let xml1 = @musicxml.simple_score_to_musicxml_string_checked(score, opts).unwrap()
  let xml2 = @musicxml.simple_score_to_musicxml_string_checked(score, opts).unwrap()
  assert_eq(xml1, xml2)
}

///|
/// golden: C 大调音阶 MusicXML 包含完整结构元素
test "golden_c_major_scale_xml_structure" {
  let score = make_c_major_scale_score()
  let opts = @musicxml.default_musicxml_export_options()
  let xml = @musicxml.simple_score_to_musicxml_string_checked(score, opts).unwrap()
  // XML 声明
  assert_true(xml.contains("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"))
  // DOCTYPE
  assert_true(xml.contains("<!DOCTYPE score-partwise"))
  // 根元素
  assert_true(xml.contains("<score-partwise version=\"4.0\">"))
  assert_true(xml.contains("</score-partwise>"))
  // part-list
  assert_true(xml.contains("<part-list>"))
  assert_true(xml.contains("</part-list>"))
  // score-part
  assert_true(xml.contains("<score-part id=\"P1\">"))
  assert_true(xml.contains("<part-name>Instrument</part-name>"))
  // part
  assert_true(xml.contains("<part id=\"P1\">"))
  assert_true(xml.contains("</part>"))
  // measure
  assert_true(xml.contains("<measure number=\"1\">"))
  // attributes (divisions + time + clef)
  assert_true(xml.contains("<divisions>480</divisions>"))
  assert_true(xml.contains("<beats>4</beats>"))
  assert_true(xml.contains("<beat-type>4</beat-type>"))
  assert_true(xml.contains("<sign>G</sign>"))
  assert_true(xml.contains("<line>2</line>"))
}

///|
/// golden: C 大调音阶 MusicXML 包含所有 8 个音符
test "golden_c_major_scale_xml_all_notes" {
  let score = make_c_major_scale_score()
  let opts = @musicxml.default_musicxml_export_options()
  let xml = @musicxml.simple_score_to_musicxml_string_checked(score, opts).unwrap()
  // 8 个音符：C4 D4 E4 F4 G4 A4 B4 C5
  assert_true(xml.contains("<step>C</step>"))
  assert_true(xml.contains("<step>D</step>"))
  assert_true(xml.contains("<step>E</step>"))
  assert_true(xml.contains("<step>F</step>"))
  assert_true(xml.contains("<step>G</step>"))
  assert_true(xml.contains("<step>A</step>"))
  assert_true(xml.contains("<step>B</step>"))
  // 八度：C4..B4=octave 4, C5=octave 5
  assert_true(xml.contains("<octave>4</octave>"))
  assert_true(xml.contains("<octave>5</octave>"))
}

///|
/// golden: C 大调音阶 MusicXML 音符类型正确
test "golden_c_major_scale_xml_note_types" {
  let score = make_c_major_scale_score()
  let opts = @musicxml.default_musicxml_export_options()
  let xml = @musicxml.simple_score_to_musicxml_string_checked(score, opts).unwrap()
  // 所有音符应为 quarter
  assert_true(xml.contains("<type>quarter</type>"))
  // 每个音符 duration = 480 (divisions per quarter)
  assert_true(xml.contains("<duration>480</duration>"))
}

///|
/// golden: C 大调音阶 MusicXML 不同 divisions 产生不同 duration
test "golden_c_major_scale_xml_different_divisions" {
  let score = make_c_major_scale_score()
  let opts = @musicxml.MusicXmlExportOptions::{
    divisions: 960,
    include_xml_header: false,
    include_doctype: false,
    part_name_fallback: "I",
  }
  let xml = @musicxml.simple_score_to_musicxml_string_checked(score, opts).unwrap()
  assert_true(xml.contains("<divisions>960</divisions>"))
  assert_true(xml.contains("<duration>960</duration>"))
  assert_false(xml.contains("<divisions>480</divisions>"))
}

///|
/// compat: musicxml 包从 v1 根包迁移。
/// v1 `score_to_musicxml_string_checked(score, opts)` → v2 `@musicxml.simple_score_to_musicxml_string_checked(score, opts)`
test "compat_note_v1_musicxml_types_removed" {
  // v1 MusicXmlDocumentKind 枚举已移除，v2 简化为 include_xml_header+include_doctype
  let opts = @musicxml.default_musicxml_export_options()
  // v2 opts 不含 document_kind 字段，只含 include_xml_header / include_doctype
  assert_true(opts.include_xml_header)
  assert_true(opts.include_doctype)
  assert_eq(opts.divisions, 480)
}

// ============================================================
// 导入测试
// ============================================================

///|
fn minimal_musicxml() -> String {
  "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
  "<!DOCTYPE score-partwise PUBLIC \"-//Recordare//DTD MusicXML 4.0 Partwise//EN\" \"http://www.musicxml.org/dtds/partwise.dtd\">\n" +
  "<score-partwise version=\"4.0\">\n" +
  "  <part-list>\n" +
  "    <score-part id=\"P1\">\n" +
  "      <part-name>Test</part-name>\n" +
  "    </score-part>\n" +
  "  </part-list>\n" +
  "  <part id=\"P1\">\n" +
  "    <measure number=\"1\">\n" +
  "      <attributes>\n" +
  "        <divisions>480</divisions>\n" +
  "        <time>\n" +
  "          <beats>4</beats>\n" +
  "          <beat-type>4</beat-type>\n" +
  "        </time>\n" +
  "        <clef>\n" +
  "          <sign>G</sign>\n" +
  "          <line>2</line>\n" +
  "        </clef>\n" +
  "      </attributes>\n" +
  "      <note>\n" +
  "        <pitch>\n" +
  "          <step>C</step>\n" +
  "          <octave>4</octave>\n" +
  "        </pitch>\n" +
  "        <duration>480</duration>\n" +
  "        <type>quarter</type>\n" +
  "      </note>\n" +
  "    </measure>\n" +
  "  </part>\n" +
  "</score-partwise>\n"
}

///|
test "parse_minimal_musicxml" {
  let xml = minimal_musicxml()
  let result = @musicxml.parse_musicxml_xml_checked(xml)
  assert_true(result is Ok(_))
  let score = result.unwrap()
  assert_eq(score.parts.length(), 1)
  assert_eq(score.parts[0].measures.length(), 1)
  assert_eq(score.parts[0].measures[0].notes.length(), 1)
  let note = score.parts[0].measures[0].notes[0]
  assert_false(note.is_rest)
  match note.pitch {
    Some(p) => {
      assert_eq(p.step, "C")
      assert_eq(p.octave, 4)
    }
    None => assert_true(false)
  }
}

///|
test "import_minimal_to_layout" {
  let xml = minimal_musicxml()
  let result = @musicxml.musicxml_string_to_layout_checked(xml)
  assert_true(result is Ok(_))
  let layout = result.unwrap()
  assert_eq(layout.parts.length(), 1)
  assert_eq(layout.initial_signature.numerator, 4)
  assert_eq(layout.initial_signature.denominator, 4)
  let staff = layout.parts[0].staves[0]
  let voice = staff.voices[0]
  assert_eq(voice.measures.length(), 1)
  let events = voice.measures[0].events
  assert_eq(events.length(), 1)
  // 验证是一个 Note 事件
  assert_true(events[0] is @score.Note(_))
}

///|
test "import_with_rest" {
  let xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
    "<score-partwise version=\"4.0\">\n" +
    "  <part-list>\n" +
    "    <score-part id=\"P1\">\n" +
    "      <part-name>T</part-name>\n" +
    "    </score-part>\n" +
    "  </part-list>\n" +
    "  <part id=\"P1\">\n" +
    "    <measure number=\"1\">\n" +
    "      <attributes>\n" +
    "        <divisions>480</divisions>\n" +
    "        <time>\n" +
    "          <beats>4</beats>\n" +
    "          <beat-type>4</beat-type>\n" +
    "        </time>\n" +
    "        <clef>\n" +
    "          <sign>G</sign>\n" +
    "          <line>2</line>\n" +
    "        </clef>\n" +
    "      </attributes>\n" +
    "      <note>\n" +
    "        <rest/>\n" +
    "        <duration>480</duration>\n" +
    "        <type>quarter</type>\n" +
    "      </note>\n" +
    "    </measure>\n" +
    "  </part>\n" +
    "</score-partwise>\n"
  let result = @musicxml.musicxml_string_to_layout_checked(xml)
  assert_true(result is Ok(_))
  let layout = result.unwrap()
  let events = layout.parts[0].staves[0].voices[0].measures[0].events
  assert_eq(events.length(), 1)
  assert_true(events[0] is @score.Rest(_))
}

///|
test "import_with_sharp" {
  let xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
    "<score-partwise version=\"4.0\">\n" +
    "  <part-list>\n" +
    "    <score-part id=\"P1\">\n" +
    "      <part-name>T</part-name>\n" +
    "    </score-part>\n" +
    "  </part-list>\n" +
    "  <part id=\"P1\">\n" +
    "    <measure number=\"1\">\n" +
    "      <attributes>\n" +
    "        <divisions>480</divisions>\n" +
    "        <time>\n" +
    "          <beats>4</beats>\n" +
    "          <beat-type>4</beat-type>\n" +
    "        </time>\n" +
    "        <clef>\n" +
    "          <sign>G</sign>\n" +
    "          <line>2</line>\n" +
    "        </clef>\n" +
    "      </attributes>\n" +
    "      <note>\n" +
    "        <pitch>\n" +
    "          <step>F</step>\n" +
    "          <alter>1</alter>\n" +
    "          <octave>4</octave>\n" +
    "        </pitch>\n" +
    "        <duration>480</duration>\n" +
    "        <type>quarter</type>\n" +
    "      </note>\n" +
    "    </measure>\n" +
    "  </part>\n" +
    "</score-partwise>\n"
  let result = @musicxml.musicxml_string_to_layout_checked(xml)
  assert_true(result is Ok(_))
  let layout = result.unwrap()
  match layout.parts[0].staves[0].voices[0].measures[0].events[0] {
    @score.Note(n) => assert_eq(n.pitch.to_string(), "F#4")
    _ => assert_true(false)
  }
}

///|
test "import_with_flat" {
  let xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
    "<score-partwise version=\"4.0\">\n" +
    "  <part-list>\n" +
    "    <score-part id=\"P1\">\n" +
    "      <part-name>T</part-name>\n" +
    "    </score-part>\n" +
    "  </part-list>\n" +
    "  <part id=\"P1\">\n" +
    "    <measure number=\"1\">\n" +
    "      <attributes>\n" +
    "        <divisions>480</divisions>\n" +
    "        <time>\n" +
    "          <beats>4</beats>\n" +
    "          <beat-type>4</beat-type>\n" +
    "        </time>\n" +
    "        <clef>\n" +
    "          <sign>G</sign>\n" +
    "          <line>2</line>\n" +
    "        </clef>\n" +
    "      </attributes>\n" +
    "      <note>\n" +
    "        <pitch>\n" +
    "          <step>B</step>\n" +
    "          <alter>-1</alter>\n" +
    "          <octave>3</octave>\n" +
    "        </pitch>\n" +
    "        <duration>480</duration>\n" +
    "        <type>quarter</type>\n" +
    "      </note>\n" +
    "    </measure>\n" +
    "  </part>\n" +
    "</score-partwise>\n"
  let result = @musicxml.musicxml_string_to_layout_checked(xml)
  assert_true(result is Ok(_))
  let layout = result.unwrap()
  match layout.parts[0].staves[0].voices[0].measures[0].events[0] {
    @score.Note(n) => assert_eq(n.pitch.to_string(), "Bb3")
    _ => assert_true(false)
  }
}

///|
test "import_dotted_note" {
  let xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
    "<score-partwise version=\"4.0\">\n" +
    "  <part-list>\n" +
    "    <score-part id=\"P1\">\n" +
    "      <part-name>T</part-name>\n" +
    "    </score-part>\n" +
    "  </part-list>\n" +
    "  <part id=\"P1\">\n" +
    "    <measure number=\"1\">\n" +
    "      <attributes>\n" +
    "        <divisions>480</divisions>\n" +
    "        <time>\n" +
    "          <beats>4</beats>\n" +
    "          <beat-type>4</beat-type>\n" +
    "        </time>\n" +
    "        <clef>\n" +
    "          <sign>G</sign>\n" +
    "          <line>2</line>\n" +
    "        </clef>\n" +
    "      </attributes>\n" +
    "      <note>\n" +
    "        <pitch>\n" +
    "          <step>G</step>\n" +
    "          <octave>4</octave>\n" +
    "        </pitch>\n" +
    "        <duration>720</duration>\n" +
    "        <type>half</type>\n" +
    "        <dot/>\n" +
    "      </note>\n" +
    "    </measure>\n" +
    "  </part>\n" +
    "</score-partwise>\n"
  let result = @musicxml.musicxml_string_to_layout_checked(xml)
  assert_true(result is Ok(_))
  let layout = result.unwrap()
  match layout.parts[0].staves[0].voices[0].measures[0].events[0] {
    @score.Note(n) => {
      // DurUnit 未实现 Eq, 用模式匹配验证
      let unit_ok = match n.duration.unit {
        @time.DurHalf => true
        _ => false
      }
      assert_true(unit_ok)
      assert_eq(n.duration.dots, 1)
    }
    _ => assert_true(false)
  }
}

///|
test "import_chord" {
  let xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
    "<score-partwise version=\"4.0\">\n" +
    "  <part-list>\n" +
    "    <score-part id=\"P1\">\n" +
    "      <part-name>T</part-name>\n" +
    "    </score-part>\n" +
    "  </part-list>\n" +
    "  <part id=\"P1\">\n" +
    "    <measure number=\"1\">\n" +
    "      <attributes>\n" +
    "        <divisions>480</divisions>\n" +
    "        <time>\n" +
    "          <beats>4</beats>\n" +
    "          <beat-type>4</beat-type>\n" +
    "        </time>\n" +
    "        <clef>\n" +
    "          <sign>G</sign>\n" +
    "          <line>2</line>\n" +
    "        </clef>\n" +
    "      </attributes>\n" +
    "      <note>\n" +
    "        <pitch>\n" +
    "          <step>C</step>\n" +
    "          <octave>4</octave>\n" +
    "        </pitch>\n" +
    "        <duration>480</duration>\n" +
    "        <type>quarter</type>\n" +
    "      </note>\n" +
    "      <note>\n" +
    "        <chord/>\n" +
    "        <pitch>\n" +
    "          <step>E</step>\n" +
    "          <octave>4</octave>\n" +
    "        </pitch>\n" +
    "        <duration>480</duration>\n" +
    "        <type>quarter</type>\n" +
    "      </note>\n" +
    "      <note>\n" +
    "        <chord/>\n" +
    "        <pitch>\n" +
    "          <step>G</step>\n" +
    "          <octave>4</octave>\n" +
    "        </pitch>\n" +
    "        <duration>480</duration>\n" +
    "        <type>quarter</type>\n" +
    "      </note>\n" +
    "    </measure>\n" +
    "  </part>\n" +
    "</score-partwise>\n"
  let result = @musicxml.musicxml_string_to_layout_checked(xml)
  assert_true(result is Ok(_))
  let layout = result.unwrap()
  let events = layout.parts[0].staves[0].voices[0].measures[0].events
  assert_eq(events.length(), 1)
  match events[0] {
    @score.Chord(c) => assert_eq(c.pitches.length(), 3)
    _ => assert_true(false)
  }
}

///|
test "import_multi_measure" {
  let xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
    "<score-partwise version=\"4.0\">\n" +
    "  <part-list><score-part id=\"P1\"><part-name>T</part-name></score-part></part-list>\n" +
    "  <part id=\"P1\">\n" +
    "    <measure number=\"1\">\n" +
    "      <attributes>\n" +
    "        <divisions>480</divisions>\n" +
    "        <time><beats>4</beats><beat-type>4</beat-type></time>\n" +
    "        <clef><sign>G</sign><line>2</line></clef>\n" +
    "      </attributes>\n" +
    "      <note><pitch><step>C</step><octave>4</octave></pitch><duration>480</duration><type>quarter</type></note>\n" +
    "    </measure>\n" +
    "    <measure number=\"2\">\n" +
    "      <note><pitch><step>D</step><octave>4</octave></pitch><duration>480</duration><type>quarter</type></note>\n" +
    "    </measure>\n" +
    "  </part>\n" +
    "</score-partwise>\n"
  let result = @musicxml.musicxml_string_to_layout_checked(xml)
  assert_true(result is Ok(_))
  let layout = result.unwrap()
  let voice = layout.parts[0].staves[0].voices[0]
  assert_eq(voice.measures.length(), 2)
}

// ============================================================
// 往返测试: SimpleScore → MusicXML → ScoreLayout
// ============================================================

///|
test "roundtrip_export_import_note_count" {
  let score = make_simple_score()
  let opts = @musicxml.default_musicxml_export_options()
  let xml = @musicxml.simple_score_to_musicxml_string_checked(score, opts).unwrap()
  let result = @musicxml.musicxml_string_to_layout_checked(xml)
  assert_true(result is Ok(_))
  let layout = result.unwrap()
  assert_eq(layout.parts.length(), 1)
  let voice = layout.parts[0].staves[0].voices[0]
  assert_true(voice.measures.length() >= 1)
  // 统计总事件数
  let mut total = 0
  for mi = 0; mi < voice.measures.length(); mi = mi + 1 {
    total = total + voice.measures[mi].events.length()
  }
  assert_eq(total, 4)
}

///|
test "roundtrip_rest" {
  let dur = @time.rhythm_duration(@time.DurQuarter, 0, None)
  let vel = @score.velocity_checked(100).unwrap()
  let evts = [
    @score.simple_note_checked(@pitch.c(4), dur, Some(vel)).unwrap(),
    @score.simple_rest_checked(dur).unwrap(),
    @score.simple_note_checked(@pitch.e(4), dur, Some(vel)).unwrap(),
  ]
  let ch = @score.midi_channel_checked(0).unwrap()
  let track = @score.simple_track_checked(evts, Some(ch), None).unwrap()
  let tempo = @score.tempo_checked(120).unwrap()
  let sig = @time.time_signature(4, 4)
  let score = @score.simple_score_checked([track], tempo, sig).unwrap()
  let opts = @musicxml.default_musicxml_export_options()
  let xml = @musicxml.simple_score_to_musicxml_string_checked(score, opts).unwrap()
  let result = @musicxml.musicxml_string_to_layout_checked(xml)
  assert_true(result is Ok(_))
  let layout = result.unwrap()
  let events = layout.parts[0].staves[0].voices[0].measures[0].events
  assert_eq(events.length(), 3)
  assert_true(events[0] is @score.Note(_))
  assert_true(events[1] is @score.Rest(_))
  assert_true(events[2] is @score.Note(_))
}

///|
test "roundtrip_chord" {
  let dur = @time.rhythm_duration(@time.DurHalf, 0, None)
  let vel = @score.velocity_checked(100).unwrap()
  let evt = @score.simple_chord_checked(
    [@pitch.c(4), @pitch.e(4), @pitch.g(4)],
    dur,
    Some(vel),
  ).unwrap()
  let ch = @score.midi_channel_checked(0).unwrap()
  let track = @score.simple_track_checked([evt], Some(ch), None).unwrap()
  let tempo = @score.tempo_checked(120).unwrap()
  let sig = @time.time_signature(4, 4)
  let score = @score.simple_score_checked([track], tempo, sig).unwrap()
  let opts = @musicxml.default_musicxml_export_options()
  let xml = @musicxml.simple_score_to_musicxml_string_checked(score, opts).unwrap()
  let result = @musicxml.musicxml_string_to_layout_checked(xml)
  assert_true(result is Ok(_))
  let layout = result.unwrap()
  let events = layout.parts[0].staves[0].voices[0].measures[0].events
  assert_eq(events.length(), 1)
  match events[0] {
    @score.Chord(c) => assert_eq(c.pitches.length(), 3)
    _ => assert_true(false)
  }
}

// ============================================================
// 错误路径测试
// ============================================================

///|
test "import_bad_xml_parse_error" {
  let xml = "not xml at all"
  let result = @musicxml.musicxml_string_to_layout_checked(xml)
  assert_true(result is Err(_))
}

///|
test "import_empty_xml_error" {
  let result = @musicxml.musicxml_string_to_layout_checked("")
  assert_true(result is Err(_))
}

///|
test "import_unclosed_tag_error" {
  let xml = "<score-partwise><part-list></part-list><part id=\"P1\"><measure number=\"1\">"
  let result = @musicxml.musicxml_string_to_layout_checked(xml)
  assert_true(result is Err(_))
}

///|
test "import_wrong_root_error" {
  let xml = "<not-musicxml><part-list/></not-musicxml>"
  let result = @musicxml.musicxml_string_to_layout_checked(xml)
  assert_true(result is Err(_))
}

///|
test "import_unknown_note_type_error" {
  let xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
    "<score-partwise version=\"4.0\">\n" +
    "  <part-list><score-part id=\"P1\"><part-name>T</part-name></score-part></part-list>\n" +
    "  <part id=\"P1\">\n" +
    "    <measure number=\"1\">\n" +
    "      <attributes>\n" +
    "        <divisions>480</divisions>\n" +
    "        <time><beats>4</beats><beat-type>4</beat-type></time>\n" +
    "        <clef><sign>G</sign><line>2</line></clef>\n" +
    "      </attributes>\n" +
    "      <note>\n" +
    "        <pitch><step>C</step><octave>4</octave></pitch>\n" +
    "        <duration>480</duration>\n" +
    "        <type>invalid_type</type>\n" +
    "      </note>\n" +
    "    </measure>\n" +
    "  </part>\n" +
    "</score-partwise>\n"
  let result = @musicxml.musicxml_string_to_layout_checked(xml)
  assert_true(result is Err(_))
}

///|
test "import_missing_type_error" {
  let xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
    "<score-partwise version=\"4.0\">\n" +
    "  <part-list><score-part id=\"P1\"><part-name>T</part-name></score-part></part-list>\n" +
    "  <part id=\"P1\">\n" +
    "    <measure number=\"1\">\n" +
    "      <attributes>\n" +
    "        <divisions>480</divisions>\n" +
    "        <time><beats>4</beats><beat-type>4</beat-type></time>\n" +
    "        <clef><sign>G</sign><line>2</line></clef>\n" +
    "      </attributes>\n" +
    "      <note>\n" +
    "        <pitch><step>C</step><octave>4</octave></pitch>\n" +
    "        <duration>480</duration>\n" +
    "      </note>\n" +
    "    </measure>\n" +
    "  </part>\n" +
    "</score-partwise>\n"
  let result = @musicxml.musicxml_string_to_layout_checked(xml)
  assert_true(result is Err(_))
}

// ============================================================
// 导入报告测试
// ============================================================

///|
test "import_result_report" {
  let xml = minimal_musicxml()
  let result = @musicxml.musicxml_string_to_import_result_checked(xml)
  assert_true(result is Ok(_))
  let r = result.unwrap()
  assert_eq(r.report.part_count, 1)
  assert_eq(r.report.measure_count, 1)
  let json = @musicxml.musicxml_import_report_to_json(r.report)
  assert_true(json.contains("part_count"))
  assert_true(json.contains("warnings"))
}

///|
test "import_result_with_direction_warning" {
  let xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
    "<score-partwise version=\"4.0\">\n" +
    "  <part-list><score-part id=\"P1\"><part-name>T</part-name></score-part></part-list>\n" +
    "  <part id=\"P1\">\n" +
    "    <measure number=\"1\">\n" +
    "      <attributes>\n" +
    "        <divisions>480</divisions>\n" +
    "        <time><beats>4</beats><beat-type>4</beat-type></time>\n" +
    "        <clef><sign>G</sign><line>2</line></clef>\n" +
    "      </attributes>\n" +
    "      <note>\n" +
    "        <pitch><step>C</step><octave>4</octave></pitch>\n" +
    "        <duration>480</duration>\n" +
    "        <type>quarter</type>\n" +
    "      </note>\n" +
    "      <direction placement=\"below\">\n" +
    "        <dynamics><p/></dynamics>\n" +
    "      </direction>\n" +
    "    </measure>\n" +
    "  </part>\n" +
    "</score-partwise>\n"
  let result = @musicxml.musicxml_string_to_import_result_checked(xml)
  assert_true(result is Ok(_))
  let r = result.unwrap()
  assert_eq(r.report.part_count, 1)
  assert_eq(r.report.measure_count, 1)
  // direction 应产生 warning
  assert_true(
    r.report.warnings.length() > 0 || r.report.unsupported_elements.length() > 0,
  )
}

///|
test "import_error_to_string" {
  let e = @musicxml.MusicXmlError::MusicXmlImportError("test parse error")
  assert_true(e.to_string().contains("导入错误"))
}
