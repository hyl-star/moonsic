///|
fn write_wav_header_arr(
  buf : Array[Byte],
  num_samples : Int,
  sample_rate : Int,
) -> Unit {
  let byte_rate = sample_rate * 2
  let data_size = num_samples * 2
  let file_size = 36 + data_size
  buf[0] = b'R'
  buf[1] = b'I'
  buf[2] = b'F'
  buf[3] = b'F'
  write_u32le(buf, 4, file_size)
  buf[8] = b'W'
  buf[9] = b'A'
  buf[10] = b'V'
  buf[11] = b'E'
  buf[12] = b'f'
  buf[13] = b'm'
  buf[14] = b't'
  buf[15] = b' '
  write_u32le(buf, 16, 16)
  write_u16le(buf, 20, 1)
  write_u16le(buf, 22, 1)
  write_u32le(buf, 24, sample_rate)
  write_u32le(buf, 28, byte_rate)
  write_u16le(buf, 32, 2)
  write_u16le(buf, 34, 16)
  buf[36] = b'd'
  buf[37] = b'a'
  buf[38] = b't'
  buf[39] = b'a'
  write_u32le(buf, 40, data_size)
}

///|
fn write_u32le(buf : Array[Byte], offset : Int, value : Int) -> Unit {
  buf[offset] = (value & 0xFF).to_byte()
  buf[offset + 1] = ((value >> 8) & 0xFF).to_byte()
  buf[offset + 2] = ((value >> 16) & 0xFF).to_byte()
  buf[offset + 3] = ((value >> 24) & 0xFF).to_byte()
}

///|
fn write_u16le(buf : Array[Byte], offset : Int, value : Int) -> Unit {
  buf[offset] = (value & 0xFF).to_byte()
  buf[offset + 1] = ((value >> 8) & 0xFF).to_byte()
}
