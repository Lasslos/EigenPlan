import 'package:flutter_test/flutter_test.dart';
import 'package:your_schedule/core/untis.dart';

import '../../support/fixtures.dart';
import '../../support/json_parity.dart';

void main() {
  test('parses a real school-search result, known gaps only', () {
    final raw = loadFixtureMap('school.json');

    final school = School.fromJson(raw);

    expect(school.loginName, 'cjd-koewi');
    expect(school.server, 'cjd-koewi.webuntis.com');
    expect(school.rpcUrl, 'https://cjd-koewi.webuntis.com/WebUntis/jsonrpc_intern.do?school=cjd-koewi');

    // Known, currently-unmodeled fields — not used anywhere in the app today.
    // A new key showing up here (not in this list) means the API added something
    // `School` might actually need.
    expect(
      findUnparsedKeys(raw, school.toJson()),
      unorderedEquals(<String>[
        'useMobileServiceUrlAndroid',
        'useMobileServiceUrlIos',
        'tenantId',
        'mobileServiceUrl',
      ]),
    );
  });
}
