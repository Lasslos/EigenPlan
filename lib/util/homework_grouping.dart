import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/date.dart';

/// Splits [items] into "upcoming" (due [today] or later) and "older" (already past
/// due) — the same `Date(item.endDate).differenceInDays(today) < 0` cutoff used
/// elsewhere for "Überfällig" styling. `upcoming` is sorted ascending by due date
/// (soonest first); `older` is sorted descending (most recently due first), so the
/// item closest to today sits nearest the boundary between the two groups.
/// Completion status has no effect on the split — it's purely date-based.
({List<HomeworkItem> upcoming, List<HomeworkItem> older}) splitHomeworkByDueDate(
  List<HomeworkItem> items, {
  Date? today,
}) {
  final cutoff = today ?? Date.now();
  final upcoming = <HomeworkItem>[];
  final older = <HomeworkItem>[];
  for (final item in items) {
    if (Date(item.endDate).differenceInDays(cutoff) < 0) {
      older.add(item);
    } else {
      upcoming.add(item);
    }
  }
  upcoming.sort((a, b) => a.endDate.compareTo(b.endDate));
  older.sort((a, b) => b.endDate.compareTo(a.endDate));
  return (upcoming: upcoming, older: older);
}
