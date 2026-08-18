import 'package:flutter_test/flutter_test.dart';
import 'package:your_schedule/core/untis.dart';

import '../../support/fixtures.dart';

// No `findUnparsedKeys` parity assertion in this file, unlike most model tests —
// CalendarEntryDetail deliberately models only the fields not already available from
// the GridEntry the user tapped (subject/room/teacher/klasses/status/type/times), so
// a parity check would fail on every field left out by design. See the doc comment on
// CalendarEntryDetail in calendar_entry_detail.dart for the full rationale.
void main() {
  test('parses a calendar-entry/detail response, modeled fields resolve', () {
    // Derived from docs/api/captures/home/calender-entry.md's wolfsburger-oberschule
    // example, with a `homeworks[0]` item added matching the shape confirmed via a
    // live probe (see docs/api/spec/NOTES.md §5.4/§5.5) — the original captures never
    // had real homework attached to test against.
    final raw = loadFixtureMap('calendar_entry_detail_response.json');

    final response = CalendarEntryDetailResponse.fromJson(raw);

    expect(response.calendarEntries, hasLength(1));
    final entry = response.calendarEntries.single;
    expect(entry.id, 2499695);
    expect(entry.notesAll, 'Bitte Aufgaben mitbringen');
    expect(entry.notesStaff, isNull);
    expect(entry.homeworks, hasLength(1));
    expect(entry.homeworks.single.text, 'Macht einfach irgendetwas');
    expect(entry.homeworks.single.completed, isFalse);
    expect(entry.integrationsSection, hasLength(1));
    expect(entry.integrationsSection.single.name, 'Messenger');
  });
}
