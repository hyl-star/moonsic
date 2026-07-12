///|
fn ffi_ok(data_json : String) -> String {
  "{\"ok\":true,\"data\":" + data_json + "}"
}

///|
fn ffi_error(error : FfiError) -> String {
  "{\"ok\":false,\"error\":\"FfiError\",\"message\":\"" +
  @json.json_escape(error.to_string()) +
  "\"}"
}

///|
fn input_fields(input : String) -> Result[Array[@json.JsonField], FfiError] {
  let value = match @json.json_parse(input) {
    Ok(result) => result
    Err(e) => return Err(InvalidFfiJson(e.to_string()))
  }
  match @json.json_as_object(value) {
    Ok(result) => Ok(result)
    Err(e) => Err(InvalidFfiJson(e.to_string()))
  }
}

///|
fn field_string(
  fields : Array[@json.JsonField],
  name : String,
) -> Result[String, FfiError] {
  let value = match @json.json_lookup(fields, name) {
    Ok(result) => result
    Err(_) => return Err(MissingFfiField(name))
  }
  match @json.json_as_string(value) {
    Ok(result) => Ok(result)
    Err(e) => Err(InvalidFfiField(e.to_string()))
  }
}

///|
fn field_string_or(
  fields : Array[@json.JsonField],
  name : String,
  fallback : String,
) -> Result[String, FfiError] {
  match @json.json_lookup(fields, name) {
    Ok(value) =>
      match @json.json_as_string(value) {
        Ok(result) => Ok(result)
        Err(e) => Err(InvalidFfiField(e.to_string()))
      }
    Err(_) => Ok(fallback)
  }
}

///|
fn field_int_or(
  fields : Array[@json.JsonField],
  name : String,
  fallback : Int,
) -> Result[Int, FfiError] {
  match @json.json_lookup(fields, name) {
    Ok(value) =>
      match @json.json_as_int(value) {
        Ok(result) => Ok(result)
        Err(e) => Err(InvalidFfiField(e.to_string()))
      }
    Err(_) => Ok(fallback)
  }
}

///|
fn field_int_array_or(
  fields : Array[@json.JsonField],
  name : String,
  fallback : Array[Int],
) -> Result[Array[Int], FfiError] {
  match @json.json_lookup(fields, name) {
    Ok(value) => {
      let items = match @json.json_as_array(value) {
        Ok(result) => result
        Err(e) => return Err(InvalidFfiField(e.to_string()))
      }
      let result : Array[Int] = []
      for item in items {
        match @json.json_as_int(item) {
          Ok(number) => result.push(number)
          Err(e) => return Err(InvalidFfiField(e.to_string()))
        }
      }
      Ok(result)
    }
    Err(_) => Ok(fallback)
  }
}

///|
fn xml_payload(xml : String) -> String {
  "{\"xml\":\"" + @json.json_escape(xml) + "\"}"
}

///|
fn bytes_payload(bytes : Bytes) -> String {
  "{\"byte_length\":" + bytes.length().to_string() + "}"
}
