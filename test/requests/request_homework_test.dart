import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:your_schedule/core/untis.dart';

import '../support/fixtures.dart';
import '../support/test_shared_preferences.dart';

void main() {
  setUp(initTestSharedPreferences);

  test('requestHomework parses a real getHomeWork2017 RPC response', () async {
    final school = School.fromJson(loadFixtureMap('school.json'));
    final userData = UserData.fromJson(loadFixtureMap('user_data.json'));

    final mockClient = MockClient((request) async {
      final requestBody = jsonDecode(request.body) as Map<String, dynamic>;
      final template = loadFixtureMap('homework_rpc_response.json');
      return http.Response(
        jsonEncode({...template, 'id': requestBody['id']}),
        200,
        headers: {'content-type': 'application/json'},
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

    final homework = await http.runWithClient(
      () => container.read(requestHomeworkProvider(activeSession).future),
      () => mockClient,
    );

    expect(homework.homeWorks, hasLength(3));
    expect(homework.lessonsById[7553]!.subjectId, 15);
    expect(
      container.read(cachedHomeworkProvider(activeSession)).homeWorks,
      hasLength(3),
    );
  });
}
