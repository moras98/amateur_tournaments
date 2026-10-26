/// Minimum age to use the app (Terms §3). Sign-up and profile edits reject
/// earlier birth dates: the app exposes phone numbers between players and
/// organizers, and Ley 18.331 art. 19 requires guardian authorization to
/// process an under-18's personal data.
const int kMinAgeYears = 18;

/// Whether [birthDate] has reached [minYears] completed years as of [now].
///
/// Days short of a birthday don't count (a 17-year-old 11 months into the
/// year is still 17), mirroring the age math humans do.
bool isAdult(DateTime birthDate, {DateTime? now, int minYears = kMinAgeYears}) {
  final today = now ?? DateTime.now();
  var years = today.year - birthDate.year;
  final hadBirthdayThisYear =
      today.month > birthDate.month ||
      (today.month == birthDate.month && today.day >= birthDate.day);
  if (!hadBirthdayThisYear) years--;
  return years >= minYears;
}
