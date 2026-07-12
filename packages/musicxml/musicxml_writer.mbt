// ============================================================
// MusicXmlScore -> XML string serialization
// ============================================================

///|
fn xml_escape(s : String) -> String {
  let mut out = ""
  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i]
    if c == '&' {
      out = out + "&amp;"
    } else if c == '<' {
      out = out + "&lt;"
    } else if c == '>' {
      out = out + "&gt;"
    } else if c == '\"' {
      out = out + "&quot;"
    } else {
      out = out + s[i:i + 1].to_owned()
    }
  }
  out
}

///|
fn indent(n : Int) -> String {
  let mut s = ""
  for k = 0; k < n; k = k + 1 {
    s = s + " "
  }
  s
}

///|
fn serialize_note(n : MusicXmlNote, ind : Int) -> String {
  let mut s = indent(ind) + "<note>\n"
  let i2 = ind + 2
  if n.is_chord_tone && !n.is_rest {
    s = s + indent(i2) + "<chord/>\n"
  }
  if n.is_rest {
    s = s + indent(i2) + "<rest/>\n"
  } else {
    match n.pitch {
      Some(p) => {
        s = s + indent(i2) + "<pitch>\n"
        s = s + indent(i2 + 2) + "<step>\{xml_escape(p.step)}</step>\n"
        if p.alter != 0 {
          s = s + indent(i2 + 2) + "<alter>\{p.alter}</alter>\n"
        }
        s = s + indent(i2 + 2) + "<octave>\{p.octave}</octave>\n"
        s = s + indent(i2) + "</pitch>\n"
      }
      None => s = s + indent(i2) + "<rest/>\n"
    }
  }
  s = s + indent(i2) + "<duration>\{n.duration}</duration>\n"
  s = s + indent(i2) + "<type>\{note_type_to_xml(n.note_type)}</type>\n"
  for d = 0; d < n.dots; d = d + 1 {
    s = s + indent(i2) + "<dot/>\n"
  }
  if n.voice > 1 {
    s = s + indent(i2) + "<voice>\{n.voice}</voice>\n"
  }
  if n.staff > 1 {
    s = s + indent(i2) + "<staff>\{n.staff}</staff>\n"
  }
  s + indent(ind) + "</note>\n"
}

///|
fn serialize_measure(m : MusicXmlMeasure, ind : Int) -> String {
  let mut s = indent(ind) + "<measure number=\"\{m.number}\">\n"
  match m.attributes {
    Some(attrs) => {
      s = s + indent(ind + 2) + "<attributes>\n"
      s = s + indent(ind + 4) + "<divisions>\{attrs.divisions}</divisions>\n"
      s = s + indent(ind + 4) + "<time>\n"
      s = s +
        indent(ind + 6) +
        "<beats>\{attrs.time_signature.numerator}</beats>\n"
      s = s +
        indent(ind + 6) +
        "<beat-type>\{attrs.time_signature.denominator}</beat-type>\n"
      s = s + indent(ind + 4) + "</time>\n"
      s = s + indent(ind + 4) + "<clef>\n"
      s = s + indent(ind + 6) + "<sign>G</sign>\n"
      s = s + indent(ind + 6) + "<line>2</line>\n"
      s = s + indent(ind + 4) + "</clef>\n"
      s = s + indent(ind + 2) + "</attributes>\n"
    }
    None => ()
  }
  for i = 0; i < m.notes.length(); i = i + 1 {
    s = s + serialize_note(m.notes[i], ind + 2)
  }
  s + indent(ind) + "</measure>\n"
}

///|
pub fn musicxml_score_to_string(
  doc : MusicXmlScore,
  options : MusicXmlExportOptions,
) -> String {
  let mut xml = ""
  if options.include_xml_header {
    xml = xml + "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
    if options.include_doctype {
      xml = xml +
        "<!DOCTYPE score-partwise PUBLIC \"-//Recordare//DTD MusicXML 4.0 Partwise//EN\" \"http://www.musicxml.org/dtds/partwise.dtd\">\n"
    }
  }
  xml = xml + "<score-partwise version=\"4.0\">\n"
  xml = xml + "  <part-list>\n"
  for i = 0; i < doc.parts.length(); i = i + 1 {
    let p = doc.parts[i]
    xml = xml + "    <score-part id=\"\{xml_escape(p.id)}\">\n"
    xml = xml + "      <part-name>\{xml_escape(p.name)}</part-name>\n"
    xml = xml + "    </score-part>\n"
  }
  xml = xml + "  </part-list>\n"
  for i = 0; i < doc.parts.length(); i = i + 1 {
    let p = doc.parts[i]
    xml = xml + "  <part id=\"\{xml_escape(p.id)}\">\n"
    for j = 0; j < p.measures.length(); j = j + 1 {
      xml = xml + serialize_measure(p.measures[j], 4)
    }
    xml = xml + "  </part>\n"
  }
  xml = xml + "</score-partwise>\n"
  xml
}

///|
pub fn simple_score_to_musicxml_string_checked(
  score : @score.SimpleScore,
  options : MusicXmlExportOptions,
) -> Result[String, MusicXmlError] {
  match simple_score_to_musicxml_checked(score, options) {
    Ok(doc) => Ok(musicxml_score_to_string(doc, options))
    Err(e) => Err(e)
  }
}
