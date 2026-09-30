import 'package:flutter_test/flutter_test.dart';
import 'package:moto_service_card/core/utils/calendar_date.dart';

void main() {
  final picked = DateTime(2026, 12, 9);

  test('new format (UTC midnight) parses to the same calendar day', () {
    expect(parseCalendarDate('2026-12-09T00:00:00.000Z'), picked);
  });

  test('legacy row (local midnight stored as an instant) shows the picked day',
      () {
    final legacy = picked.toUtc().toIso8601String();
    expect(parseCalendarDate(legacy), picked);
  });

  test('legacy row with a time of day keeps its local day', () {
    final legacy = DateTime(2026, 9, 30, 11, 30).toUtc().toIso8601String();
    expect(parseCalendarDate(legacy), DateTime(2026, 9, 30));
  });

  test('formatCalendarDate sends UTC midnight of the local day', () {
    expect(formatCalendarDate(picked), '2026-12-09T00:00:00.000Z');
    expect(formatCalendarDate(DateTime(2026, 12, 9, 23, 59)),
        '2026-12-09T00:00:00.000Z');
  });

  test('round trip keeps the day', () {
    expect(parseCalendarDate(formatCalendarDate(picked)), picked);
  });
}
