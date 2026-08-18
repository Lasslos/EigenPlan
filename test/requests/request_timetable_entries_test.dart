import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/week.dart';

import '../support/fixtures.dart';
import '../support/test_shared_preferences.dart';

void main() {
  setUp(initTestSharedPreferences);

  test(
    'requestTimetableEntries sends the passed resource, not userData\'s own',
    () async {
      final school = School.fromJson(loadFixtureMap('school.json'));
      final userData = UserData.fromJson(loadFixtureMap('user_data.json'));

      Uri? capturedUri;
      final mockClient = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(
          loadFixtureRaw('timetable_entries.json'),
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

      final week = Week.relative(0);
      // Deliberately different from userData.type/.id — standing in for a resource
      // picked via the "switch timetable" picker rather than the session's own.
      const resource = TimetableResourceRef(
        resourceType: 'CLASS',
        resourceId: 1217,
      );

      final entries = await http.runWithClient(
        () => container.read(
          requestTimetableEntriesProvider(activeSession, week, resource).future,
        ),
        () => mockClient,
      );

      expect(capturedUri!.queryParameters['resourceType'], 'CLASS');
      expect(capturedUri!.queryParameters['resources'], '1217');
      expect(entries, isNotEmpty);
    },
  );
}
