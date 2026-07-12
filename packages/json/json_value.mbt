// Basic JSON AST and small construction helpers.

///|
pub(all) enum JsonValue {
  JNull
  JBool(Bool)
  JNumber(Double)
  JString(String)
  JArray(Array[JsonValue])
  JObject(Array[JsonField])
}

///|
pub(all) struct JsonField {
  key : String
  value : JsonValue
}

///|
pub(all) enum JsonError {
  ParseError(String)
  DecodeError(String)
}

///|
pub fn JsonError::to_string(self : JsonError) -> String {
  match self {
    ParseError(msg) => "JSON parse error: \{msg}"
    DecodeError(msg) => "JSON decode error: \{msg}"
  }
}

///|
pub fn json_null() -> JsonValue {
  JNull
}

///|
pub fn json_bool(value : Bool) -> JsonValue {
  JBool(value)
}

///|
pub fn json_number(value : Double) -> JsonValue {
  JNumber(value)
}

///|
pub fn json_int(value : Int) -> JsonValue {
  JNumber(value.to_double())
}

///|
pub fn json_string(value : String) -> JsonValue {
  JString(value)
}

///|
pub fn json_array(items : Array[JsonValue]) -> JsonValue {
  JArray(items)
}

///|
pub fn json_object(fields : Array[JsonField]) -> JsonValue {
  JObject(fields)
}

///|
pub fn json_field(key : String, value : JsonValue) -> JsonField {
  { key, value }
}
