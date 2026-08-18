import 'package:flutter_test/flutter_test.dart';
import 'package:your_schedule/core/untis.dart';

import '../../support/fixtures.dart';
import '../../support/json_parity.dart';

void main() {
  test('parses a timetable/menu response, all fields round-trip', () {
    final raw = loadFixtureMap('timetable_menu.json');

    final menu = TimetableMenuResponse.fromJson(raw);

    expect(menu.myTimetable.type, 'TEACHER');
    expect(menu.myTimetable.resource.id, 134);
    expect(menu.dependents, isEmpty);
    expect(menu.availableTimetables, ['CLASS', 'STUDENT', 'TEACHER', 'ROOM']);
    expect(findUnparsedKeys(raw, menu.toJson()), isEmpty);
  });
}
