import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/date.dart';
import 'package:your_schedule/util/date_utils.dart';

/// Whole minutes from [now] until [target], rounded **up** and clamped at 0.
///
/// Rounding up is what a countdown means colloquially: at 11:43 a lesson starting at 11:45
/// is "in 2 Minuten", even though 2 full minutes may not be left. Truncating instead (what
/// `Duration.inMinutes` does) would call that same moment "1 Minute".
///
/// Callers pass a `now` truncated to the minute (see `currentMinuteProvider`), which makes
/// the result stable for the whole minute and step down exactly on the boundary.
int minutesUntil(DateTime target, DateTime now) {
  final remaining = target.difference(now);
  if (remaining <= Duration.zero) {
    return 0;
  }
  return (remaining.inMicroseconds / Duration.microsecondsPerMinute).ceil();
}

/// [minutes] with the correctly inflected German unit — "1 Minute", "2 Minuten".
String minutesLabel(int minutes) => '$minutes ${minutes == 1 ? 'Minute' : 'Minuten'}';

/// [minutes] as a countdown label: plain minutes below an hour ("47 Minuten"), hours and
/// minutes above it ("1 Std. 47 Min."). The split matters once a countdown can span the
/// [scheduleLeadIn] before school — "119 Minuten" is a number you have to do maths on.
String durationLabel(int minutes) {
  if (minutes < 60) {
    return minutesLabel(minutes);
  }
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? '$hours Std.' : '$hours Std. $rest Min.';
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

/// Cancelled lessons, changed/substituted lessons, and standalone events on [day],
/// filtered through [overrides] (the Filter screen's per-course visibility map — same
/// `overrides[courseKey] ?? true` rule `week_view.dart`/`day_view.dart` use), sorted by
/// start time.
List<Irregularity> irregularitiesFor(
  TimetableDay? day,
  Map<String, bool> overrides,
) {
  if (day == null) {
    return [];
  }
  final visible = day.gridEntries.where((e) => _isVisible(e, overrides));

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

/// How long before the first lesson the dashboard stops describing the day as a whole and
/// starts pointing at the room to walk to — see [ScheduleDayPhase.startingSoon].
const scheduleLeadIn = Duration(hours: 2);

/// Where [now] sits relative to a school day that hasn't finished yet.
enum ScheduleDayPhase {
  /// The first lesson is further off than [scheduleLeadIn] — the early morning, say.
  beforeStart,

  /// The first lesson is within [scheduleLeadIn]: close enough that where to go matters
  /// more than an overview of the day.
  startingSoon,

  /// A lesson is running, or [now] is in a gap/break between two of them.
  inProgress,
}

/// Where [now] sits relative to [bounds] (a day's real start/end per [schoolDayBounds]),
/// counting the [leadIn] before the first lesson as part of the day.
///
/// `null` once the day is over — or when it never had any visible, non-cancelled lessons
/// to begin with — which is exactly when a caller should move on to the next school day.
/// Deriving this from [schoolDayBounds] rather than from the school's global time grid is
/// what makes it personal: a morning whose first two periods are cancelled, or whose only
/// early lesson is filtered out on the Filter screen, counts as [beforeStart] right up
/// until the lesson the user actually has to attend.
ScheduleDayPhase? schoolDayPhase(
  ({DateTime start, DateTime end})? bounds,
  DateTime now, {
  Duration leadIn = scheduleLeadIn,
}) {
  if (bounds == null) {
    return null;
  }
  if (now.isBefore(bounds.start.subtract(leadIn))) {
    return ScheduleDayPhase.beforeStart;
  }
  if (now.isBefore(bounds.start)) {
    return ScheduleDayPhase.startingSoon;
  }
  if (now.isBefore(bounds.end)) {
    return ScheduleDayPhase.inProgress;
  }
  return null;
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
