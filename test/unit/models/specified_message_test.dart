import 'package:flutter_test/flutter_test.dart';
import 'package:your_schedule/core/untis.dart';

import '../../support/fixtures.dart';
import '../../support/json_parity.dart';

void main() {
  test('parses a real message detail with an S3-backed (storage) attachment', () {
    final raw = loadFixtureMap('specified_message_storage_attachment.json');

    final message = SpecifiedMessage.fromJson(raw);

    expect(message.id, 4857);
    expect(message.storageAttachments, hasLength(1));
    expect(message.storageAttachments.first.name, 'Schulmusical-Plakat.pdf');
    expect(message.attachments, isEmpty);
    expect(findUnparsedKeys(raw, message.toJson()), isEmpty);
  });

  test('parses a real message detail with an externally-hosted attachment', () {
    final raw = loadFixtureMap('specified_message_external_attachment.json');

    final message = SpecifiedMessage.fromJson(raw);

    expect(message.id, 11743);
    expect(message.attachments, hasLength(2));
    expect(message.storageAttachments, isEmpty);
    expect(findUnparsedKeys(raw, message.toJson()), isEmpty);
  });
}
