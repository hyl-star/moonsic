///|
pub fn bench_generate_melody(count : Int) -> String {
  let key = @scale.key(@pitch.c(4), @scale.Major)
  let rhythm = @rhythm.rhythm_template(@rhythm.FourQuarters)
  let config = default_generation_config()
  let mut events = 0
  for i = 0; i < count; i = i + 1 {
    match generate_melody_checked(key, rhythm, config) {
      Ok(track) => events = events + track.events.length()
      Err(_) => ()
    }
  }
  "generate_melody count=\{count} events=\{events}"
}
