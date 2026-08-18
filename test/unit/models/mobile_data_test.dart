import 'package:flutter_test/flutter_test.dart';
import 'package:your_schedule/core/untis.dart';

import '../../support/fixtures.dart';
import '../../support/json_parity.dart';

void main() {
  test('parses a mobile/data response, all fields round-trip', () {
    // No capture ever showed a populated `user`/`schoolYear` shape from this
    // repository's own account set (see docs/api/spec/NOTES.md) — hand-constructed
    // to match MobileData's own fields, mirroring exam_test.dart's approach.
    final raw = loadFixtureMap('mobile_data.json');

    final mobileData = MobileData.fromJson(raw);

    expect(mobileData.tenant.displayName, 'Musterschule');
    expect(mobileData.user!.person.imageUrl, isNotNull);
    expect(mobileData.schoolYear!.name, '2026/2027');
    expect(findUnparsedKeys(raw, mobileData.toJson()), isEmpty);
  });
}
