// Small typed accessors for JsonValue.

///|
pub fn json_as_object(value : JsonValue) -> Result[Array[JsonField], JsonError] {
  match value {
    JObject(fields) => Ok(fields)
    _ => Err(DecodeError("expected object"))
  }
}

///|
pub fn json_lookup(
  fields : Array[JsonField],
  key : String,
) -> Result[JsonValue, JsonError] {
  for field in fields {
    if field.key == key {
      return Ok(field.value)
    }
  }
  Err(DecodeError("missing field: \{key}"))
}

///|
pub fn json_as_string(value : JsonValue) -> Result[String, JsonError] {
  match value {
    JString(s) => Ok(s)
    _ => Err(DecodeError("expected string"))
  }
}

///|
pub fn json_as_int(value : JsonValue) -> Result[Int, JsonError] {
  match value {
    JNumber(n) => Ok(n.to_int())
    _ => Err(DecodeError("expected number"))
  }
}

///|
pub fn json_as_double(value : JsonValue) -> Result[Double, JsonError] {
  match value {
    JNumber(n) => Ok(n)
    _ => Err(DecodeError("expected number"))
  }
}

///|
pub fn json_as_bool(value : JsonValue) -> Result[Bool, JsonError] {
  match value {
    JBool(b) => Ok(b)
    _ => Err(DecodeError("expected bool"))
  }
}

///|
pub fn json_as_array(value : JsonValue) -> Result[Array[JsonValue], JsonError] {
  match value {
    JArray(items) => Ok(items)
    _ => Err(DecodeError("expected array"))
  }
}
