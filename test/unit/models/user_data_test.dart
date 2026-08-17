import 'package:flutter_test/flutter_test.dart';
import 'package:your_schedule/core/untis.dart';

import '../../support/fixtures.dart';
import '../../support/json_parity.dart';

void main() {
  test('parses a real (trimmed) getUserData2017 response, known gaps only', () {
    final raw = loadFixtureMap('user_data.json');

    final userData = UserData.fromJson(raw);

    expect(userData.id, 1664);
    expect(userData.type, 'CLASS');
    expect(userData.klassen.values.single.name, '10A');
    expect(userData.rooms.values.single.name, 'A-06 ');
    expect(userData.subjects.values.single.longName, '?');
    expect(userData.teachers.values.single.shortName, 'BAL');
    expect(userData.timeGrid, hasLength(2));

    // `UserData.fromJson`/`toJson` are hand-written (not generated — see
    // `lib/core/untis/models/user_data/user_data.dart`) and deliberately only pick
    // out a subset of `getUserData2017`'s master data. Known, currently-dropped
    // fields — a new key here means the API grew something worth capturing, or that
    // `UserData` started dropping something it used to keep. (Each item's `id` is
    // *not* a gap — `toJson` reconstructs it from the enclosing map's key.)
    expect(
      findUnparsedKeys(raw, userData.toJson()),
      unorderedEquals(<String>[
        'masterData.klassen[0].departmentId',
        'masterData.klassen[0].foreColor',
        'masterData.klassen[0].backColor',
        'masterData.rooms[0].departmentId',
        'masterData.rooms[0].foreColor',
        'masterData.rooms[0].backColor',
        'masterData.rooms[0].displayAllowed',
        'masterData.subjects[0].departmentIds',
        'masterData.subjects[0].foreColor',
        'masterData.subjects[0].backColor',
        'masterData.subjects[0].displayAllowed',
        'masterData.teachers[0].departmentIds',
        'masterData.teachers[0].foreColor',
        'masterData.teachers[0].backColor',
        'masterData.teachers[0].entryDate',
        'masterData.teachers[0].exitDate',
        'masterData.teachers[0].displayAllowed',
        'masterData.timeGrid.days[0].day',
        'userData.departmentId',
        'userData.children',
        'userData.klassenIds',
        'userData.rights',
      ]),
    );
  });
}
