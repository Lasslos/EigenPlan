import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:your_schedule/core/untis.dart';

part 'specified_message.freezed.dart';
part 'specified_message.g.dart';

@freezed
abstract class SpecifiedMessage with _$SpecifiedMessage {
  const factory SpecifiedMessage({
    required int id,
    required String subject,
    required String content,
    required MessageSender sender,
    required DateTime sentDateTime,
    required bool allowMessageDeletion,
    required bool isReply,
    required bool isReplyAllowed,
    required bool isReportMessage,
    required bool isReplyForbidden,
    required List<Map<String, dynamic>> attachments,
    required List<Map<String, dynamic>> storageAttachments,
    required List<Map<String, dynamic>> replyHistory,
    Map<String, dynamic>? blobAttachment,
    Map<String, dynamic>? requestConfirmation,
  }) = _SpecifiedMessage;

  factory SpecifiedMessage.fromJson(Map<String, dynamic> json) =>
      _$SpecifiedMessageFromJson(json);
}
