import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'messages.freezed.dart';
part 'messages.g.dart';

@freezed
abstract class MessageSender with _$MessageSender {
  const factory MessageSender({
    required String displayName,
    required int userId,
    String? className,
    String? imageUrl,
  }) = _MessageSender;

  factory MessageSender.fromJson(Map<String, dynamic> json) =>
      _$MessageSenderFromJson(json);
}

@freezed
abstract class IncomingMessage with _$IncomingMessage {
  const factory IncomingMessage({
    required int id,
    required String subject,
    required String contentPreview,
    required MessageSender sender,
    required DateTime sentDateTime,
    required bool allowMessageDeletion,
    required bool hasAttachments,
    required bool isMessageRead,
    required bool isReply,
    required bool isReplyAllowed,
  }) = _IncomingMessage;

  factory IncomingMessage.fromJson(Map<String, dynamic> json) =>
      _$IncomingMessageFromJson(json);
}

@freezed
abstract class Messages with _$Messages {
  const factory Messages({
    required List<IncomingMessage> incomingMessages,
    required List<Map<String, dynamic>> readConfirmationMessages,
  }) = _Messages;

  factory Messages.fromJson(Map<String, dynamic> json) =>
      _$MessagesFromJson(json);
}
