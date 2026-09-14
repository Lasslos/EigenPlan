import 'package:flutter_test/flutter_test.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/date.dart';
import 'package:your_schedule/util/schedule_status.dart';

const _resource = TimetableResource(id: 1, shortName: 'own');

GridEntry _entry({
  required DateTime start,
  required DateTime end,
  String type = 'NORMAL_TEACHING_PERIOD',
  String status = 'REGULAR',
  List<String> icons = const [],
  String? subjectShortName,
}) =>
    GridEntry(
      duration: GridEntryDuration(start: start, end: end),
      type: type,
      status: status,
      icons: icons,
      position1: subjectShortName == null
          ? null
          : [
              GridEntryPositionItem(
                current: GridEntryPositionElement(
                  type: 'SUBJECT',
                  status: 'REGULAR',
                  shortName: subjectShortName,
                ),
              ),
            ],
    );

TimetableDay _day(DateTime date, List<GridEntry> entries, {String status = 'REGULAR'}) => TimetableDay(
      date: date,
      resourceType: 'STUDENT',
      resource: _resource,
      status: status,
      gridEntries: entries,
    );

void main() {
  group('schoolDayPhase', () {
    final day1 = DateTime(2026, 1, 5, 8);
    final bounds = (start: DateTime(2026, 1, 5, 8), end: DateTime(2026, 1, 5, 13));

    test('null for a day with no bounds at all', () {
      expect(schoolDayPhase(null, DateTime(2026, 1, 5, 10)), isNull);
    });

    test('beforeStart while the first lesson is further off than the lead-in', () {
      expect(schoolDayPhase(bounds, DateTime(2026, 1, 5, 5, 30)), ScheduleDayPhase.beforeStart);
      expect(schoolDayPhase(bounds, DateTime(2026, 1, 5, 5, 59)), ScheduleDayPhase.beforeStart);
    });

    test('startingSoon once the lead-in window opens', () {
      expect(schoolDayPhase(bounds, DateTime(2026, 1, 5, 6)), ScheduleDayPhase.startingSoon);
      expect(schoolDayPhase(bounds, DateTime(2026, 1, 5, 7, 59)), ScheduleDayPhase.startingSoon);
    });

    test('honours a custom lead-in', () {
      expect(
        schoolDayPhase(bounds, DateTime(2026, 1, 5, 7, 20), leadIn: const Duration(minutes: 30)),
        ScheduleDayPhase.beforeStart,
      );
      expect(
        schoolDayPhase(bounds, DateTime(2026, 1, 5, 7, 40), leadIn: const Duration(minutes: 30)),
        ScheduleDayPhase.startingSoon,
      );
    });

    test('inProgress from the first lesson onwards, including breaks', () {
      expect(schoolDayPhase(bounds, DateTime(2026, 1, 5, 8)), ScheduleDayPhase.inProgress);
      expect(schoolDayPhase(bounds, DateTime(2026, 1, 5, 10, 15)), ScheduleDayPhase.inProgress);
      expect(schoolDayPhase(bounds, DateTime(2026, 1, 5, 12, 59)), ScheduleDayPhase.inProgress);
    });

    test('null once the last lesson has ended', () {
      expect(schoolDayPhase(bounds, DateTime(2026, 1, 5, 13)), isNull);
      expect(schoolDayPhase(bounds, DateTime(2026, 1, 5, 15)), isNull);
    });

    test('a cancelled first period pushes the start back, not the phase forward', () {
      // The reported bug in miniature: at 08:30 the day the user actually attends hasn't
      // begun, so this is still a day being waited on — not one already under way.
      final entries = [
        _entry(start: DateTime(2026, 1, 5, 8), end: DateTime(2026, 1, 5, 9), status: 'CANCELLED', subjectShortName: 'Ma'),
        _entry(start: DateTime(2026, 1, 5, 9), end: DateTime(2026, 1, 5, 10), subjectShortName: 'De'),
      ];
      final phase = schoolDayPhase(schoolDayBounds(_day(day1, entries), const {}), DateTime(2026, 1, 5, 8, 30));
      expect(phase, ScheduleDayPhase.startingSoon);
    });
  });

  group('currentOrNextLesson', () {
    final day1 = DateTime(2026, 1, 5, 8);
    final entries = [
      _entry(start: DateTime(2026, 1, 5, 8), end: DateTime(2026, 1, 5, 9), subjectShortName: 'Ma'),
      _entry(start: DateTime(2026, 1, 5, 9), end: DateTime(2026, 1, 5, 10), subjectShortName: 'De'),
    ];

    test('null when today is null', () {
      expect(currentOrNextLesson(null, day1, const {}), isNull);
    });

    test('returns the lesson in progress as current', () {
      final result = currentOrNextLesson(_day(day1, entries), DateTime(2026, 1, 5, 8, 30), const {});
      expect(result?.isCurrent, isTrue);
      expect(result?.entry.positionOfType('SUBJECT')?.current?.shortName, 'Ma');
    });

    test('returns the next lesson during a gap', () {
      // 07:45 is before the first lesson — the "next" one is Ma.
      final result = currentOrNextLesson(_day(day1, entries), DateTime(2026, 1, 5, 7, 45), const {});
      expect(result?.isCurrent, isFalse);
      expect(result?.entry.positionOfType('SUBJECT')?.current?.shortName, 'Ma');
    });

    test('cancelled lessons are skipped', () {
      final cancelled = [
        _entry(start: DateTime(2026, 1, 5, 8), end: DateTime(2026, 1, 5, 9), status: 'CANCELLED', subjectShortName: 'Ma'),
        _entry(start: DateTime(2026, 1, 5, 9), end: DateTime(2026, 1, 5, 10), subjectShortName: 'De'),
      ];
      final result = currentOrNextLesson(_day(day1, cancelled), DateTime(2026, 1, 5, 8, 30), const {});
      expect(result?.entry.positionOfType('SUBJECT')?.current?.shortName, 'De');
    });

    test('null when nothing is left today', () {
      final result = currentOrNextLesson(_day(day1, entries), DateTime(2026, 1, 5, 12), const {});
      expect(result, isNull);
    });

    test('filtered-out courses are skipped, like cancelled ones', () {
      final result = currentOrNextLesson(_day(day1, entries), DateTime(2026, 1, 5, 8, 30), {'Ma|': false});
      expect(result?.entry.positionOfType('SUBJECT')?.current?.shortName, 'De');
    });
  });

  group('irregularitiesFor', () {
    final day1 = DateTime(2026, 1, 5, 8);

    test('classifies cancelled, changed, and event entries', () {
      final entries = [
        _entry(start: DateTime(2026, 1, 5, 8), end: DateTime(2026, 1, 5, 9), status: 'CANCELLED', subjectShortName: 'Ma'),
        _entry(start: DateTime(2026, 1, 5, 9), end: DateTime(2026, 1, 5, 10), status: 'CHANGED', subjectShortName: 'De'),
        _entry(start: DateTime(2026, 1, 5, 11), end: DateTime(2026, 1, 5, 12), type: 'EVENT', subjectShortName: 'Sport'),
        _entry(start: DateTime(2026, 1, 5, 12), end: DateTime(2026, 1, 5, 13), subjectShortName: 'Regular'),
      ];
      final result = irregularitiesFor(_day(day1, entries), const {});
      expect(result, hasLength(3));
      expect(result[0].kind, IrregularityKind.cancelled);
      expect(result[1].kind, IrregularityKind.changed);
      expect(result[2].kind, IrregularityKind.event);
    });

    test('respects filter overrides', () {
      final entries = [
        _entry(start: DateTime(2026, 1, 5, 8), end: DateTime(2026, 1, 5, 9), status: 'CANCELLED', subjectShortName: 'Ma'),
      ];
      final result = irregularitiesFor(_day(day1, entries), {'Ma|': false});
      expect(result, isEmpty);
    });

    test('empty for a null day', () {
      expect(irregularitiesFor(null, const {}), isEmpty);
    });
  });

  group('nextSchoolDay', () {
    test('skips the weekend (Saturday-boundary regression)', () {
      var friday = DateTime(2026, 1, 1);
      while (friday.weekday != DateTime.friday) {
        friday = friday.add(const Duration(days: 1));
      }
      final result = nextSchoolDay(Date(friday), const []);
      expect(result?.weekday, DateTime.monday);
      expect(result?.differenceInDays(Date(friday)), 3);
    });

    test('skips days covered by a holiday', () {
      var monday = DateTime(2026, 1, 1);
      while (monday.weekday != DateTime.monday) {
        monday = monday.add(const Duration(days: 1));
      }
      final holiday = Holiday(
        'Ferien',
        'Ferien',
        monday.add(const Duration(days: 1)),
        monday.add(const Duration(days: 3)),
      );
      final result = nextSchoolDay(Date(monday), [holiday]);
      expect(result?.isAtSameMomentAs(Date(monday.add(const Duration(days: 4)))), isTrue);
    });
  });

  group('lookupDay', () {
    test('falls back from week1 to week2', () {
      final day = Date(DateTime(2026, 1, 6));
      final dayData = _day(DateTime(2026, 1, 6), const []);
      expect(lookupDay(day, const {}, {day: dayData}), same(dayData));
    });
  });

  group('schoolDayBounds', () {
    final day1 = DateTime(2026, 1, 5, 8);

    test('null for a null day', () {
      expect(schoolDayBounds(null, const {}), isNull);
    });

    test('null when every entry is cancelled', () {
      final entries = [
        _entry(start: DateTime(2026, 1, 5, 8), end: DateTime(2026, 1, 5, 9), status: 'CANCELLED', subjectShortName: 'Ma'),
      ];
      expect(schoolDayBounds(_day(day1, entries), const {}), isNull);
    });

    test('spans the earliest start to the latest end, ignoring cancelled entries', () {
      final entries = [
        // Cancelled first period — shouldn't count as the real start.
        _entry(start: DateTime(2026, 1, 5, 7), end: DateTime(2026, 1, 5, 8), status: 'CANCELLED', subjectShortName: 'Ma'),
        _entry(start: DateTime(2026, 1, 5, 8), end: DateTime(2026, 1, 5, 9), subjectShortName: 'De'),
        // Cancelled last period — shouldn't count as the real end.
        _entry(start: DateTime(2026, 1, 5, 13), end: DateTime(2026, 1, 5, 14), status: 'CANCELLED', subjectShortName: 'Sport'),
        _entry(start: DateTime(2026, 1, 5, 12), end: DateTime(2026, 1, 5, 13), subjectShortName: 'Ku'),
      ];
      final bounds = schoolDayBounds(_day(day1, entries), const {});
      expect(bounds?.start, DateTime(2026, 1, 5, 8));
      expect(bounds?.end, DateTime(2026, 1, 5, 13));
    });

    test('ignores filtered-out courses, like cancelled entries', () {
      final entries = [
        _entry(start: DateTime(2026, 1, 5, 7), end: DateTime(2026, 1, 5, 8), subjectShortName: 'Ma'),
        _entry(start: DateTime(2026, 1, 5, 8), end: DateTime(2026, 1, 5, 9), subjectShortName: 'De'),
      ];
      final bounds = schoolDayBounds(_day(day1, entries), {'Ma|': false});
      expect(bounds?.start, DateTime(2026, 1, 5, 8));
      expect(bounds?.end, DateTime(2026, 1, 5, 9));
    });
  });

  group('visibleLessonsFor', () {
    final day1 = DateTime(2026, 1, 5, 8);

    test('includes cancelled entries, sorted by start time', () {
      final entries = [
        _entry(start: DateTime(2026, 1, 5, 9), end: DateTime(2026, 1, 5, 10), subjectShortName: 'De'),
        _entry(start: DateTime(2026, 1, 5, 8), end: DateTime(2026, 1, 5, 9), status: 'CANCELLED', subjectShortName: 'Ma'),
      ];
      final result = visibleLessonsFor(_day(day1, entries), const {});
      expect(result, hasLength(2));
      expect(result.first.positionOfType('SUBJECT')?.current?.shortName, 'Ma');
      expect(result.first.isCancelled, isTrue);
    });

    test('respects filter overrides', () {
      final entries = [
        _entry(start: DateTime(2026, 1, 5, 8), end: DateTime(2026, 1, 5, 9), subjectShortName: 'Ma'),
      ];
      expect(visibleLessonsFor(_day(day1, entries), {'Ma|': false}), isEmpty);
    });

    test('empty for a non-REGULAR day', () {
      final entries = [
        _entry(start: DateTime(2026, 1, 5, 8), end: DateTime(2026, 1, 5, 9), subjectShortName: 'Ma'),
      ];
      expect(visibleLessonsFor(_day(day1, entries, status: 'NO_DATA'), const {}), isEmpty);
    });

    test('empty for a null day', () {
      expect(visibleLessonsFor(null, const {}), isEmpty);
    });
  });

  group('minutesUntil', () {
    final start = DateTime(2026, 1, 5, 11, 45);

    test('counts whole minutes left, not minutes elapsed', () {
      expect(minutesUntil(start, DateTime(2026, 1, 5, 11, 43)), 2);
      expect(minutesUntil(start, DateTime(2026, 1, 5, 11, 44)), 1);
    });

    test('rounds up a partial minute rather than truncating', () {
      // The reported bug: 90s left used to render as "1 Minute".
      expect(minutesUntil(start, DateTime(2026, 1, 5, 11, 43, 30)), 2);
      expect(minutesUntil(start, DateTime(2026, 1, 5, 11, 44, 59)), 1);
    });

    test('hits zero only once the target is reached', () {
      expect(minutesUntil(start, start.subtract(const Duration(seconds: 1))), 1);
      expect(minutesUntil(start, start), 0);
    });

    test('clamps past targets to zero instead of going negative', () {
      expect(minutesUntil(start, DateTime(2026, 1, 5, 12)), 0);
    });
  });

  group('minutesLabel', () {
    test('inflects the German unit', () {
      expect(minutesLabel(1), '1 Minute');
      expect(minutesLabel(2), '2 Minuten');
      expect(minutesLabel(0), '0 Minuten');
    });
  });

  group('durationLabel', () {
    test('stays in minutes below an hour', () {
      expect(durationLabel(0), '0 Minuten');
      expect(durationLabel(1), '1 Minute');
      expect(durationLabel(59), '59 Minuten');
    });

    test('splits into hours and minutes from an hour up', () {
      // A two-hour lead-in would otherwise read as "119 Minuten".
      expect(durationLabel(60), '1 Std.');
      expect(durationLabel(119), '1 Std. 59 Min.');
      expect(durationLabel(120), '2 Std.');
      expect(durationLabel(125), '2 Std. 5 Min.');
    });
  });
}
