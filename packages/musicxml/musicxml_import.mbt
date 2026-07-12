// ============================================================
// MusicXML Import — XML string → MusicXmlScore / ScoreLayout
// ============================================================

// ============================================================
// MusicXmlImportReport / MusicXmlImportResult
// ============================================================

///|
/// 导入报告: 记录 warnings 和统计信息
pub(all) struct MusicXmlImportReport {
  warnings : Array[String]
  unsupported_elements : Array[String]
  part_count : Int
  measure_count : Int
}

///|
/// 导入结果: ScoreLayout + 报告
pub(all) struct MusicXmlImportResult {
  layout : @score.ScoreLayout
  report : MusicXmlImportReport
}

///|
/// 导入报告转为 JSON 字符串
pub fn musicxml_import_report_to_json(report : MusicXmlImportReport) -> String {
  let p = "\"part_count\": " + report.part_count.to_string()
  let m = "\"measure_count\": " + report.measure_count.to_string()
  let w = json_string_array("warnings", report.warnings)
  let u = json_string_array("unsupported_elements", report.unsupported_elements)
  "{ " + p + ", " + m + ", " + w + ", " + u + " }"
}

///|
fn json_string_array(key : String, arr : Array[String]) -> String {
  let mut s = "\"" + key + "\": ["
  for i = 0; i < arr.length(); i = i + 1 {
    if i > 0 {
      s = s + ", "
    }
    s = s + "\"" + json_escape(arr[i]) + "\""
  }
  s + "]"
}

///|
fn json_escape(s : String) -> String {
  let mut out = ""
  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i]
    if c == '"' {
      out = out + "\\\""
    } else if c == '\\' {
      out = out + "\\\\"
    } else if c == '\n' {
      out = out + "\\n"
    } else if c == '\r' {
      out = out + "\\r"
    } else if c == '\t' {
      out = out + "\\t"
    } else {
      out = out + s[i:i + 1].to_owned()
    }
  }
  out
}

// ============================================================
// 内部: 字符串工具
// ============================================================

///|
fn trim_str(s : String) -> String {
  let mut start = 0
  let mut end = s.length()
  while start < end {
    let c = s[start]
    if c == ' ' || c == '\n' || c == '\r' || c == '\t' {
      start = start + 1
    } else {
      break
    }
  }
  while end > start {
    let c = s[end - 1]
    if c == ' ' || c == '\n' || c == '\r' || c == '\t' {
      end = end - 1
    } else {
      break
    }
  }
  s[start:end].to_owned()
}

///|
fn is_only_ws(s : String) -> Bool {
  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i]
    if !(c == ' ' || c == '\n' || c == '\r' || c == '\t') {
      return false
    }
  }
  true
}

///|
fn parse_int_text(s : String) -> Result[Int, MusicXmlError] {
  let trimmed = trim_str(s)
  let len = trimmed.length()
  if len == 0 {
    return Err(MusicXmlImportError("空整数字符串"))
  }
  let mut i = 0
  let mut neg = false
  if trimmed[0] == '-' {
    neg = true
    i = 1
  } else if trimmed[0] == '+' {
    i = 1
  }
  if i >= len {
    return Err(MusicXmlImportError("无效整数: \{s}"))
  }
  let mut val : Int = 0
  while i < len {
    let c = trimmed[i]
    if c >= '0' && c <= '9' {
      val = val * 10 + (c.to_int() - '0'.to_int())
      i = i + 1
    } else {
      return Err(MusicXmlImportError("无效整数: \{s}"))
    }
  }
  if neg {
    val = -val
  }
  Ok(val)
}

// ============================================================
// 内部: XML Token 类型
// ============================================================

///|
priv enum XmlToken {
  OpenTag(String, Array[(String, String)])
  CloseTag(String)
  SelfCloseTag(String, Array[(String, String)])
  Text(String)
}

///|
priv struct XmlElement {
  name : String
  attrs : Array[(String, String)]
  text : String
  children : Array[XmlElement]
}

// ============================================================
// 内部: XML 扫描辅助
// ============================================================

///|
fn read_xml_name(xml : String, pos : Int) -> (String, Int) {
  let len = xml.length()
  let mut p = pos
  // 首字符
  if p < len {
    let c = xml[p]
    let is_start = (c >= 'A' && c <= 'Z') ||
      (c >= 'a' && c <= 'z') ||
      c == '_' ||
      c == ':'
    if is_start {
      p = p + 1
      while p < len {
        let c2 = xml[p]
        let is_cont = (c2 >= 'A' && c2 <= 'Z') ||
          (c2 >= 'a' && c2 <= 'z') ||
          (c2 >= '0' && c2 <= '9') ||
          c2 == '_' ||
          c2 == ':' ||
          c2 == '-' ||
          c2 == '.'
        if is_cont {
          p = p + 1
        } else {
          break
        }
      }
    }
  }
  (xml[pos:p].to_owned(), p)
}

