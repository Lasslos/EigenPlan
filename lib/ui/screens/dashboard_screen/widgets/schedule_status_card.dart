import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:your_schedule/core/provider/clock_provider.dart';
import 'package:your_schedule/core/provider/filters.dart';
import 'package:your_schedule/core/provider/selected_timetable_resource_provider.dart';
import 'package:your_schedule/core/provider/timetable_provider.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/ui/screens/dashboard_screen/widgets/dashboard_summary_card.dart';
import 'package:your_schedule/ui/shared/course_chip.dart';
import 'package:your_schedule/util/schedule_status.dart';
import 'package:your_schedule/utils.dart';

/// "Where do I have to be" from [scheduleLeadIn] before the first lesson until the last
/// one ends (current/next lesson with room and countdown, plus today's
/// cancellations/substitutions/events), and "what's on that day" outside that window:
/// today while its first lesson is still further off, the next school day once today is
/// over.
class ScheduleStatusCard extends ConsumerWidget {
  const ScheduleStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(selectedUntisSessionProvider) as ActiveUntisSession;
    final resource = ref.watch(effectiveTimetableResourceProvider(session));

    if (resource == null) {
      return const SizedBox.shrink();
    }

    final holidays = session.userData.holidays.values;
    final overrides = ref.watch(courseOverridesForResourceProvider(resource));
    // Both the countdown and the current-vs-next-lesson decision are pure functions of the
    // clock, so they have to be driven by it — see [currentMinuteProvider].
    final now = ref.watch(currentMinuteProvider);
    final date = ref.watch(todayProvider);
    final thisWeek = ref.watch(timeTableProvider(session, Week.fromDate(date), resource));
    final nextWeek = ref.watch(timeTableProvider(session, Week.relativeTo(date, 1), resource));

    final today = lookupDay(date, thisWeek, nextWeek);
    final phase = schoolDayPhase(schoolDayBounds(today, overrides), now);
    // The lead-in counts as "in school": within [scheduleLeadIn] of the first lesson the
    // useful thing is the room to walk to, not a summary of the day.
    final status =
        phase == null || phase == ScheduleDayPhase.beforeStart ? null : currentOrNextLesson(today, now, overrides);

    if (status != null) {
      return DashboardSummaryCard(
        title: 'Heute',
        child: _InSchoolContent(
          today: today,
          status: status,
          overrides: overrides,
          now: now,
        ),
      );
    }
    // Today keeps the card for as long as it still has school ahead of it — a morning
    // before the first lesson is "Heute", not "Morgen". Only a finished day (or one
    // without any lessons at all) hands over to the next one.
    final day = phase == null ? nextSchoolDay(date, holidays) : date;
    final dayData = day == null ? null : lookupDay(day, thisWeek, nextWeek);
    return DashboardSummaryCard(
      title: day == null ? 'Nächster Schultag' : _dayLabel(day, date),
      child: _DayOverviewContent(
        hasDay: day != null,
        dayData: dayData,
        overrides: overrides,
        lessons: visibleLessonsFor(dayData, overrides),
      ),
    );
  }
}

String _subjectName(GridEntry entry) {
  final slot = entry.positionOfType('SUBJECT') ?? entry.positionOfType('INFO');
  return slot?.current?.longName ??
      slot?.current?.displayName ??
      slot?.current?.shortName ??
      entry.lessonText ??
      'Unbekanntes Fach';
}

String? _roomName(GridEntry entry) {
  final element = entry.positionOfType('ROOM')?.current;
  final name = element?.shortName ?? element?.displayName ?? element?.longName;
  return (name == null || name.isEmpty) ? null : name;
}

class _InSchoolContent extends StatelessWidget {
  const _InSchoolContent({
    required this.today,
    required this.status,
    required this.overrides,
    required this.now,
  });

  final TimetableDay? today;
  final ({GridEntry entry, bool isCurrent}) status;
  final Map<String, bool> overrides;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final irregularities = irregularitiesFor(today, overrides);
    final bounds = schoolDayBounds(today, overrides);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LessonStatusTile(
          entry: status.entry,
          isCurrent: status.isCurrent,
          isLastPeriod: bounds != null && status.entry.duration.end.isAtSameMomentAs(bounds.end),
          now: now,
        ),
        if (bounds != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Text(
              'Schulende: ${intl.DateFormat('HH:mm').format(bounds.end)} Uhr',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        for (final irregularity in irregularities) _IrregularityTile(irregularity),
      ],
    );
  }
}

