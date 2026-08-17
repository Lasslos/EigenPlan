import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:your_schedule/core/untis.dart';

import '../support/fixtures.dart';

void main() {
  test('requestSchoolList parses a real searchSchool RPC response', () async {
    final mockClient = MockClient((request) async {
      final requestBody = jsonDecode(request.body) as Map<String, dynamic>;
      final template = loadFixtureMap('school_search_rpc_response.json');
      return http.Response(
        jsonEncode({...template, 'id': requestBody['id']}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final schools = await http.runWithClient(
      () => container.read(requestSchoolListProvider('cjd').future),
      () => mockClient,
    );

    expect(schools, hasLength(1));
    expect(schools.single.loginName, 'cjd-koewi');
  });
}