///|
fn read_attrs(xml : String, pos : Int) -> (Array[(String, String)], Int) {
  let attrs : Array[(String, String)] = []
  let len = xml.length()
  let mut p = pos
  while p < len {
    // 跳过空格
    while p < len {
      let c = xml[p]
      if c == ' ' || c == '\n' || c == '\r' || c == '\t' {
        p = p + 1
      } else {
        break
      }
    }
    if p >= len || xml[p] == '>' || xml[p] == '/' {
      break
    }
    // 读取属性名
    let name_start = p
    while p < len {
      let c = xml[p]
      let is_name_c = (c >= 'A' && c <= 'Z') ||
        (c >= 'a' && c <= 'z') ||
        (c >= '0' && c <= '9') ||
        c == '_' ||
        c == ':' ||
        c == '-' ||
        c == '.'
      if is_name_c {
        p = p + 1
      } else {
        break
      }
    }
    if p == name_start {
      break
    }
    let name = xml[name_start:p].to_owned()
    // 跳过空格和 =
    while p < len {
      let c = xml[p]
      if c == ' ' || c == '\n' || c == '\r' || c == '\t' {
        p = p + 1
      } else {
        break
      }
    }
    if p < len && xml[p] == '=' {
      p = p + 1
      while p < len {
        let c = xml[p]
        if c == ' ' || c == '\n' || c == '\r' || c == '\t' {
          p = p + 1
        } else {
          break
        }
      }
      // 读取引号内的值
      if p < len && (xml[p] == '"' || xml[p] == '\'') {
        let quote = xml[p]
        p = p + 1
        let val_start = p
        while p < len && xml[p] != quote {
          p = p + 1
        }
        let val = xml[val_start:p].to_owned()
        if p < len {
          p = p + 1
        }
        attrs.push((name, val))
      }
    }
  }
  (attrs, p)
}

// ============================================================
// 内部: XML Token 化
// ============================================================

///|
fn tokenize_xml(xml : String) -> Result[Array[XmlToken], MusicXmlError] {
  let len = xml.length()
  let tokens : Array[XmlToken] = []
  let mut pos = 0
  while pos < len {
    if xml[pos] == '<' {
      pos = pos + 1
      if pos >= len {
        return Err(
          MusicXmlImportError("意外的 XML 结尾: '<' 后无内容"),
        )
      }
      // 检查特殊结构
      if xml[pos] == '!' {
        pos = pos + 1
        if pos + 1 < len && xml[pos] == '-' && xml[pos + 1] == '-' {
          // 注释 <!-- ... -->
          pos = pos + 2
          while pos + 2 < len {
            if xml[pos] == '-' && xml[pos + 1] == '-' && xml[pos + 2] == '>' {
              pos = pos + 3
              break
            }
            pos = pos + 1
          }
        } else if pos + 6 < len &&
          xml[pos] == '[' &&
          xml[pos + 1] == 'C' &&
          xml[pos + 2] == 'D' &&
          xml[pos + 3] == 'A' &&
          xml[pos + 4] == 'T' &&
          xml[pos + 5] == 'A' &&
          xml[pos + 6] == '[' {
          // CDATA
          pos = pos + 7
          while pos + 2 < len {
            if xml[pos] == ']' && xml[pos + 1] == ']' && xml[pos + 2] == '>' {
              pos = pos + 3
              break
            }
            pos = pos + 1
          }
        } else {
          // DOCTYPE 或其他声明
          while pos < len && xml[pos] != '>' {
            pos = pos + 1
          }
          if pos < len {
            pos = pos + 1
          }
        }
      } else if xml[pos] == '?' {
        // 处理指令 <? ... ?>
        pos = pos + 1
        while pos + 1 < len {
          if xml[pos] == '?' && xml[pos + 1] == '>' {
            pos = pos + 2
            break
          }
          pos = pos + 1
        }
      } else if xml[pos] == '/' {
        // 闭合标签 </name>
        pos = pos + 1
        let (name, after_name) = read_xml_name(xml, pos)
        pos = after_name
        while pos < len {
          let c = xml[pos]
          if c == ' ' || c == '\n' || c == '\r' || c == '\t' {
            pos = pos + 1
          } else {
            break
          }
        }
        if pos < len && xml[pos] == '>' {
          pos = pos + 1
        }
        tokens.push(CloseTag(name))
      } else {
        // 开放标签或自闭合标签
        let (name, after_name) = read_xml_name(xml, pos)
        pos = after_name
        let (attrs_vals, after_attrs) = read_attrs(xml, pos)
        pos = after_attrs
        while pos < len {
          let c = xml[pos]
          if c == ' ' || c == '\n' || c == '\r' || c == '\t' {
            pos = pos + 1
          } else {
            break
          }
        }
        if pos + 1 < len && xml[pos] == '/' && xml[pos + 1] == '>' {
          pos = pos + 2
          tokens.push(SelfCloseTag(name, attrs_vals))
        } else if pos < len && xml[pos] == '>' {
          pos = pos + 1
          tokens.push(OpenTag(name, attrs_vals))
        } else {
          return Err(
            MusicXmlImportError(
              "标签未正确结束: <\{name}> 位置 \{pos}",
            ),
          )
        }
      }
    } else {
      // 文本内容
      let start = pos
      while pos < len && xml[pos] != '<' {
        pos = pos + 1
      }
      let text = xml[start:pos].to_owned()
      if !is_only_ws(text) {
        tokens.push(Text(text))
      }
    }
  }
  Ok(tokens)
}

