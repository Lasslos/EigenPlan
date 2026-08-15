import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_attachment.freezed.dart';
part 'message_attachment.g.dart';

/// An externally-hosted message attachment (e.g. a SharePoint link) —
/// `downloadUrl` is directly usable, no signed-URL dance needed. `id` is observed
/// as the literal string `"0"` for every attachment of this kind — likely means "no
/// real numeric id, externally hosted" rather than a meaningful identifier.
@freezed
abstract class ExternalAttachment with _$ExternalAttachment {
  const factory ExternalAttachment({
    required String id,
    required String name,
    required String downloadUrl,
  }) = _ExternalAttachment;

  factory ExternalAttachment.fromJson(Map<String, dynamic> json) => _$ExternalAttachmentFromJson(json);
}

/// An attachment stored in Untis's own S3-compatible storage — requires
/// `request_attachment_storage_url.dart` to resolve an actual download URL before it
/// can be fetched.
@freezed
abstract class StorageAttachment with _$StorageAttachment {
  const factory StorageAttachment({
    required String id,
    required String name,
  }) = _StorageAttachment;

  factory StorageAttachment.fromJson(Map<String, dynamic> json) => _$StorageAttachmentFromJson(json);
}
