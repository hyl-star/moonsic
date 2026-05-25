// Shared JSON response helpers for string-only FFI entry points.

///|
fn ffi_ok_value(value_json : String) -> String {
  "{\"ok\":true,\"value\":" + value_json + "}"
}

///|
fn ffi_ok_data(data_json : String) -> String {
  "{\"ok\":true,\"data\":" + data_json + "}"
}

///|
fn ffi_ok_field(name : String, value_json : String) -> String {
  "{\"ok\":true,\"" + name + "\":" + value_json + "}"
}

///|
fn ffi_error(error : String, message : String) -> String {
  "{\"ok\":false,\"error\":" +
  json_escape(error) +
  ",\"message\":" +
  json_escape(message) +
  "}"
}
