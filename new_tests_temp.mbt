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
/// Note type 边界：32nd / 64th / 128th 序列化
test "musicxml_v2: note_type_32nd_64th_128th_xml" {
  let mk_opts() = @moonsic.MusicXmlExportOptions::{
    divisions: 480,
    document_kind: @moonsic.Partwise,
    include_xml_header: false,
    include_doctype: false,
    strict: false,
    part_name_fallback: "T",
  }
  let check_type(nt : @moonsic.MusicXmlNoteType, expected : String) = {
    let note = @moonsic.MusicXmlNote::{
      pitch: Some(@moonsic.MusicXmlPitch::{ step: "C", alter: 0, octave: 4 }),
      duration: 60,
      note_type: nt,
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
    let p = @moonsic.MusicXmlPart::{
      id: "P1",
      name: "T",
      measures: [m],
    }
    let doc = @moonsic.MusicXmlScore::{
      title: "",
      composer: "",
      document_kind: @moonsic.Partwise,
      parts: [p],
      divisions: 480,
    }
    match @moonsic.musicxml_to_string_checked(doc, mk_opts()) {
      Ok(xml) => assert_true(xml.contains("<type>\\{expected}</type>"))
      Err(e) => abort(e.to_string())
    }
  }
  check_type(@moonsic.ThirtySecondT, "32nd")
  check_type(@moonsic.SixtyFourthT, "64th")
  check_type(@moonsic.OneTwentyEighthT, "128th")
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
