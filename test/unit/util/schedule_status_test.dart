import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/date.dart';
import 'package:your_schedule/util/schedule_status.dart';

const _resource = TimetableResource(id: 1, shortName: 'own');

TimeGridEntry _grid(String label, int startHour, int endHour) => TimeGridEntry(
      label,
      TimeOfDay(hour: startHour, minute: 0),
      TimeOfDay(hour: endHour, minute: 0),
    );

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
  group('isWithinSchoolHours', () {
    final timeGrid = [_grid('1', 8, 9), _grid('6', 13, 14)];

    test('false for an empty time grid', () {
      expect(isWithinSchoolHours(const [], DateTime(2026, 1, 5, 10)), isFalse);
    });

    test('false before the first lesson starts', () {
      expect(isWithinSchoolHours(timeGrid, DateTime(2026, 1, 5, 7, 59)), isFalse);
    });

    test('false after the last lesson ends', () {
      expect(isWithinSchoolHours(timeGrid, DateTime(2026, 1, 5, 14, 1)), isFalse);
    });

    test('true between the first and last lesson', () {
      expect(isWithinSchoolHours(timeGrid, DateTime(2026, 1, 5, 10)), isTrue);
    });
  });

  group('currentOrNextLesson', () {
    final day1 = DateTime(2026, 1, 5, 8);
    final entries = [
      _entry(start: DateTime(2026, 1, 5, 8), end: DateTime(2026, 1, 5, 9), subjectShortName: 'Ma'),
      _entry(start: DateTime(2026, 1, 5, 9), end: DateTime(2026, 1, 5, 10), subjectShortName: 'De'),
    ];

    test('null when today is null', () {
      expect(currentOrNextLesson(null, day1), isNull);
    });

    test('returns the lesson in progress as current', () {
      final result = currentOrNextLesson(_day(day1, entries), DateTime(2026, 1, 5, 8, 30));
      expect(result?.isCurrent, isTrue);
      expect(result?.entry.positionOfType('SUBJECT')?.current?.shortName, 'Ma');
    });

    test('returns the next lesson during a gap', () {
      // 07:45 is before the first lesson — the "next" one is Ma.
      final result = currentOrNextLesson(_day(day1, entries), DateTime(2026, 1, 5, 7, 45));
      expect(result?.isCurrent, isFalse);
      expect(result?.entry.positionOfType('SUBJECT')?.current?.shortName, 'Ma');
    });

    test('cancelled lessons are skipped', () {
      final cancelled = [
        _entry(start: DateTime(2026, 1, 5, 8), end: DateTime(2026, 1, 5, 9), status: 'CANCELLED', subjectShortName: 'Ma'),
        _entry(start: DateTime(2026, 1, 5, 9), end: DateTime(2026, 1, 5, 10), subjectShortName: 'De'),
      ];
      final result = currentOrNextLesson(_day(day1, cancelled), DateTime(2026, 1, 5, 8, 30));
      expect(result?.entry.positionOfType('SUBJECT')?.current?.shortName, 'De');
    });

    test('null when nothing is left today', () {
      final result = currentOrNextLesson(_day(day1, entries), DateTime(2026, 1, 5, 12));
      expect(result, isNull);
    });
  });

  group('todaysIrregularities', () {
    final day1 = DateTime(2026, 1, 5, 8);

    test('classifies cancelled, changed, and event entries', () {
      final entries = [
        _entry(start: DateTime(2026, 1, 5, 8), end: DateTime(2026, 1, 5, 9), status: 'CANCELLED', subjectShortName: 'Ma'),
        _entry(start: DateTime(2026, 1, 5, 9), end: DateTime(2026, 1, 5, 10), status: 'CHANGED', subjectShortName: 'De'),
        _entry(start: DateTime(2026, 1, 5, 11), end: DateTime(2026, 1, 5, 12), type: 'EVENT', subjectShortName: 'Sport'),
        _entry(start: DateTime(2026, 1, 5, 12), end: DateTime(2026, 1, 5, 13), subjectShortName: 'Regular'),
      ];
      final result = todaysIrregularities(_day(day1, entries), const {});
      expect(result, hasLength(3));
      expect(result[0].kind, IrregularityKind.cancelled);
      expect(result[1].kind, IrregularityKind.changed);
      expect(result[2].kind, IrregularityKind.event);
    });

    test('respects filter overrides', () {
      final entries = [
        _entry(start: DateTime(2026, 1, 5, 8), end: DateTime(2026, 1, 5, 9), status: 'CANCELLED', subjectShortName: 'Ma'),
      ];
      final result = todaysIrregularities(_day(day1, entries), {'Ma|': false});
      expect(result, isEmpty);
    });

    test('empty for a null day', () {
      expect(todaysIrregularities(null, const {}), isEmpty);
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
      expect(schoolDayBounds(null), isNull);
    });

    test('null when every entry is cancelled', () {
      final entries = [
        _entry(start: DateTime(2026, 1, 5, 8), end: DateTime(2026, 1, 5, 9), status: 'CANCELLED', subjectShortName: 'Ma'),
      ];
      expect(schoolDayBounds(_day(day1, entries)), isNull);
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
      final bounds = schoolDayBounds(_day(day1, entries));
      expect(bounds?.start, DateTime(2026, 1, 5, 8));
      expect(bounds?.end, DateTime(2026, 1, 5, 13));
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
}