class _LessonStatusTile extends StatelessWidget {
  const _LessonStatusTile({
    required this.entry,
    required this.isCurrent,
    required this.isLastPeriod,
    required this.now,
  });

  final GridEntry entry;
  final bool isCurrent;
  final bool isLastPeriod;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final target = isCurrent ? entry.duration.end : entry.duration.start;
    final minutes = durationLabel(minutesUntil(target, now));
    final countdown = !isCurrent
        ? 'Beginnt in $minutes'
        : isLastPeriod
            ? '$minutes bis Schulende'
            : '$minutes bis zur Pause';
    final room = _roomName(entry);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(isCurrent ? Icons.play_circle_outline : Icons.upcoming_outlined),
      title: CourseChip(label: _subjectName(entry), courseKey: entry.courseKey),
      subtitle: Text(room == null ? countdown : '$countdown · Raum $room'),
    );
  }
}

class _IrregularityTile extends StatelessWidget {
  const _IrregularityTile(this.irregularity);

  final Irregularity irregularity;

  @override
  Widget build(BuildContext context) {
    final entry = irregularity.entry;
    final subject = _subjectName(entry);
    final time =
        '${intl.DateFormat('HH:mm').format(entry.duration.start)}–${intl.DateFormat('HH:mm').format(entry.duration.end)}';
    final (icon, text) = switch (irregularity.kind) {
      IrregularityKind.cancelled => (Icons.event_busy, '$subject fällt aus'),
      IrregularityKind.changed => (Icons.swap_horiz, 'Vertretung: $subject'),
      IrregularityKind.event => (Icons.event, '$subject, $time Uhr'),
    };
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20),
      title: Text(text),
    );
  }
}

/// A school day that's still at arm's length — today before the [scheduleLeadIn] window
/// opens, or the next school day once today is over — condensed. Not a second timetable: just "when" (the
/// day itself is the card's title, e.g. "Morgen"), "which subjects" as a row of
/// course-colored chips (see [CourseChip]) rather than a plain text list, and whatever
/// is irregular about it, the same tiles the in-school view shows.
class _DayOverviewContent extends StatelessWidget {
  const _DayOverviewContent({
    required this.hasDay,
    required this.dayData,
    required this.overrides,
    required this.lessons,
  });

  final bool hasDay;
  final TimetableDay? dayData;
  final Map<String, bool> overrides;
  final List<GridEntry> lessons;

  @override
  Widget build(BuildContext context) {
    if (!hasDay) {
      return const Text('Kein weiterer Schultag in Sicht.');
    }
    if (lessons.isEmpty) {
      return const Text('Keine Stundenplandaten verfügbar.');
    }
    final bounds = schoolDayBounds(dayData, overrides);
    final courses = _distinctCourses(lessons);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (bounds != null)
          Text(
            'Unterricht von ${_time(bounds.start)}–${_time(bounds.end)} Uhr',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        if (courses.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final course in courses) CourseChip(label: course.name, courseKey: course.courseKey),
              ],
            ),
          ),
        for (final irregularity in irregularitiesFor(dayData, overrides)) _IrregularityTile(irregularity),
      ],
    );
  }
}

/// "Heute" when [day] is [today] (school hasn't started yet), "Morgen" when it really is
/// the calendar day after, else its weekday name (e.g. "Montag" when the next school day
/// is further out, over a weekend/holiday).
String _dayLabel(Date day, Date today) {
  return switch (day.differenceInDays(today)) {
    0 => 'Heute',
    1 => 'Morgen',
    _ => day.format(intl.DateFormat('EEEE', 'de')),
  };
}

String _time(DateTime time) => intl.DateFormat('H:mm', 'de').format(time);

/// Courses on [lessons] in first-occurrence (i.e. chronological) order, deduplicated
/// by `courseKey` (falling back to name when an entry has no `courseKey`) and
/// excluding cancelled entries — a subject that only occurs cancelled that day isn't
/// happening, so it's left out.
List<({String? courseKey, String name})> _distinctCourses(List<GridEntry> lessons) {
  final seen = <String>{};
  final courses = <({String? courseKey, String name})>[];
  for (final entry in lessons) {
    if (entry.isCancelled) {
      continue;
    }
    final courseKey = entry.courseKey;
    final name = _subjectName(entry);
    if (seen.add(courseKey ?? name)) {
      courses.add((courseKey: courseKey, name: name));
    }
  }
  return courses;
}
