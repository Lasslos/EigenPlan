import 'package:flutter_test/flutter_test.dart';
import 'package:your_schedule/core/untis.dart';

import '../../support/fixtures.dart';
import '../../support/json_parity.dart';

// TimetableFilterResponse is deliberately partial (see its doc comment):
// buildings/departments/roomGroups/resourceTypes/assignmentGroups/resources/subjects
// (always empty, UNKNOWN item shape in every capture so far) and the per-student
// assignmentGroups/per-room roomGroups fields aren't modeled — expected gaps below,
// not asserted as findUnparsedKeys(...).isEmpty.
const _unmodeledTopLevel = [
  'buildings',
  'departments',
  'roomGroups',
  'resourceTypes',
  'assignmentGroups',
  'resources',
  'subjects',
];

void main() {
  test('parses a CLASS timetable/filter response', () {
    final raw = loadFixtureMap('timetable_filter_class.json');
    final filter = TimetableFilterResponse.fromJson(raw);

    expect(filter.resourceType, 'CLASS');
    expect(filter.preSelected!.shortName, '5d');
    expect(filter.classes, hasLength(1));
    expect(filter.classes.single.classResource.shortName, '10a');
    expect(filter.classes.single.classTeacher1!.shortName, 'ML1');
    expect(filter.classes.single.classTeacher2, isNull);
    expect(
      findUnparsedKeys(raw, filter.toJson()),
      unorderedEquals(_unmodeledTopLevel),
    );
  });

  test('parses a TEACHER timetable/filter response', () {
    final raw = loadFixtureMap('timetable_filter_teacher.json');
    final filter = TimetableFilterResponse.fromJson(raw);

    expect(filter.resourceType, 'TEACHER');
    expect(filter.teachers, hasLength(1));
    expect(filter.teachers.single.teacher.id, 134);
    expect(filter.teachers.single.departments, hasLength(1));
    expect(
      findUnparsedKeys(raw, filter.toJson()),
      unorderedEquals(_unmodeledTopLevel),
    );
  });

  test('parses a ROOM timetable/filter response', () {
    final raw = loadFixtureMap('timetable_filter_room.json');
    final filter = TimetableFilterResponse.fromJson(raw);

    expect(filter.resourceType, 'ROOM');
    expect(filter.preSelected, isNull);
    expect(filter.rooms, hasLength(1));
    expect(filter.rooms.single.room.shortName, '1a3');
    expect(filter.rooms.single.capacity, 0);
    expect(
      findUnparsedKeys(raw, filter.toJson()),
      unorderedEquals([..._unmodeledTopLevel, 'rooms[0].roomGroups']),
    );
  });

  test('parses a STUDENT timetable/filter response', () {
    final raw = loadFixtureMap('timetable_filter_student.json');
    final filter = TimetableFilterResponse.fromJson(raw);

    expect(filter.resourceType, 'STUDENT');
    expect(filter.classes, hasLength(1));
    expect(filter.students, hasLength(1));
    expect(filter.students.single.student.id, 6542);
    expect(filter.students.single.classes.single.classResource.shortName, '6a');
    expect(
      findUnparsedKeys(raw, filter.toJson()),
      unorderedEquals([..._unmodeledTopLevel, 'students[0].assignmentGroups']),
    );
  });
}
