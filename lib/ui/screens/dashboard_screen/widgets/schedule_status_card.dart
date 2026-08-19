import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:your_schedule/core/provider/filters.dart';
import 'package:your_schedule/core/provider/selected_timetable_resource_provider.dart';
import 'package:your_schedule/core/provider/timetable_provider.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/ui/screens/dashboard_screen/widgets/dashboard_summary_card.dart';
import 'package:your_schedule/ui/shared/timed_refresh.dart';
import 'package:your_schedule/util/schedule_status.dart';
import 'package:your_schedule/utils.dart';

/// How often the countdown/current-vs-next-lesson text re-derives itself from
/// `DateTime.now()`. Cheap either way (pure in-memory comparisons, no request), but 15s
/// keeps the minute-precision countdown from visibly lagging behind a real minute
/// boundary without recomputing on every frame.
const _refreshInterval = Duration(seconds: 15);

/// "What's happening right now" during school hours (current/next lesson with a
/// countdown, plus today's cancellations/substitutions/events), or — outside school
/// hours — what to bring for the next school day.
class ScheduleStatusCard extends ConsumerWidget {
  const ScheduleStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(selectedUntisSessionProvider) as ActiveUntisSession;
    final resource = ref.watch(effectiveTimetableResourceProvider(session));

    if (resource == null) {
      return const SizedBox.shrink();
    }

    final timeGrid = session.userData.timeGrid;
    final holidays = session.userData.holidays.values;
    final overrides = ref.watch(courseOverridesForResourceProvider(resource));
    final thisWeek = ref.watch(timeTableProvider(session, Week.now(), resource));
    final nextWeek = ref.watch(timeTableProvider(session, Week.relative(1), resource));

    return TimedRefresh(
      interval: _refreshInterval,
      builder: (now, context) {
        final today = lookupDay(Date.now(), thisWeek, nextWeek);
        final status = isWithinSchoolHours(timeGrid, now) ? currentOrNextLesson(today, now, overrides) : null;

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
        final nextDay = nextSchoolDay(Date.now(), holidays);
        final nextDayData = nextDay == null ? null : lookupDay(nextDay, thisWeek, nextWeek);
        return DashboardSummaryCard(
          title: nextDay == null ? 'Nächster Schultag' : _dayLabel(nextDay),
          child: _NextDayOverviewContent(
            hasDay: nextDay != null,
            dayData: nextDayData,
            overrides: overrides,
            lessons: visibleLessonsFor(nextDayData, overrides),
          ),
        );
      },
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
    final irregularities = todaysIrregularities(today, overrides);
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
    final remaining = isCurrent ? entry.duration.end.difference(now) : entry.duration.start.difference(now);
    final minutes = remaining.inMinutes.clamp(0, 999);
    final countdown = !isCurrent
        ? 'Beginnt in $minutes Minuten'
        : isLastPeriod
            ? '$minutes Minuten bis Schulende'
            : '$minutes Minuten bis zur Pause';
    final room = _roomName(entry);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(isCurrent ? Icons.play_circle_outline : Icons.upcoming_outlined),
      title: Text(_subjectName(entry)),
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

/// The next school day, condensed to two lines — not a second timetable, just "when"
/// and "which subjects" (the day itself is the card's title, e.g. "Morgen"):
/// "Unterricht von 8:00–15:45 Uhr"
/// "Fächer: Spanisch, Deutsch, Politik und Wirtschaft und Wahlpflichtunterricht"
class _NextDayOverviewContent extends StatelessWidget {
  const _NextDayOverviewContent({
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
    final subjects = _distinctSubjects(lessons);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (bounds != null)
          Text(
            'Unterricht von ${_time(bounds.start)}–${_time(bounds.end)} Uhr',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        if (subjects.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Fächer: ${_joinGerman(subjects)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

/// "Morgen" when [day] really is the calendar day after today, else its weekday name
/// (e.g. "Montag" when the next school day is further out, over a weekend/holiday).
String _dayLabel(Date day) {
  if (day.differenceInDays(Date.now()) == 1) {
    return 'Morgen';
  }
  return day.format(intl.DateFormat('EEEE', 'de'));
}

String _time(DateTime time) => intl.DateFormat('H:mm', 'de').format(time);

/// Subject names on [lessons] in first-occurrence (i.e. chronological) order,
/// deduplicated by name and excluding cancelled entries — a subject that only
/// occurs cancelled that day isn't happening, so it's left out.
List<String> _distinctSubjects(List<GridEntry> lessons) {
  final seen = <String>{};
  final names = <String>[];
  for (final entry in lessons) {
    if (entry.isCancelled) {
      continue;
    }
    final name = _subjectName(entry);
    if (seen.add(name)) {
      names.add(name);
    }
  }
  return names;
}

/// Joins [items] the way German lists them in prose: commas throughout, "und" only
/// before the last item — e.g. `["A", "B", "C"]` → `"A, B und C"`.
String _joinGerman(List<String> items) {
  if (items.length <= 1) {
    return items.isEmpty ? '' : items.first;
  }
  return '${items.sublist(0, items.length - 1).join(', ')} und ${items.last}';
}
