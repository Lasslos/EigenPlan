import 'package:flutter_test/flutter_test.dart';
import 'package:your_schedule/util/date.dart';

void main() {
  test('equality and comparison are by calendar day, not by time-of-day', () {
    final a = Date(DateTime(2026, 3, 5, 8));
    final b = Date(DateTime(2026, 3, 5, 23));

    expect(a, equals(b));
    expect(a.compareTo(b), 0);
  });

  test('addDays/subtractDays roll over month and year boundaries', () {
    final date = Date.raw(2026, 12, 31);

    expect(date.addDays(1), equals(Date.raw(2027, 1, 1)));
    expect(Date.raw(2026, 1, 1).subtractDays(1), equals(Date.raw(2025, 12, 31)));
  });

  test('startOfWeek/endOfWeek anchor the week on Saturday', () {
    // 2026-03-05 is a Thursday.
    final thursday = Date.raw(2026, 3, 5);

    expect(thursday.startOfWeek(), equals(Date.raw(2026, 2, 28)));
    expect(thursday.endOfWeek(), equals(Date.raw(2026, 3, 6)));
  });

  test('differenceInDays is symmetric around zero', () {
    final start = Date.raw(2026, 3, 1);
    final end = Date.raw(2026, 3, 10);

    expect(end.differenceInDays(start), 9);
    expect(start.differenceInDays(end), -9);
  });

  group('relativeDayLabel', () {
    final date = DateTime(2026, 1, 12);

    test('today, tomorrow and yesterday get dedicated words', () {
      expect(relativeDayLabel(0, date), 'Heute');
      expect(relativeDayLabel(1, date), 'Morgen');
      expect(relativeDayLabel(-1, date), 'Gestern');
    });

    test('within a week, further future/past days count in Tagen', () {
      expect(relativeDayLabel(2, date), 'In 2 Tagen');
      expect(relativeDayLabel(7, date), 'In 7 Tagen');
      expect(relativeDayLabel(-2, date), 'Vor 2 Tagen');
      expect(relativeDayLabel(-7, date), 'Vor 7 Tagen');
    });

    test('beyond a week either way, falls back to the absolute date', () {
      expect(relativeDayLabel(8, date), '12.01.2026');
      expect(relativeDayLabel(42, date), '12.01.2026');
      expect(relativeDayLabel(-8, date), '12.01.2026');
      expect(relativeDayLabel(-42, date), '12.01.2026');
    });
  });

  group('formatMessageTimestamp', () {
    final today = Date.raw(2026, 3, 5);

    test('shows the time of day for a message sent today', () {
      expect(formatMessageTimestamp(DateTime(2026, 3, 5, 9, 7), today), '09:07');
      expect(formatMessageTimestamp(DateTime(2026, 3, 5, 23, 59), today), '23:59');
    });

    test('shows day and month within the current year', () {
      expect(formatMessageTimestamp(DateTime(2026, 3, 4, 22), today), '4.03.');
      expect(formatMessageTimestamp(DateTime(2026, 12, 31), today), '31.12.');
    });

    test('shows the full date for an earlier year', () {
      expect(formatMessageTimestamp(DateTime(2025, 12, 31, 22), today), '31.12.2025');
    });

    test('a message sent yesterday late is dated, not timed', () {
      // Regression: the old helper compared against DateTime.now() read at build time, so
      // after midnight yesterday's messages kept rendering as a time of day.
      expect(formatMessageTimestamp(DateTime(2026, 3, 4, 23, 55), today), '4.03.');
    });
  });
}
