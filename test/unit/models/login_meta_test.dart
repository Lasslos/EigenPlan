import 'package:flutter_test/flutter_test.dart';
import 'package:your_schedule/core/untis.dart';

import '../../support/fixtures.dart';
import '../../support/json_parity.dart';

void main() {
  test('parses a real login-meta response with no unrecognized fields', () {
    final raw = loadFixtureMap('login_meta.json');

    final loginMeta = LoginMeta.fromJson(raw);

    expect(loginMeta.anonymousLoginEnabled, isFalse);
    expect(loginMeta.ssoLoginEnabled, isTrue);
    expect(findUnparsedKeys(raw, loginMeta.toJson()), isEmpty);
  });
}
