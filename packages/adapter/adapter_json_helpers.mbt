///|
fn json_type_error(error : @json.JsonError) -> AdapterError {
  AdapterJsonError(error.to_string())
}

///|
fn json_object_fields(
  value : @json.JsonValue,
) -> Result[Array[@json.JsonField], AdapterError] {
  match @json.json_as_object(value) {
    Ok(fields) => Ok(fields)
    Err(e) => Err(json_type_error(e))
  }
}

///|
fn json_lookup_required(
  fields : Array[@json.JsonField],
  key : String,
) -> Result[@json.JsonValue, AdapterError] {
  match @json.json_lookup(fields, key) {
    Ok(value) => Ok(value)
    Err(e) => Err(json_type_error(e))
  }
}

///|
fn json_lookup_optional(
  fields : Array[@json.JsonField],
  key : String,
) -> @json.JsonValue? {
  match @json.json_lookup(fields, key) {
    Ok(value) => Some(value)
    Err(_) => None
  }
}

///|
fn json_string_required(
  fields : Array[@json.JsonField],
  key : String,
) -> Result[String, AdapterError] {
  match json_lookup_required(fields, key) {
    Ok(value) =>
      match @json.json_as_string(value) {
        Ok(text) => Ok(text)
        Err(e) => Err(json_type_error(e))
      }
    Err(e) => Err(e)
  }
}

///|
fn json_int_required(
  fields : Array[@json.JsonField],
  key : String,
) -> Result[Int, AdapterError] {
  match json_lookup_required(fields, key) {
    Ok(value) =>
      match @json.json_as_int(value) {
        Ok(number) => Ok(number)
        Err(e) => Err(json_type_error(e))
      }
    Err(e) => Err(e)
  }
}

///|
fn json_double_required(
  fields : Array[@json.JsonField],
  key : String,
) -> Result[Double, AdapterError] {
  match json_lookup_required(fields, key) {
    Ok(value) =>
      match @json.json_as_double(value) {
        Ok(number) => Ok(number)
        Err(e) => Err(json_type_error(e))
      }
    Err(e) => Err(e)
  }
}

///|
fn json_array_required(
  fields : Array[@json.JsonField],
  key : String,
) -> Result[Array[@json.JsonValue], AdapterError] {
  match json_lookup_required(fields, key) {
    Ok(value) =>
      match @json.json_as_array(value) {
        Ok(items) => Ok(items)
        Err(e) => Err(json_type_error(e))
      }
    Err(e) => Err(e)
  }
}
