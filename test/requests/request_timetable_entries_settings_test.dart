import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:your_schedule/core/untis.dart';

import '../support/fixtures.dart';

void main() {
  test(
    'requestTimetableEntriesSettings sends resourceType and parses the response',
    () async {
      final school = School.fromJson(loadFixtureMap('school.json'));
      final userData = UserData.fromJson(loadFixtureMap('user_data.json'));

      Uri? capturedUri;
      final mockClient = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(
          loadFixtureRaw('timetable_entries_settings.json'),
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

      final settings = await http.runWithClient(
        () => container.read(
          requestTimetableEntriesSettingsProvider(
            activeSession,
            'TEACHER',
          ).future,
        ),
        () => mockClient,
      );

      expect(capturedUri!.queryParameters['resourceType'], 'TEACHER');
      expect(settings.showTeacherAbsences, isTrue);
      expect(settings.showSymbols, isFalse);
    },
  );
}
