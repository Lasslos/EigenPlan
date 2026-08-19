import 'package:flutter/material.dart' show TimeOfDay;
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/date.dart';
import 'package:your_schedule/util/date_utils.dart';

/// Whether [now] falls between the first and last [TimeGridEntry] of the school day —
/// i.e. whether classes could currently be in session. Mirrors the boundary check
/// `TimeIndicator` draws on the timetable grid.
///
/// Deliberately a plain function rather than a `@riverpod` provider: a provider that
/// read `DateTime.now()` internally would only recompute when a *watched* dependency
/// changes, never on its own — wall-clock time isn't one, so it would compute once and
/// freeze. Callers re-invoke this every tick via `TimedRefresh` instead.
bool isWithinSchoolHours(List<TimeGridEntry> timeGrid, DateTime now) {
  if (timeGrid.isEmpty) {
    return false;
  }
  final time = TimeOfDay.fromDateTime(now);
  return time.difference(timeGrid.first.startTime) >= Duration.zero &&
      time.difference(timeGrid.last.endTime) <= Duration.zero;
}

/// Whether [entry] should be shown at all, per the Filter screen's per-course
/// visibility map — same `overrides[courseKey] ?? true` rule `week_view.dart`/
/// `day_view.dart` use. Entries with no `courseKey` (e.g. standalone events) are
/// always visible.
bool _isVisible(GridEntry entry, Map<String, bool> overrides) {
  final key = entry.courseKey;
  return key == null || (overrides[key] ?? true);
}

/// The lesson currently in progress on [today], or — during a gap/break — the next one
/// to start. `null` if there's nothing left today. Cancelled lessons never count as
/// "current" or "next": there's nothing to arrive at. Hidden courses (per [overrides],
/// the Filter screen's per-course visibility map) are skipped too — a filtered-out
/// class shouldn't surface here even though it's still filtered from the timetable
/// grid.
({GridEntry entry, bool isCurrent})? currentOrNextLesson(
  TimetableDay? today,
  DateTime now,
  Map<String, bool> overrides,
) {
  if (today == null) {
    return null;
  }
  final candidates = today.gridEntries.where((e) => !e.isCancelled && _isVisible(e, overrides)).toList()
    ..sort((a, b) => a.duration.start.compareTo(b.duration.start));

  for (final entry in candidates) {
    if (!entry.duration.start.isAfter(now) && entry.duration.end.isAfter(now)) {
      return (entry: entry, isCurrent: true);
    }
  }
  for (final entry in candidates) {
    if (entry.duration.start.isAfter(now)) {
      return (entry: entry, isCurrent: false);
    }
  }
  return null;
}

enum IrregularityKind { cancelled, changed, event }

class Irregularity {
  const Irregularity(this.kind, this.entry);

  final IrregularityKind kind;
  final GridEntry entry;
}

/// Cancelled lessons, changed/substituted lessons, and standalone events on [today],
/// filtered through [overrides] (the Filter screen's per-course visibility map — same
/// `overrides[courseKey] ?? true` rule `week_view.dart`/`day_view.dart` use), sorted by
/// start time.
List<Irregularity> todaysIrregularities(
  TimetableDay? today,
  Map<String, bool> overrides,
) {
  if (today == null) {
    return [];
  }
  final visible = today.gridEntries.where((e) => _isVisible(e, overrides));

  final irregularities = <Irregularity>[
    for (final entry in visible)
      if (entry.isCancelled)
        Irregularity(IrregularityKind.cancelled, entry)
      else if (entry.isChanged || entry.hasSubstitution)
        Irregularity(IrregularityKind.changed, entry)
      else if (entry.type == 'EVENT')
        Irregularity(IrregularityKind.event, entry),
  ]..sort((a, b) => a.entry.duration.start.compareTo(b.entry.duration.start));
  return irregularities;
}

/// The next actual school day after [from] — skipping weekends and any day covered by
/// [holidays]. `null` if none is found within [maxLookahead] days (e.g. deep into
/// summer break).
Date? nextSchoolDay(
  Date from,
  Iterable<Holiday> holidays, {
  int maxLookahead = 21,
}) {
  var day = from.addDays(1);
  for (var i = 0; i < maxLookahead; i++, day = day.addDays(1)) {
    if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
      continue;
    }
    final inHoliday = holidays.any((h) {
      final start = h.startDate.normalized();
      final end = h.endDate.normalized();
      return !day.isBefore(start) && !end.isBefore(day);
    });
    if (inHoliday) {
      continue;
    }
    return day;
  }
  return null;
}

/// Looks [day] up in whichever of [week1]/[week2] contains it — "the next school day"
/// can land in either depending how close today is to a week boundary (weeks here
/// start Saturday), and a dashboard showing "today" can equally need either.
TimetableDay? lookupDay(Date day, TimeTableWeek week1, TimeTableWeek week2) => week1[day] ?? week2[day];

/// When [day]'s school day actually starts/ends once cancellations and hidden courses
/// (per [overrides], the Filter screen's per-course visibility map) are taken into
/// account — the earliest start and latest end among its non-cancelled, visible
/// entries. `null` if [day] is unknown or has no such entries at all (e.g. everything
/// on it is cancelled/hidden, or it's genuinely empty).
({DateTime start, DateTime end})? schoolDayBounds(TimetableDay? day, Map<String, bool> overrides) {
  if (day == null) {
    return null;
  }
  final active = day.gridEntries.where((e) => !e.isCancelled && _isVisible(e, overrides));
  if (active.isEmpty) {
    return null;
  }
  var start = active.first.duration.start;
  var end = active.first.duration.end;
  for (final entry in active) {
    if (entry.duration.start.isBefore(start)) {
      start = entry.duration.start;
    }
    if (entry.duration.end.isAfter(end)) {
      end = entry.duration.end;
    }
  }
  return (start: start, end: end);
}

/// Every lesson on [day] — cancelled ones included, so this reads as a real summary of
/// the day rather than just "what to pack" — filtered through [overrides] (the Filter
/// screen's per-course visibility map) and sorted by start time. `null`/non-`REGULAR`
/// days (outside the school year, or genuinely no data) yield an empty list.
List<GridEntry> visibleLessonsFor(TimetableDay? day, Map<String, bool> overrides) {
  if (day == null || day.status != 'REGULAR') {
    return [];
  }
  final visible = day.gridEntries.where((e) => _isVisible(e, overrides)).toList()
    ..sort((a, b) => a.duration.start.compareTo(b.duration.start));
  return visible;
}
