import 'dart:convert';

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

  test('requestExams parses a real empty-exams RPC response', () async {
    // Regression test: this used to throw a NoSuchMethodError at runtime
    // (`response.result.result['exams']` — a stray double `.result`) for every
    // exams request, real data or not. See request_exams.dart.
    final school = School.fromJson(loadFixtureMap('school.json'));
    final userData = UserData.fromJson(loadFixtureMap('user_data.json'));

    final mockClient = MockClient((request) async {
      final requestBody = jsonDecode(request.body) as Map<String, dynamic>;
      final template = loadFixtureMap('exams_rpc_response_empty.json');
      return http.Response(
        jsonEncode({...template, 'id': requestBody['id']}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final activeSession = UntisSession.active(
      school,
      LoginMode.anonymous,
      null,
      null,
      null,
      userData,
    ) as ActiveUntisSession;

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final examsByDay = await http.runWithClient(
      () => container.read(requestExamsProvider(activeSession, Week.now()).future),
      () => mockClient,
    );

    expect(examsByDay, hasLength(7));
    expect(examsByDay.values.every((exams) => exams.isEmpty), isTrue);
  });
}
