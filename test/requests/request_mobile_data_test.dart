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
    'requestMobileData parses a mobile/data response and populates the cache',
    () async {
      final school = School.fromJson(loadFixtureMap('school.json'));
      final userData = UserData.fromJson(loadFixtureMap('user_data.json'));

      final mockClient = MockClient((request) async {
        return http.Response(
          loadFixtureRaw('mobile_data.json'),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      // Anonymous, specifically to avoid needing to mock authTokenProvider — anonymous
      // sessions skip fetching an auth token entirely (see request_mobile_data.dart).
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

      final mobileData = await http.runWithClient(
        () => container.read(requestMobileDataProvider(activeSession).future),
        () => mockClient,
      );

      expect(mobileData.tenant.displayName, 'Musterschule');
      expect(
        container
            .read(cachedMobileDataProvider(activeSession))
            ?.tenant
            .displayName,
        'Musterschule',
      );
    },
  );
}
