// ============================================================
// MusicXmlError
// ============================================================

///|
pub(all) enum MusicXmlError {
  InvalidMusicXmlOptions(String)
  MusicXmlUnsupported(String)
  MusicXmlDurationError(String)
  MusicXmlPitchError(String)
  MusicXmlMeasureError(String)
  MusicXmlSerializationError(String)
  MusicXmlImportError(String)
}

///|
pub fn MusicXmlError::to_string(self : MusicXmlError) -> String {
  match self {
    InvalidMusicXmlOptions(msg) => "无效 MusicXML 选项：\{msg}"
    MusicXmlUnsupported(msg) => "MusicXML 不支持：\{msg}"
    MusicXmlDurationError(msg) => "MusicXML 时值错误：\{msg}"
    MusicXmlPitchError(msg) => "MusicXML 音高错误：\{msg}"
    MusicXmlMeasureError(msg) => "MusicXML 小节错误：\{msg}"
    MusicXmlSerializationError(msg) => "MusicXML 序列化错误：\{msg}"
    MusicXmlImportError(msg) => "MusicXML 导入错误：\{msg}"
  }
}
