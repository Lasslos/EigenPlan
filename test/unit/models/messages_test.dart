import 'package:flutter_test/flutter_test.dart';
import 'package:your_schedule/core/untis.dart';

import '../../support/fixtures.dart';
import '../../support/json_parity.dart';

void main() {
  test('parses a real messages-list response with no unrecognized fields', () {
    final raw = loadFixtureMap('messages.json');

    final messages = Messages.fromJson(raw);

    expect(messages.incomingMessages, hasLength(2));
    expect(messages.incomingMessages.first.id, 4890);
    expect(messages.incomingMessages.first.sender.displayName, 'Admin_1');
    expect(messages.incomingMessages[1].hasAttachments, isTrue);
    expect(findUnparsedKeys(raw, messages.toJson()), isEmpty);
  });
}