// ============================================================
// 内部: Token → XmlElement 解析
// ============================================================

///|
fn parse_element(
  tokens : Array[XmlToken],
  pos : Int,
) -> Result[(XmlElement, Int), MusicXmlError] {
  if pos >= tokens.length() {
    return Err(MusicXmlImportError("意外的 token 列表结尾"))
  }
  match tokens[pos] {
    SelfCloseTag(name, attrs) =>
      Ok((XmlElement::{ name, attrs, text: "", children: [] }, pos + 1))
    OpenTag(name, attrs) => {
      let children : Array[XmlElement] = []
      let text_parts : Array[String] = []
      let mut p = pos + 1
      let mut found_close = false
      while p < tokens.length() && !found_close {
        match tokens[p] {
          CloseTag(close_name) => {
            if close_name != name {
              return Err(
                MusicXmlImportError(
                  "标签不匹配: 期望 </\{name}>, 遇到 </\{close_name}>",
                ),
              )
            }
            p = p + 1
            found_close = true
          }
          Text(t) => {
            text_parts.push(t)
            p = p + 1
          }
          OpenTag(_, _) | SelfCloseTag(_, _) => {
            let parse_result = parse_element(tokens, p)
            match parse_result {
              Ok((child, new_p)) => {
                children.push(child)
                p = new_p
              }
              Err(e) => return Err(e)
            }
          }
        }
      }
      if !found_close {
        return Err(MusicXmlImportError("未闭合的标签: <\{name}>"))
      }
      let mut joined = ""
      for i = 0; i < text_parts.length(); i = i + 1 {
        joined = joined + text_parts[i]
      }
      let text = trim_str(joined)
      Ok((XmlElement::{ name, attrs, text, children }, p))
    }
    _ =>
      Err(
        MusicXmlImportError(
          "期望 OpenTag 或 SelfCloseTag, 但遇到其他 token",
        ),
      )
  }
}

///|
/// 从 tokens 位置 0 开始解析所有顶层元素
fn parse_all(
  tokens : Array[XmlToken],
) -> Result[Array[XmlElement], MusicXmlError] {
  let elements : Array[XmlElement] = []
  let mut pos = 0
  while pos < tokens.length() {
    match tokens[pos] {
      OpenTag(_, _) | SelfCloseTag(_, _) => {
        let parse_result = parse_element(tokens, pos)
        match parse_result {
          Ok((el, new_pos)) => {
            elements.push(el)
            pos = new_pos
          }
          Err(e) => return Err(e)
        }
      }
      Text(_) => pos = pos + 1
      CloseTag(name) =>
        return Err(
          MusicXmlImportError("意外的闭合标签 </\{name}> 在顶层"),
        )
    }
  }
  Ok(elements)
}

// ============================================================
// 内部: XmlElement 查询辅助
// ============================================================

///|
fn find_child(el : XmlElement, name : String) -> XmlElement? {
  for i = 0; i < el.children.length(); i = i + 1 {
    if el.children[i].name == name {
      return Some(el.children[i])
    }
  }
  None
}

///|
fn find_children(el : XmlElement, name : String) -> Array[XmlElement] {
  let result : Array[XmlElement] = []
  for i = 0; i < el.children.length(); i = i + 1 {
    if el.children[i].name == name {
      result.push(el.children[i])
    }
  }
  result
}

///|
fn get_attr(el : XmlElement, name : String) -> String? {
  for i = 0; i < el.attrs.length(); i = i + 1 {
    let (n, v) = el.attrs[i]
    if n == name {
      return Some(v)
    }
  }
  None
}

