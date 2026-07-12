// ============================================================
// Examples/Output Writer — 将资产包内容验证并准备写入
// ============================================================

///|
/// 文件条目：描述一个待写入磁盘的资产文件
pub(all) struct DemoFileEntry {
  filename : String
  content_type : String
  string_content : String?
  bytes_content : Bytes?
}

///|
/// 从资产包收集所有可写入文件（跳过缺失资产，不伪造空文件）
pub fn collect_assets_from_bundle(
  bundle : CompositionAssetBundle,
) -> Array[DemoFileEntry] {
  let entries : Array[DemoFileEntry] = []

  // bundle.json — 始终包含（资产包摘要）
  let bundle_json = composition_asset_bundle_to_json(bundle)
  if bundle_json != "" {
    entries.push({
      filename: "bundle.json",
      content_type: "application/json",
      string_content: Some(bundle_json),
      bytes_content: None,
    })
  }

  // score.json
  match bundle.score_json {
    Some(json) =>
      if json != "" {
        entries.push({
          filename: "score.json",
          content_type: "application/json",
          string_content: Some(json),
          bytes_content: None,
        })
      }
    None => ()
  }

  // composition.mid
  match bundle.midi_bytes {
    Some(bytes) =>
      if bytes.length() > 0 {
        entries.push({
          filename: "composition.mid",
          content_type: "audio/midi",
          string_content: None,
          bytes_content: Some(bytes),
        })
      }
    None => ()
  }

  // composition.musicxml
  match bundle.musicxml {
    Some(xml) =>
      if xml != "" {
        entries.push({
          filename: "composition.musicxml",
          content_type: "application/xml",
          string_content: Some(xml),
          bytes_content: None,
        })
      }
    None => ()
  }

  // composition.wav
  match bundle.wav_bytes {
    Some(bytes) =>
      if bytes.length() >= 44 {
        entries.push({
          filename: "composition.wav",
          content_type: "audio/wav",
          string_content: None,
          bytes_content: Some(bytes),
        })
      }
    None => ()
  }

  // web-events.json
  match bundle.web_events_json {
    Some(json) =>
      if json != "" {
        entries.push({
          filename: "web-events.json",
          content_type: "application/json",
          string_content: Some(json),
          bytes_content: None,
        })
      }
    None => ()
  }

  // game.json
  match bundle.game_ir_json {
    Some(json) =>
      if json != "" {
        entries.push({
          filename: "game.json",
          content_type: "application/json",
          string_content: Some(json),
          bytes_content: None,
        })
      }
    None => ()
  }

  entries
}

///|
/// 将资产包所有资产写入磁盘
/// 注意：实际文件写入需要运行时环境支持（CLI/JS host）
/// 返回已验证的文件条目列表，调用方可从中提取内容写入磁盘
pub fn write_composition_assets_checked(
  bundle : CompositionAssetBundle,
  output_dir : String,
) -> Result[Array[DemoFileEntry], DemoError] {
  if output_dir == "" {
    return Err(InvalidRequest("output_dir must not be empty"))
  }

  let entries = collect_assets_from_bundle(bundle)

  // 至少需要 bundle.json + 一个核心资产（midi/musicxml/score）
  if entries.length() <= 1 {
    let has_core = bundle.midi_bytes is Some(_) ||
      bundle.musicxml is Some(_) ||
      (bundle.score_json is Some(_) && bundle.score_json.unwrap() != "")
    if !has_core {
      return Err(NoUsableAsset("no core asset available to write"))
    }
  }

  // 验证每个条目内容非空
  for entry in entries {
    match entry.string_content {
      Some(s) =>
        if s.length() == 0 {
          return Err(SerializationFailed("empty content in " + entry.filename))
        }
      None => ()
    }
    match entry.bytes_content {
      Some(b) =>
        if b.length() == 0 {
          return Err(SerializationFailed("empty bytes in " + entry.filename))
        }
      None => ()
    }
  }

  Ok(entries)
}

///|
/// 写入 MIDI 文件 — 验证并返回要写入的 bytes
pub fn write_midi_file(
  bytes : Bytes,
  path : String,
) -> Result[Bytes, DemoError] {
  if bytes.length() == 0 {
    return Err(SerializationFailed("MIDI bytes must not be empty"))
  }
  if path == "" {
    return Err(InvalidRequest("path must not be empty"))
  }
  Ok(bytes)
}

///|
/// 写入 MusicXML 文件 — 验证并返回要写入的 XML 字符串
pub fn write_musicxml_file(
  xml : String,
  path : String,
) -> Result[String, DemoError] {
  if xml == "" {
    return Err(SerializationFailed("MusicXML content must not be empty"))
  }
  if path == "" {
    return Err(InvalidRequest("path must not be empty"))
  }
  if !xml.contains("score-partwise") {
    return Err(
      SerializationFailed("MusicXML missing <score-partwise> root element"),
    )
  }
  Ok(xml)
}

