import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:your_schedule/core/untis.dart';

import '../support/fixtures.dart';
import '../support/test_shared_preferences.dart';

void main() {
  setUp(initTestSharedPreferences);

  test(
    'requestTimetableMenu parses a 200 response and populates the cache',
    () async {
      final school = School.fromJson(loadFixtureMap('school.json'));
      final userData = UserData.fromJson(loadFixtureMap('user_data.json'));

      final mockClient = MockClient((request) async {
        return http.Response(
          loadFixtureRaw('timetable_menu.json'),
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

      final menu = await http.runWithClient(
        () =>
            container.read(requestTimetableMenuProvider(activeSession).future),
        () => mockClient,
      );

      expect(menu!.myTimetable.type, 'TEACHER');
      expect(menu.myTimetable.resource.id, 134);
      expect(menu.availableTimetables, ['CLASS', 'STUDENT', 'TEACHER', 'ROOM']);
      expect(
        container
            .read(cachedTimetableMenuProvider(activeSession))
            ?.myTimetable
            .resource
            .id,
        134,
      );
    },
  );

  test(
    'requestTimetableMenu returns null on the documented 404 (no timetable resource)',
    () async {
      final school = School.fromJson(loadFixtureMap('school.json'));
      final userData = UserData.fromJson(loadFixtureMap('user_data.json'));

      final mockClient = MockClient((request) async {
        return http.Response(
          '{"errorCode":"NO_TIMETABLES_AVAILABLE_FOR_YOUR_USER"}',
          404,
        );
      });

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

      final menu = await http.runWithClient(
        () =>
            container.read(requestTimetableMenuProvider(activeSession).future),
        () => mockClient,
      );

      expect(menu, isNull);
    },
  );
}