///|
fn parse_child_int(
  el : XmlElement,
  child_name : String,
) -> Result[Int, MusicXmlError] {
  match find_child(el, child_name) {
    Some(child) => parse_int_text(child.text)
    None => Err(MusicXmlImportError("缺少必需元素: \{child_name}"))
  }
}

///|
fn parse_opt_child_int(
  el : XmlElement,
  child_name : String,
) -> Result[Int, MusicXmlError] {
  match find_child(el, child_name) {
    Some(child) => parse_int_text(child.text)
    None => Ok(1)
  }
}

// ============================================================
// 内部: MusicXML 类型转换辅助
// ============================================================

///|
fn xml_type_to_note_type(s : String) -> Result[MusicXmlNoteType, MusicXmlError] {
  let t = trim_str(s)
  match t {
    "whole" => Ok(WholeT)
    "half" => Ok(HalfT)
    "quarter" => Ok(QuarterT)
    "eighth" => Ok(EighthT)
    "16th" => Ok(SixteenthT)
    "32nd" => Ok(ThirtySecondT)
    "64th" => Ok(SixtyFourthT)
    "128th" => Ok(OneTwentyEighthT)
    _ => Err(MusicXmlImportError("未知音符类型: \{t}"))
  }
}

///|
fn note_type_to_dur_unit(nt : MusicXmlNoteType) -> @time.DurUnit {
  match nt {
    WholeT => @time.DurWhole
    HalfT => @time.DurHalf
    QuarterT => @time.DurQuarter
    EighthT => @time.DurEighth
    SixteenthT => @time.DurSixteenth
    ThirtySecondT => @time.ThirtySecond
    SixtyFourthT => @time.SixtyFourth
    OneTwentyEighthT => @time.OneTwentyEighth
  }
}

///|
fn alter_to_accidental(alter : Int) -> @pitch.Accidental {
  match alter {
    -2 => @pitch.DoubleFlat
    -1 => @pitch.Flat
    0 => @pitch.Natural
    1 => @pitch.Sharp
    2 => @pitch.DoubleSharp
    _ => @pitch.Natural
  }
}

///|
fn mx_pitch_to_pitch(mp : MusicXmlPitch) -> Result[@pitch.Pitch, MusicXmlError] {
  let pc = match mp.step {
    "C" => @pitch.C
    "D" => @pitch.D
    "E" => @pitch.E
    "F" => @pitch.F
    "G" => @pitch.G
    "A" => @pitch.A
    "B" => @pitch.B
    _ => return Err(MusicXmlImportError("未知音名: \{mp.step}"))
  }
  Ok(@pitch.pitch(pc, alter_to_accidental(mp.alter), mp.octave))
}

///|
fn mx_note_to_rhythm_duration(n : MusicXmlNote) -> @time.RhythmDuration {
  @time.rhythm_duration(note_type_to_dur_unit(n.note_type), n.dots, None)
}

// ============================================================
// 内部: MusicXML 元素提取
// ============================================================

///|
fn extract_pitch(el : XmlElement) -> Result[MusicXmlPitch, MusicXmlError] {
  let step = match find_child(el, "step") {
    Some(s) => trim_str(s.text)
    None => return Err(MusicXmlImportError("缺少 <step> 元素"))
  }
  let alter = match find_child(el, "alter") {
    Some(a) => {
      let parsed = parse_int_text(a.text)
      match parsed {
        Ok(v) => v
        Err(e) => return Err(e)
      }
    }
    None => 0
  }
  let octave = match find_child(el, "octave") {
    Some(o) => {
      let parsed = parse_int_text(o.text)
      match parsed {
        Ok(v) => v
        Err(e) => return Err(e)
      }
    }
    None => return Err(MusicXmlImportError("缺少 <octave> 元素"))
  }
  Ok(MusicXmlPitch::{ step, alter, octave })
}

