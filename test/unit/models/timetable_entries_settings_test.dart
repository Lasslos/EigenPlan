import 'package:flutter_test/flutter_test.dart';
import 'package:your_schedule/core/untis.dart';

import '../../support/fixtures.dart';
import '../../support/json_parity.dart';

void main() {
  test(
    'parses a timetable/entries/settings response, all fields round-trip',
    () {
      final raw = loadFixtureMap('timetable_entries_settings.json');

      final settings = TimetableEntriesSettings.fromJson(raw);

      expect(settings.showTeacherAbsences, isTrue);
      expect(settings.showSymbols, isFalse);
      expect(findUnparsedKeys(raw, settings.toJson()), isEmpty);
    },
  );
}
