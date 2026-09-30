/// Helpers for fields that are calendar dates (a due day, a fuel-up day),
/// not moments in time.
///
/// Wire format: UTC midnight of that day (`2026-12-09T00:00:00.000Z`), so the
/// day survives any server or device time zone.

/// Parses an API date into a local, midnight-based calendar date.
///
/// Rows saved before the UTC-midnight format hold the picked day's *local*
/// midnight as an instant (e.g. 23:00Z the day before in Poland); those are
/// converted through the device zone so they still show the intended day.
DateTime parseCalendarDate(String iso) {
  final parsed = DateTime.parse(iso);
  if (!parsed.isUtc) {
    return DateTime(parsed.year, parsed.month, parsed.day);
  }
  final isUtcMidnight = parsed.hour == 0 &&
      parsed.minute == 0 &&
      parsed.second == 0 &&
      parsed.millisecond == 0;
  final day = isUtcMidnight ? parsed : parsed.toLocal();
  return DateTime(day.year, day.month, day.day);
}

/// Serializes the calendar day of [date] (its local Y/M/D) as UTC midnight.
String formatCalendarDate(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day).toIso8601String();
