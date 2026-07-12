///|
pub fn ffi_external_generate_mock_json(input : String) -> String {
  match generation_request_from_json(input) {
    Ok(request) =>
      match deterministic_mock_generate(request) {
        Ok(response) => ffi_ok_json(generation_response_to_json(response))
        Err(e) => ffi_error("AdapterError", e.to_string())
      }
    Err(e) => ffi_error("AdapterError", e.to_string())
  }
}

///|
pub fn ffi_validate_generation_patch_json(input : String) -> String {
  match @json.json_parse(input) {
    Ok(root) => {
      let fields = match json_object_fields(root) {
        Ok(result) => result
        Err(e) => return ffi_error("AdapterError", e.to_string())
      }
      let request_value = match json_lookup_required(fields, "request") {
        Ok(result) => result
        Err(e) => return ffi_error("AdapterError", e.to_string())
      }
      let request = match generation_request_from_json_value(request_value) {
        Ok(result) => result
        Err(e) => return ffi_error("AdapterError", e.to_string())
      }
      let patch_value = match json_lookup_required(fields, "patch") {
        Ok(result) => result
        Err(e) => return ffi_error("AdapterError", e.to_string())
      }
      let patch = match generation_patch_from_json_value(patch_value) {
        Ok(result) => result
        Err(e) => return ffi_error("AdapterError", e.to_string())
      }
      match validate_generation_patch(patch, request.context) {
        Ok(_) => ffi_ok_json("{\"valid\":true}")
        Err(e) => ffi_error("AdapterError", e.to_string())
      }
    }
    Err(e) => ffi_error("AdapterError", e.to_string())
  }
}

///|
fn ffi_ok_json(data : String) -> String {
  "{\"ok\":true,\"data\":" + data + "}"
}

///|
fn ffi_error(kind : String, message : String) -> String {
  "{\"ok\":false,\"error\":\"" +
  @json.json_escape(kind) +
  "\",\"message\":\"" +
  @json.json_escape(message) +
  "\"}"
}
