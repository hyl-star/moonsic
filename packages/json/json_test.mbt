// Basic JSON package tests.

///|
test "stringify_null_bool_number" {
  assert_eq(@json.json_stringify(@json.json_null()), "null")
  assert_eq(@json.json_stringify(@json.json_bool(true)), "true")
  assert_eq(@json.json_stringify(@json.json_int(12)), "12")
}

///|
test "stringify_string_escapes" {
  assert_eq(@json.json_stringify(@json.json_string("a\"b")), "\"a\\\"b\"")
  assert_eq(@json.json_stringify(@json.json_string("a\nb")), "\"a\\nb\"")
}

///|
test "stringify_array" {
  let value = @json.json_array([@json.json_int(1), @json.json_string("x")])
  assert_eq(@json.json_stringify(value), "[1,\"x\"]")
}

///|
test "stringify_object" {
  let value = @json.json_object([
    @json.json_field("a", @json.json_int(1)),
    @json.json_field("b", @json.json_bool(false)),
  ])
  assert_eq(@json.json_stringify(value), "{\"a\":1,\"b\":false}")
}

///|
test "parse_object_lookup" {
  let value = @json.json_parse("{\"a\":1,\"b\":\"x\"}").unwrap()
  let fields = @json.json_as_object(value).unwrap()
  assert_eq(
    @json.json_as_int(@json.json_lookup(fields, "a").unwrap()).unwrap(),
    1,
  )
  assert_eq(
    @json.json_as_string(@json.json_lookup(fields, "b").unwrap()).unwrap(),
    "x",
  )
}

///|
test "parse_array" {
  let value = @json.json_parse("[1,true,null]").unwrap()
  let items = @json.json_as_array(value).unwrap()
  assert_eq(items.length(), 3)
}

///|
test "parse_negative_decimal_exp" {
  let value = @json.json_parse("-1.5e2").unwrap()
  assert_eq(@json.json_as_double(value).unwrap(), -150.0)
}

///|
test "parse_invalid_err" {
  assert_true(@json.json_parse("{") is Err(_))
}

///|
test "decode_missing_field_err" {
  let fields : Array[@json.JsonField] = []
  assert_true(@json.json_lookup(fields, "missing") is Err(_))
}

///|
test "decode_wrong_type_err" {
  assert_true(@json.json_as_string(@json.json_int(1)) is Err(_))
}
