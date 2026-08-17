import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:your_schedule/core/untis.dart';

import '../support/fixtures.dart';

void main() {
  test('requestLoginMeta hits login-meta and parses the response', () async {
    final school = School.fromJson(loadFixtureMap('school.json'));

    final mockClient = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/WebUntis/api/public/v1/login-meta');
      expect(request.url.queryParameters['school'], 'cjd-koewi');
      return http.Response(
        loadFixtureRaw('login_meta.json'),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final loginMeta = await http.runWithClient(
      () => container.read(requestLoginMetaProvider(school).future),
      () => mockClient,
    );

    expect(loginMeta.ssoLoginEnabled, isTrue);
    expect(loginMeta.anonymousLoginEnabled, isFalse);
  });
}
