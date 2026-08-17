import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'attachment_storage_url.freezed.dart';
part 'attachment_storage_url.g.dart';

@freezed
abstract class AdditionalHeader with _$AdditionalHeader {
  const factory AdditionalHeader({
    required String key,
    required String value,
  }) = _AdditionalHeader;

  factory AdditionalHeader.fromJson(Map<String, dynamic> json) => _$AdditionalHeaderFromJson(json);
}

/// Response of `GET /messages/{id}/attachmentstorageurl`. [downloadUrl] is a
/// pre-signed S3 URL using server-side encryption with a customer-supplied key
/// (SSE-C) — it only works if [additionalHeaders] are replayed verbatim on the
/// follow-up `GET` to that URL, and expires quickly (observed ~10 minutes). See
/// `request_attachment_storage_url.dart`.
@freezed
abstract class AttachmentStorageUrl with _$AttachmentStorageUrl {
  @JsonSerializable(explicitToJson: true)
  const factory AttachmentStorageUrl({
    required List<AdditionalHeader> additionalHeaders,
    required String downloadUrl,
  }) = _AttachmentStorageUrl;

  factory AttachmentStorageUrl.fromJson(Map<String, dynamic> json) => _$AttachmentStorageUrlFromJson(json);
}
