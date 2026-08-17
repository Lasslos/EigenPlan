import 'package:flutter_test/flutter_test.dart';
import 'package:your_schedule/core/untis.dart';

import '../../support/fixtures.dart';
import '../../support/json_parity.dart';

void main() {
  test('parses a real timetable/entries response, known gaps only', () {
    final raw = loadFixtureMap('timetable_entries.json');

    final response = TimetableEntriesResponse.fromJson(raw);

    expect(response.days, hasLength(1));
    final day = response.days.single;
    expect(day.gridEntries, hasLength(1));
    final entry = day.gridEntries.single;
    expect(entry.positionOfType('SUBJECT')?.current.shortName, 'G');
    expect(entry.positionOfType('TEACHER')?.current.shortName, 'MusL');
    expect(entry.isCancelled, isFalse);
    expect(entry.hasSubstitution, isFalse);

    // Known, currently-unmodeled fields observed live on `TimetableDay`/`GridEntry`
    // (see docs/api/captures/home/timetable_entries.md). A new key here means the
    // API grew something these models should probably start capturing.
    expect(
      findUnparsedKeys(raw, response.toJson()),
      unorderedEquals(<String>[
        'days[0].dayEntries',
        'days[0].backEntries',
        'days[0].gridEntries[0].name',
        'days[0].gridEntries[0].userName',
        'days[0].gridEntries[0].moved',
        'days[0].gridEntries[0].durationTotal',
        'days[0].gridEntries[0].link',
      ]),
    );
  });
}
