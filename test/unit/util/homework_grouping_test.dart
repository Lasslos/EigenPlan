import 'package:flutter_test/flutter_test.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/date.dart';
import 'package:your_schedule/util/homework_grouping.dart';

HomeworkItem _item(int id, DateTime endDate, {bool completed = false}) => HomeworkItem(
  id: id,
  lessonId: 1,
  startDate: endDate,
  endDate: endDate,
  text: 'Aufgabe $id',
  completed: completed,
);

void main() {
  group('splitHomeworkByDueDate', () {
    final today = Date.raw(2026, 1, 10);

    test('empty input → both groups empty', () {
      final split = splitHomeworkByDueDate(const [], today: today);

      expect(split.upcoming, isEmpty);
      expect(split.older, isEmpty);
    });

    test('due today counts as upcoming, due yesterday counts as older', () {
      final dueToday = _item(1, DateTime(2026, 1, 10));
      final dueYesterday = _item(2, DateTime(2026, 1, 9));

      final split = splitHomeworkByDueDate([dueToday, dueYesterday], today: today);

      expect(split.upcoming, [dueToday]);
      expect(split.older, [dueYesterday]);
    });

    test('upcoming is sorted ascending (soonest first)', () {
      final later = _item(1, DateTime(2026, 1, 20));
      final sooner = _item(2, DateTime(2026, 1, 12));

      final split = splitHomeworkByDueDate([later, sooner], today: today);

      expect(split.upcoming, [sooner, later]);
    });

    test('older is sorted descending (most recently due first)', () {
      final longAgo = _item(1, DateTime(2026, 1, 1));
      final recently = _item(2, DateTime(2026, 1, 8));

      final split = splitHomeworkByDueDate([longAgo, recently], today: today);

      expect(split.older, [recently, longAgo]);
    });

    test('completion status has no effect on the split', () {
      final completedPast = _item(1, DateTime(2026, 1, 5), completed: true);
      final incompletePast = _item(2, DateTime(2026, 1, 6));

      final split = splitHomeworkByDueDate([completedPast, incompletePast], today: today);

      expect(split.older, hasLength(2));
    });
  });
}
