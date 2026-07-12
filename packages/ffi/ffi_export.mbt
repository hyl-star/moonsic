///|
pub fn ffi_simple_score_to_musicxml_json(input : String) -> String {
  let score = match @adapter.simple_score_from_json_checked(input) {
    Ok(result) => result
    Err(e) => return ffi_error(FfiExportError(e.to_string()))
  }
  match
    @musicxml.simple_score_to_musicxml_string_checked(
      score,
      @musicxml.default_musicxml_export_options(),
    ) {
    Ok(xml) => ffi_ok(xml_payload(xml))
    Err(e) => ffi_error(FfiExportError(e.to_string()))
  }
}

///|
pub fn ffi_simple_score_to_midi_json(input : String) -> String {
  let score = match @adapter.simple_score_from_json_checked(input) {
    Ok(result) => result
    Err(e) => return ffi_error(FfiExportError(e.to_string()))
  }
  match @midi.simple_score_to_midi_bytes_checked(score, 480) {
    Ok(bytes) => ffi_ok(bytes_payload(bytes))
    Err(e) => ffi_error(FfiExportError(e.to_string()))
  }
}