///|
fn extract_note(
  el : XmlElement,
  warnings : Array[String],
) -> Result[MusicXmlNote, MusicXmlError] {
  let is_rest = match find_child(el, "rest") {
    Some(_) => true
    None => false
  }
  let is_chord = match find_child(el, "chord") {
    Some(_) => true
    None => false
  }

  let pitch = if is_rest {
    None
  } else {
    match find_child(el, "pitch") {
      Some(pitch_el) => {
        let parsed = extract_pitch(pitch_el)
        match parsed {
          Ok(p) => Some(p)
          Err(e) => return Err(e)
        }
      }
      None => {
        warnings.push("note 缺少 <pitch>, 视为休止符")
        None
      }
    }
  }

  // 检查 tie
  match find_child(el, "tie") {
    Some(_) => warnings.push("导入暂不完全支持 <tie>, 忽略")
    None => ()
  }
  // 检查 lyric
  match find_child(el, "lyric") {
    Some(_) => warnings.push("导入暂不支持 <lyric>, 忽略")
    None => ()
  }

  let duration = match parse_child_int(el, "duration") {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let note_type = match find_child(el, "type") {
    Some(t) => {
      let parsed = xml_type_to_note_type(t.text)
      match parsed {
        Ok(nt) => nt
        Err(e) => return Err(e)
      }
    }
    None => return Err(MusicXmlImportError("缺少 <type> 元素"))
  }
  let dots = find_children(el, "dot").length()
  let voice = match parse_opt_child_int(el, "voice") {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let staff = match parse_opt_child_int(el, "staff") {
    Ok(v) => v
    Err(e) => return Err(e)
  }

  Ok(MusicXmlNote::{
    pitch,
    duration,
    note_type,
    dots,
    is_rest,
    is_chord_tone: is_chord,
    voice,
    staff,
  })
}

///|
fn extract_attributes(
  el : XmlElement,
) -> Result[MusicXmlAttributes, MusicXmlError] {
  let divisions = match parse_child_int(el, "divisions") {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let time_el = match find_child(el, "time") {
    Some(t) => t
    None => return Err(MusicXmlImportError("缺少 <time> 元素"))
  }
  let beats = match parse_child_int(time_el, "beats") {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let beat_type = match parse_child_int(time_el, "beat-type") {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let sig = @time.time_signature(beats, beat_type)
  Ok(MusicXmlAttributes::{ divisions, time_signature: sig })
}

///|
fn extract_measure(
  el : XmlElement,
  warnings : Array[String],
) -> Result[MusicXmlMeasure, MusicXmlError] {
  let number = match get_attr(el, "number") {
    Some(n) => {
      let parsed = parse_int_text(n)
      match parsed {
        Ok(v) => v
        Err(e) => return Err(e)
      }
    }
    None => 1
  }
  let attrs = match find_child(el, "attributes") {
    Some(a) => {
      let parsed = extract_attributes(a)
      match parsed {
        Ok(v) => Some(v)
        Err(e) => return Err(e)
      }
    }
    None => None
  }
  let notes : Array[MusicXmlNote] = []
  let note_els = find_children(el, "note")
  for i = 0; i < note_els.length(); i = i + 1 {
    let n = match extract_note(note_els[i], warnings) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    notes.push(n)
  }
  // 记录不支持的元素
  if find_children(el, "direction").length() > 0 {
    warnings.push("导入暂不支持 <direction>, 已忽略")
  }
  if find_children(el, "backup").length() > 0 {
    warnings.push("导入暂不支持 <backup>, 已忽略")
  }
  if find_children(el, "forward").length() > 0 {
    warnings.push("导入暂不支持 <forward>, 已忽略")
  }
  Ok(MusicXmlMeasure::{ number, attributes: attrs, notes })
}

///|
fn extract_part(
  el : XmlElement,
  part_name : String,
  warnings : Array[String],
) -> Result[MusicXmlPart, MusicXmlError] {
  let id = match get_attr(el, "id") {
    Some(v) => v
    None => "P1"
  }
  let measures : Array[MusicXmlMeasure] = []
  let meas_els = find_children(el, "measure")
  for i = 0; i < meas_els.length(); i = i + 1 {
    let m = match extract_measure(meas_els[i], warnings) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    measures.push(m)
  }
  Ok(MusicXmlPart::{ id, name: part_name, measures })
}

///|
fn extract_part_list_names(el : XmlElement) -> Array[(String, String)] {
  let result : Array[(String, String)] = []
  let score_parts = find_children(el, "score-part")
  for i = 0; i < score_parts.length(); i = i + 1 {
    let sp = score_parts[i]
    let id = match get_attr(sp, "id") {
      Some(v) => v
      None => "P\{i + 1}"
    }
    let name = match find_child(sp, "part-name") {
      Some(pn) => trim_str(pn.text)
      None => id
    }
    result.push((id, name))
  }
  result
}

///|
fn extract_score(
  root : XmlElement,
  warnings : Array[String],
) -> Result[MusicXmlScore, MusicXmlError] {
  if root.name != "score-partwise" {
    return Err(
      MusicXmlImportError(
        "根元素必须是 <score-partwise>, 当前: \{root.name}",
      ),
    )
  }

  // 解析 part-list 获取名称映射
  let part_names = match find_child(root, "part-list") {
    Some(pl) => extract_part_list_names(pl)
    None => []
  }

  // 解析所有 part
  let parts : Array[MusicXmlPart] = []
  let part_els = find_children(root, "part")
  for i = 0; i < part_els.length(); i = i + 1 {
    let raw_id = match get_attr(part_els[i], "id") {
      Some(v) => v
      None => "P\{i + 1}"
    }
    // 从 part-list 查找名称
    let mut part_name = raw_id
    for j = 0; j < part_names.length(); j = j + 1 {
      let (nid, nname) = part_names[j]
      if nid == raw_id {
        part_name = nname
      }
    }
    let p = match extract_part(part_els[i], part_name, warnings) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    parts.push(p)
  }

  // 从第一个有 attributes 的 measure 获取 divisions
  let mut divisions = 480
  for i = 0; i < parts.length(); i = i + 1 {
    for j = 0; j < parts[i].measures.length(); j = j + 1 {
      match parts[i].measures[j].attributes {
        Some(a) => {
          divisions = a.divisions
          break
        }
        None => ()
      }
    }
  }

  Ok(MusicXmlScore::{ title: "", parts, divisions })
}

// ============================================================
// MusicXmlScore → ScoreLayout 转换
// ============================================================

///|
fn make_event_id(
  prefix : String,
  measure_num : Int,
  idx : Int,
) -> Result[@score.EventId, MusicXmlError] {
  let id_str = "\{prefix}\{measure_num}_\{idx}"
  match @score.event_id_checked(id_str) {
    Ok(v) => Ok(v)
    Err(e) => Err(MusicXmlImportError("ID无效: \{e.to_string()}"))
  }
}

///|
fn mx_measure_to_score_events(
  m : MusicXmlMeasure,
  warnings : Array[String],
) -> Result[Array[@score.ScoreEvent], MusicXmlError] {
  let events : Array[@score.ScoreEvent] = []
  let notes = m.notes
  let mut i = 0
  while i < notes.length() {
    let n = notes[i]
    if n.is_rest {
      let rd = mx_note_to_rhythm_duration(n)
      let eid = match make_event_id("r", m.number, i) {
        Ok(v) => v
        Err(e) => return Err(e)
      }
      let evt = match @score.rest_event_checked(eid, rd, true) {
        Ok(v) => v
        Err(e) =>
          return Err(
            MusicXmlImportError("构造RestEvent失败: \{e.to_string()}"),
          )
      }
      events.push(evt)
      i = i + 1
    } else if n.is_chord_tone {
      warnings.push("孤立的 <chord> 音符, 作为独立 Note 处理")
      match n.pitch {
        Some(p) => {
          let pitch = match mx_pitch_to_pitch(p) {
            Ok(v) => v
            Err(e) => return Err(e)
          }
          let rd = mx_note_to_rhythm_duration(n)
          let eid = match make_event_id("n", m.number, i) {
            Ok(v) => v
            Err(e) => return Err(e)
          }
          let evt = match
            @score.note_event_checked(eid, pitch, rd, None, @score.NoTie, [], []) {
            Ok(v) => v
            Err(e) =>
              return Err(
                MusicXmlImportError("构造NoteEvent失败: \{e.to_string()}"),
              )
          }
          events.push(evt)
        }
        None => {
          let rd = mx_note_to_rhythm_duration(n)
          let eid = match make_event_id("r", m.number, i) {
            Ok(v) => v
            Err(e) => return Err(e)
          }
          let evt = match @score.rest_event_checked(eid, rd, true) {
            Ok(v) => v
            Err(e) =>
              return Err(
                MusicXmlImportError("构造RestEvent失败: \{e.to_string()}"),
              )
          }
          events.push(evt)
        }
      }
      i = i + 1
    } else {
      // 检查后续是否为 chord
      let mut j = i + 1
      while j < notes.length() && notes[j].is_chord_tone {
        j = j + 1
      }
      if j > i + 1 {
        // ChordEvent: 收集所有音高
        let pitches : Array[@pitch.Pitch] = []
        for k = i; k < j; k = k + 1 {
          match notes[k].pitch {
            Some(p) => {
              let pitch = match mx_pitch_to_pitch(p) {
                Ok(v) => v
                Err(e) => return Err(e)
              }
              pitches.push(pitch)
            }
            None => warnings.push("chord 音符缺少 pitch")
          }
        }
        if pitches.length() == 0 {
          let rd = mx_note_to_rhythm_duration(n)
          let eid = match make_event_id("r", m.number, i) {
            Ok(v) => v
            Err(e) => return Err(e)
          }
          let evt = match @score.rest_event_checked(eid, rd, true) {
            Ok(v) => v
            Err(e) =>
              return Err(
                MusicXmlImportError("构造RestEvent失败: \{e.to_string()}"),
              )
          }
          events.push(evt)
        } else if pitches.length() == 1 {
          let rd = mx_note_to_rhythm_duration(n)
          let eid = match make_event_id("n", m.number, i) {
            Ok(v) => v
            Err(e) => return Err(e)
          }
          let evt = match
            @score.note_event_checked(
              eid,
              pitches[0],
              rd,
              None,
              @score.NoTie,
              [],
              [],
            ) {
            Ok(v) => v
            Err(e) =>
              return Err(
                MusicXmlImportError("构造NoteEvent失败: \{e.to_string()}"),
              )
          }
          events.push(evt)
        } else {
          let rd = mx_note_to_rhythm_duration(n)
          let eid = match make_event_id("c", m.number, i) {
            Ok(v) => v
            Err(e) => return Err(e)
          }
          let evt = match
            @score.chord_event_checked(
              eid,
              pitches,
              rd,
              None,
              @score.NoTie,
              [],
              [],
            ) {
            Ok(v) => v
            Err(e) =>
              return Err(
                MusicXmlImportError("构造ChordEvent失败: \{e.to_string()}"),
              )
          }
          events.push(evt)
        }
        i = j
      } else {
        // NoteEvent
        match n.pitch {
          Some(p) => {
            let pitch = match mx_pitch_to_pitch(p) {
              Ok(v) => v
              Err(e) => return Err(e)
            }
            let rd = mx_note_to_rhythm_duration(n)
            let eid = match make_event_id("n", m.number, i) {
              Ok(v) => v
              Err(e) => return Err(e)
            }
            let evt = match
              @score.note_event_checked(
                eid,
                pitch,
                rd,
                None,
                @score.NoTie,
                [],
                [],
              ) {
              Ok(v) => v
              Err(e) =>
                return Err(
                  MusicXmlImportError("构造NoteEvent失败: \{e.to_string()}"),
                )
            }
            events.push(evt)
          }
          None => {
            let rd = mx_note_to_rhythm_duration(n)
            let eid = match make_event_id("r", m.number, i) {
              Ok(v) => v
              Err(e) => return Err(e)
            }
            let evt = match @score.rest_event_checked(eid, rd, true) {
              Ok(v) => v
              Err(e) =>
                return Err(
                  MusicXmlImportError("构造RestEvent失败: \{e.to_string()}"),
                )
            }
            events.push(evt)
          }
        }
        i = i + 1
      }
    }
  }
  Ok(events)
}

///|
fn mx_measure_to_layout_measure(
  m : MusicXmlMeasure,
  idx : Int,
  warnings : Array[String],
) -> Result[@score.Measure, MusicXmlError] {
  let m_idx = match @score.measure_index_checked(idx) {
    Ok(v) => v
    Err(e) =>
      return Err(MusicXmlImportError("小节索引无效: \{e.to_string()}"))
  }
  let ts = match m.attributes {
    Some(a) => Some(a.time_signature)
    None => None
  }
  let events = match mx_measure_to_score_events(m, warnings) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let ms = match
    @score.measure_checked(
      m_idx,
      @score.NormalMeasure,
      ts,
      None,
      None,
      events,
      None,
    ) {
    Ok(v) => v
    Err(e) =>
      return Err(MusicXmlImportError("构造Measure失败: \{e.to_string()}"))
  }
  Ok(ms)
}

///|
fn mx_part_to_layout_part(
  p : MusicXmlPart,
  warnings : Array[String],
) -> Result[@score.Part, MusicXmlError] {
  let measures : Array[@score.Measure] = []
  for j = 0; j < p.measures.length(); j = j + 1 {
    let m = match mx_measure_to_layout_measure(p.measures[j], j, warnings) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    measures.push(m)
  }

  let voice_id = match @score.voice_id_checked("v1") {
    Ok(v) => v
    Err(e) =>
      return Err(MusicXmlImportError("Voice ID无效: \{e.to_string()}"))
  }
  let voice = match @score.voice_checked(voice_id, "Voice 1", measures) {
    Ok(v) => v
    Err(e) =>
      return Err(MusicXmlImportError("构造Voice失败: \{e.to_string()}"))
  }

  let staff_id = match @score.staff_id_checked("s1") {
    Ok(v) => v
    Err(e) =>
      return Err(MusicXmlImportError("Staff ID无效: \{e.to_string()}"))
  }
  let staff = match
    @score.staff_checked(staff_id, p.name, @score.Treble, None, None, [voice]) {
    Ok(v) => v
    Err(e) =>
      return Err(MusicXmlImportError("构造Staff失败: \{e.to_string()}"))
  }

  let part_id = match @score.part_id_checked(p.id) {
    Ok(v) => v
    Err(e) => return Err(MusicXmlImportError("Part ID无效: \{e.to_string()}"))
  }
  let part = match @score.part_checked(part_id, p.name, "", [staff]) {
    Ok(v) => v
    Err(e) =>
      return Err(MusicXmlImportError("构造Part失败: \{e.to_string()}"))
  }
  Ok(part)
}

///|
fn mx_score_to_layout(
  mx : MusicXmlScore,
  warnings : Array[String],
) -> Result[@score.ScoreLayout, MusicXmlError] {
  let parts : Array[@score.Part] = []
  for i = 0; i < mx.parts.length(); i = i + 1 {
    let part = match mx_part_to_layout_part(mx.parts[i], warnings) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    parts.push(part)
  }

  let init_sig = if mx.parts.length() > 0 && mx.parts[0].measures.length() > 0 {
    match mx.parts[0].measures[0].attributes {
      Some(a) => a.time_signature
      None => @time.four_four()
    }
  } else {
    @time.four_four()
  }

  let sid = match @score.score_id_checked("imported") {
    Ok(v) => v
    Err(e) =>
      return Err(MusicXmlImportError("Score ID无效: \{e.to_string()}"))
  }
  let ppq = match @score.ppq_checked(mx.divisions) {
    Ok(v) => v
    Err(e) => return Err(MusicXmlImportError("PPQ无效: \{e.to_string()}"))
  }
  let tempo = match @score.tempo_checked(120) {
    Ok(v) => v
    Err(e) => return Err(MusicXmlImportError("Tempo无效: \{e.to_string()}"))
  }
  let metadata = match @score.score_metadata_checked("", "", "", "", []) {
    Ok(v) => v
    Err(e) =>
      return Err(MusicXmlImportError("Metadata无效: \{e.to_string()}"))
  }
  match
    @score.score_layout_checked(
      sid,
      mx.title,
      "",
      ppq,
      tempo,
      init_sig,
      parts,
      [],
      [],
      [],
      [],
      [],
      metadata,
    ) {
    Ok(layout) => Ok(layout)
    Err(e) =>
      Err(MusicXmlImportError("构造ScoreLayout失败: \{e.to_string()}"))
  }
}

// ============================================================
// 公开 API
// ============================================================

///|
/// 解析 MusicXML XML 字符串, 返回 MusicXmlScore
pub fn parse_musicxml_xml_checked(
  xml : String,
) -> Result[MusicXmlScore, MusicXmlError] {
  let tokens = match tokenize_xml(xml) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let elements = match parse_all(tokens) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  if elements.length() == 0 {
    return Err(MusicXmlImportError("XML 中未找到任何元素"))
  }
  let warnings : Array[String] = []
  extract_score(elements[0], warnings)
}

///|
/// 将 MusicXmlScore 转换为 ScoreLayout
pub fn musicxml_score_to_layout_checked(
  mx_score : MusicXmlScore,
) -> Result[@score.ScoreLayout, MusicXmlError] {
  let warnings : Array[String] = []
  mx_score_to_layout(mx_score, warnings)
}

///|
/// 一步到位: MusicXML XML 字符串 -> ScoreLayout
pub fn musicxml_string_to_layout_checked(
  xml : String,
) -> Result[@score.ScoreLayout, MusicXmlError] {
  let mx_score = match parse_musicxml_xml_checked(xml) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  musicxml_score_to_layout_checked(mx_score)
}

///|
/// 导入 MusicXML, 返回 ScoreLayout 和导入报告
pub fn musicxml_string_to_import_result_checked(
  xml : String,
) -> Result[MusicXmlImportResult, MusicXmlError] {
  let tokens = match tokenize_xml(xml) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let elements = match parse_all(tokens) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  if elements.length() == 0 {
    return Err(MusicXmlImportError("XML 中未找到任何元素"))
  }
  let warnings : Array[String] = []
  let unsupported : Array[String] = []
  let mx_score = match extract_score(elements[0], warnings) {
    Ok(v) => v
    Err(e) => return Err(e)
  }

  let part_count = mx_score.parts.length()
  let mut measure_count = 0
  for i = 0; i < mx_score.parts.length(); i = i + 1 {
    measure_count = measure_count + mx_score.parts[i].measures.length()
  }

  for i = 0; i < warnings.length(); i = i + 1 {
    unsupported.push(warnings[i])
  }

  let layout = match mx_score_to_layout(mx_score, warnings) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  Ok(MusicXmlImportResult::{
    layout,
    report: MusicXmlImportReport::{
      warnings,
      unsupported_elements: unsupported,
      part_count,
      measure_count,
    },
  })
}
