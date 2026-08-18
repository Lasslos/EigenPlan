import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:your_schedule/core/untis.dart';

import '../support/fixtures.dart';

void main() {
  test(
    'elementTypeForResourceType resolves confirmed live mappings, else null',
    () {
      expect(elementTypeForResourceType('STUDENT'), 5);
      expect(elementTypeForResourceType('TEACHER'), 2);
      expect(elementTypeForResourceType('CLASS'), isNull);
      expect(elementTypeForResourceType(null), isNull);
    },
  );

  test(
    'requestCalendarEntryDetail queries elementId=userData.id, not a period id',
    () async {
      final school = School.fromJson(loadFixtureMap('school.json'));
      final userData = UserData.fromJson(loadFixtureMap('user_data.json'));

      Uri? capturedUri;
      final mockClient = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(
          loadFixtureRaw('calendar_entry_detail_response.json'),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      // Anonymous, specifically to avoid needing to mock authTokenProvider.
      final activeSession =
          UntisSession.active(
                school,
                LoginMode.anonymous,
                null,
                null,
                null,
                userData,
              )
              as ActiveUntisSession;

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final start = DateTime(2026, 8, 18, 7, 55);
      final end = DateTime(2026, 8, 18, 9, 25);

      // A deliberately different-looking value from userData.id, standing in for a
      // period/GridEntry.ids[] value a caller must NOT pass here — this test exists
      // specifically because that mistake silently returns zero calendarEntries
      // instead of erroring (see the live-probe note in request_calendar_entry_detail.dart).
      final entries = await http.runWithClient(
        () => container.read(
          requestCalendarEntryDetailProvider(
            activeSession,
            5,
            userData.id,
            start,
            end,
          ).future,
        ),
        () => mockClient,
      );

      expect(capturedUri!.queryParameters['elementId'], userData.id.toString());
      expect(capturedUri!.queryParameters['elementType'], '5');
      expect(entries, hasLength(1));
      expect(entries.single.homeworks, hasLength(1));
    },
  );
}
