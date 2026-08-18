import 'package:flutter_test/flutter_test.dart';
import 'package:your_schedule/core/untis.dart';

GridEntryPositionItem _slot(String type, {String? shortName}) => GridEntryPositionItem(
  current: GridEntryPositionElement(type: type, status: 'REGULAR', shortName: shortName),
);

GridEntry _entry({
  String? subjectShortName,
  String? teacherShortName,
  String? classShortName,
}) => GridEntry(
  duration: GridEntryDuration(start: DateTime(2026), end: DateTime(2026, 1, 1, 1)),
  type: 'NORMAL_TEACHING_PERIOD',
  status: 'REGULAR',
  position1: subjectShortName == null ? null : [_slot('SUBJECT', shortName: subjectShortName)],
  position2: teacherShortName == null ? null : [_slot('TEACHER', shortName: teacherShortName)],
  position3: classShortName == null ? null : [_slot('CLASS', shortName: classShortName)],
);

void main() {
  group('GridEntryCourseIdentity.courseKey', () {
    test('same subject, different teacher → different keys', () {
      var a = _entry(subjectShortName: 'D', teacherShortName: 'MusL');
      var b = _entry(subjectShortName: 'D', teacherShortName: 'SchmJ');

      expect(a.courseKey, isNotNull);
      expect(b.courseKey, isNotNull);
      expect(a.courseKey, isNot(equals(b.courseKey)));
    });

    test('same subject and teacher → same key', () {
      var a = _entry(subjectShortName: 'D', teacherShortName: 'MusL');
      var b = _entry(subjectShortName: 'D', teacherShortName: 'MusL');

      expect(a.courseKey, equals(b.courseKey));
    });

    test('no teacher slot falls back to class (TEACHER resource timetable)', () {
      var entry = _entry(subjectShortName: 'D', classShortName: '5d');

      expect(entry.courseKey, equals('D|5d'));
    });

    test('no subject slot at all → null (non-teaching entry)', () {
      var entry = _entry();

      expect(entry.courseKey, isNull);
    });
  });
}
