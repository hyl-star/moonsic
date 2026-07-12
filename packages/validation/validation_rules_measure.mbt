// ============================================================
// Measure 校验
// ============================================================

///|
fn measure_events_beats(events : Array[@score.ScoreEvent]) -> Double {
  let mut total = 0.0
  for e in events {
    match e {
      @score.Note(n) =>
        total = total +
          @time.rational_to_double(
            @time.rhythm_duration_to_fraction(n.duration),
          )
      @score.Rest(r) =>
        total = total +
          @time.rational_to_double(
            @time.rhythm_duration_to_fraction(r.duration),
          )
      @score.Chord(c) =>
        total = total +
          @time.rational_to_double(
            @time.rhythm_duration_to_fraction(c.duration),
          )
      @score.Spacer(s) =>
        total = total +
          @time.rational_to_double(
            @time.rhythm_duration_to_fraction(s.duration),
          )
      _ => ()
    }
  }
  total
}

///|
pub fn validate_measure(
  m : @score.Measure,
  default_sig : @time.TimeSignature,
  options : ValidationOptions,
) -> ValidationReport {
  let mut report = empty_validation_report()
  if m.index.value < 0 {
    report = report_add_issue(
      report,
      make_issue(
        MeasureOverflow,
        "measure[\{m.index.value}]",
        "小节索引为负",
      ),
    )
    return report
  }
  let capacity = get_measure_beats(m, default_sig)
  let used = measure_events_beats(m.events)
  let path = "measure[\{m.index.value}]"

  // 检查空 chord
  for e in m.events {
    match e {
      @score.Chord(c) =>
        if c.pitches.length() == 0 {
          report = report_add_issue(
            report,
            make_issue(EmptyChordPitches, path, "空和弦"),
          )
        }
      _ => ()
    }
  }

  // 容量检查
  match m.role {
    @score.CadenzaMeasure | @score.FreeTimeMeasure => () // 不检查容量
    _ =>
      if used > capacity + 0.0001 {
        report = report_add_issue(
          report,
          make_issue(
            MeasureOverflow,
            path,
            "溢出：\{used} > \{capacity} 拍",
          ),
        )
      } else if used < capacity - 0.0001 && options.strict_measure_capacity {
        report = report_add_issue(
          report,
          make_issue(
            MeasureUnderfilled,
            path,
            "未填满：\{used} < \{capacity} 拍",
          ),
        )
      }
  }
  report
}
