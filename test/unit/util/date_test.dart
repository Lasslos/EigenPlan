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
}
