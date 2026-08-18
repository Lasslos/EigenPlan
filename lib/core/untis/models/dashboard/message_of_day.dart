import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_of_day.freezed.dart';
part 'message_of_day.g.dart';

/// An externally-hosted attachment on a [MessageOfDay] — always a directly-usable
/// link (e.g. a SharePoint URL), no signed-URL dance needed. `id` is observed as the
/// literal `-1` on every attachment — likely means "no real numeric id, externally
/// hosted" rather than a meaningful identifier (same convention as the REST
/// `/messages` family's `ExternalAttachment`, just JSON-RPC's own shape for it).
@freezed
abstract class MessageOfDayAttachment with _$MessageOfDayAttachment {
  const factory MessageOfDayAttachment({
    required int id,
    required String name,
    required String url,
  }) = _MessageOfDayAttachment;

  factory MessageOfDayAttachment.fromJson(Map<String, dynamic> json) =>
      _$MessageOfDayAttachmentFromJson(json);
}

/// One `getMessagesOfDay2017` entry — the older JSON-RPC "message of the day" list,
/// distinct from the REST `/messages` inbox family (see `docs/api/captures/startup/
/// XX_getMessagesOfDay2017.md`). Its only current consumer is enriching
/// [AnnouncementsCard]'s dashboard cards with real attachment links: the REST
/// `/dashboard/cards` endpoint only exposes `hasAttachments: bool`, not the actual
/// attachment name/url — this endpoint, keyed by the same `id`, carries those.
@freezed
abstract class MessageOfDay with _$MessageOfDay {
  const factory MessageOfDay({
    required int id,
    required String subject,
    required String body,
    @Default([]) List<MessageOfDayAttachment> attachments,
  }) = _MessageOfDay;

  factory MessageOfDay.fromJson(Map<String, dynamic> json) => _$MessageOfDayFromJson(json);
}