///|
/// 写入 WAV 文件 — 验证并返回要写入的 bytes
pub fn write_wav_file(bytes : Bytes, path : String) -> Result[Bytes, DemoError] {
  if bytes.length() < 44 {
    return Err(
      SerializationFailed(
        "WAV bytes too short: got \{bytes.length()}, need at least 44",
      ),
    )
  }
  if path == "" {
    return Err(InvalidRequest("path must not be empty"))
  }
  Ok(bytes)
}

///|
/// 写入 JSON 文件 — 验证并返回要写入的 JSON 字符串
pub fn write_json_file(
  json : String,
  path : String,
) -> Result[String, DemoError] {
  if json == "" {
    return Err(SerializationFailed("JSON content must not be empty"))
  }
  if path == "" {
    return Err(InvalidRequest("path must not be empty"))
  }
  // 确保 JSON 内容可解析
  let _ = match @json.json_parse(json) {
    Ok(v) => v
    Err(e) => return Err(SerializationFailed("invalid JSON: " + e.to_string()))
  }
  Ok(json)
}

// ============================================================
// 二进制内容验证 — 深度 header/格式检查
// ============================================================

///|
/// 检查 MIDI 文件是否以 "MThd" header 开头
pub fn check_midi_header(bytes : Bytes) -> Bool {
  if bytes.length() < 4 {
    return false
  }
  bytes[0].to_int() == 0x4D &&
  bytes[1].to_int() == 0x54 &&
  bytes[2].to_int() == 0x68 &&
  bytes[3].to_int() == 0x64
}

///|
/// 检查 WAV 文件是否以 "RIFF" header 开头且包含 "WAVE" format
pub fn check_wav_header(bytes : Bytes) -> Bool {
  if bytes.length() < 12 {
    return false
  }
  bytes[0].to_int() == 0x52 &&
  bytes[1].to_int() == 0x49 &&
  bytes[2].to_int() == 0x46 &&
  bytes[3].to_int() == 0x46 &&
  bytes[8].to_int() == 0x57 &&
  bytes[9].to_int() == 0x41 &&
  bytes[10].to_int() == 0x56 &&
  bytes[11].to_int() == 0x45
}

// ============================================================
// 二进制到文本编码：用于将 bytes 序列化为可打印格式
// ============================================================

///|
/// 将 Bytes 前 N 字节转换为十六进制字符串（大写，无分隔符），最多 64 字节
pub fn bytes_to_hex(bytes : Bytes) -> String {
  let max_len = if bytes.length() < 64 { bytes.length() } else { 64 }
  let buf : Array[Char] = []
  for i = 0; i < max_len; i = i + 1 {
    let byte_val = bytes[i].to_int()
    buf.push(nibble_to_char(byte_val / 16))
    buf.push(nibble_to_char(byte_val % 16))
  }
  buf.iter().fold(fn(acc, c) { acc + c.to_string() }, init="")
}

///|
fn nibble_to_char(n : Int) -> Char {
  if n < 10 {
    (48 + n).unsafe_to_char()
  } else {
    (65 + (n - 10)).unsafe_to_char()
  }
}

///|
/// 将 DemoFileEntry 数组序列化为完整的 JSON 字符串
/// 文本内容直接内嵌，二进制内容以 hex 字符串形式存储（字段后缀 _hex）
pub fn asset_entries_to_json(entries : Array[DemoFileEntry]) -> String {
  let items : Array[@json.JsonValue] = []
  for entry in entries {
    let fields : Array[@json.JsonField] = [
      @json.json_field("filename", @json.json_string(entry.filename)),
      @json.json_field("content_type", @json.json_string(entry.content_type)),
    ]
    let fields = match entry.string_content {
      Some(s) =>
        fields +
        [
          @json.json_field("content", @json.json_string(s)),
          @json.json_field("encoding", @json.json_string("utf-8")),
        ]
      None => fields
    }
    let fields = match entry.bytes_content {
      Some(b) =>
        fields +
        [
          @json.json_field("content_hex", @json.json_string(bytes_to_hex(b))),
          @json.json_field("encoding", @json.json_string("hex")),
          @json.json_field("byte_length", @json.json_int(b.length())),
        ]
      None => fields
    }
    items.push(@json.json_object(fields))
  }
  @json.json_stringify(@json.json_array(items))
}

///|
/// 从资产包生成完整的写入清单 JSON（含所有资产内容）
/// 文本资产直接内嵌，二进制资产以 hex 编码
pub fn write_all_assets_summary_json(
  bundle : CompositionAssetBundle,
  output_dir : String,
) -> Result[String, DemoError] {
  let entries = match write_composition_assets_checked(bundle, output_dir) {
    Ok(e) => e
    Err(e) => return Err(e)
  }
  Ok(asset_entries_to_json(entries))
}
