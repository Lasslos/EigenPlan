import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:your_schedule/core/untis.dart';

part 'specified_message.freezed.dart';
part 'specified_message.g.dart';

@freezed
abstract class SpecifiedMessage with _$SpecifiedMessage {
  @JsonSerializable(explicitToJson: true)
  const factory SpecifiedMessage({
    required int id,
    required String subject,
    required MessageSender sender,
    required DateTime sentDateTime,
    required bool allowMessageDeletion,
    required bool isReply,
    required bool isReplyAllowed,
    required bool isReportMessage,
    required bool isReplyForbidden,
    @Default([]) List<ExternalAttachment> attachments,
    @Default([]) List<StorageAttachment> storageAttachments,
    @Default([]) List<ReplyHistoryEntry> replyHistory,
    Map<String, dynamic>? blobAttachment,
    Map<String, dynamic>? requestConfirmation,
    // Null for attachment-only messages with no text body (confirmed live: a
    // `schuldorf` message with attachments and no other content).
    String? content,
  }) = _SpecifiedMessage;

  factory SpecifiedMessage.fromJson(Map<String, dynamic> json) =>
      _$SpecifiedMessageFromJson(json);
}

/// One earlier message in a reply thread, as nested under `SpecifiedMessage.replyHistory`
/// when the current message `isReply`. Confirmed populated (2026-08 live probe,
/// `wolfsburger-oberschule` TEACHER account, on a message that had actually been
/// replied to) — earlier captures only had accounts with no reply threads, which is
/// why this was previously documented as always empty. Shaped like `SpecifiedMessage`
/// itself, minus `allowMessageDeletion`/`isReply*`/`isReportMessage`/`requestConfirmation`,
/// plus `recipients`/`isRevoked` which the top-level message doesn't have.
@freezed
abstract class ReplyHistoryEntry with _$ReplyHistoryEntry {
  const factory ReplyHistoryEntry({
    required int id,
    required String subject,
    required MessageSender sender,
    // Confirmed live (2026-08, same probe): same shape as `MessageSender`, not the
    // previously-unconfirmed generic item type.
    required List<MessageSender> recipients,
    required DateTime sentDateTime,
    required bool isRevoked,
    @Default([]) List<ExternalAttachment> attachments,
    @Default([]) List<StorageAttachment> storageAttachments,
    Map<String, dynamic>? blobAttachment,
    String? content,
  }) = _ReplyHistoryEntry;

  factory ReplyHistoryEntry.fromJson(Map<String, dynamic> json) =>
      _$ReplyHistoryEntryFromJson(json);
}
