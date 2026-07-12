///|
pub fn bench_json_stringify(count : Int) -> String {
  let value = json_object([
    json_field("name", json_string("moonsic")),
    json_field("ok", json_bool(true)),
    json_field("items", json_array([json_int(1), json_int(2), json_int(3)])),
  ])
  let mut size = 0
  for i = 0; i < count; i = i + 1 {
    size = size + json_stringify(value).length()
  }
  "json_stringify count=\{count} bytes=\{size}"
}

///|
pub fn bench_json_parse(count : Int) -> String {
  let input = "{\"name\":\"moonsic\",\"ok\":true,\"items\":[1,2,3]}"
  let mut parsed = 0
  for i = 0; i < count; i = i + 1 {
    match json_parse(input) {
      Ok(_) => parsed = parsed + 1
      Err(_) => ()
    }
  }
  "json_parse count=\{count} parsed=\{parsed}"
}
