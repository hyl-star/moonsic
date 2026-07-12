///|
pub fn bench_parse_to_json(iterations : Int) -> String {
  let mut total = 0
  for i = 0; i < iterations; i = i + 1 {
    total = total + parse_to_json("C4", "pitch").length()
  }
  "parse json bytes: \{total}"
}
