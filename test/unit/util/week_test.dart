import 'package:flutter_test/flutter_test.dart';
import 'package:your_schedule/util/date.dart';
import 'package:your_schedule/util/week.dart';

void main() {
  test('fromDate spans Saturday through the following Friday', () {
    // 2026-03-05 is a Thursday.
    final week = Week.fromDate(Date.raw(2026, 3, 5));

    expect(week.startDate, equals(Date.raw(2026, 2, 28)));
    expect(week.endDate, equals(Date.raw(2026, 3, 6)));
    expect(week.daysInWeek, hasLength(7));
    expect(week.daysInWeek.first, equals(week.startDate));
    expect(week.daysInWeek.last, equals(week.endDate));
  });

  test('relative(0) matches now(), relative(1) is exactly one week later', () {
    final thisWeek = Week.now();
    final nextWeek = Week.relative(1);

    expect(nextWeek.startDate, equals(thisWeek.startDate.addWeeks(1)));
    expect(nextWeek.endDate, equals(thisWeek.endDate.addWeeks(1)));
  });

  test('equality is by start/end date, not identity', () {
    final a = Week.fromDate(Date.raw(2026, 3, 5));
    final b = Week.fromDate(Date.raw(2026, 3, 3));

    expect(a, equals(b));
  });
}
