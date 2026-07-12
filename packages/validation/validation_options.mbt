// ============================================================
// Validation Profile / Options
// ============================================================

///|
pub(all) enum ValidationProfile {
  EditingProfile
  StrictProfile
  ExportReadyProfile
  GoldenTestProfile
}

///|
pub(all) struct ValidationOptions {
  strict_measure_capacity : Bool
  empty_voice_is_error : Bool
  empty_staff_is_error : Bool
  empty_part_is_error : Bool
  check_voice_alignment : Bool
}

///|
pub fn editing_validation_options() -> ValidationOptions {
  {
    strict_measure_capacity: false,
    empty_voice_is_error: false,
    empty_staff_is_error: false,
    empty_part_is_error: false,
    check_voice_alignment: false,
  }
}

///|
pub fn strict_validation_options() -> ValidationOptions {
  {
    strict_measure_capacity: true,
    empty_voice_is_error: true,
    empty_staff_is_error: true,
    empty_part_is_error: true,
    check_voice_alignment: true,
  }
}

///|
pub fn export_ready_validation_options() -> ValidationOptions {
  {
    strict_measure_capacity: true,
    empty_voice_is_error: true,
    empty_staff_is_error: true,
    empty_part_is_error: true,
    check_voice_alignment: true,
  }
}

///|
pub fn options_for_profile(profile : ValidationProfile) -> ValidationOptions {
  match profile {
    EditingProfile => editing_validation_options()
    StrictProfile => strict_validation_options()
    ExportReadyProfile => export_ready_validation_options()
    GoldenTestProfile => strict_validation_options()
  }
}
