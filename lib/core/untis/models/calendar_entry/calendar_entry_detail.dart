import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendar_entry_detail.freezed.dart';
part 'calendar_entry_detail.g.dart';

/// One `calendar-entry/detail` homework entry — confirmed populated on the live server
/// (2026-08 probe) despite `docs/api/spec/NOTES.md` previously documenting it as
/// always-empty; that just reflected test accounts with no homework due at capture
/// time. Field names (`dateTime`/`dueDateTime`) intentionally differ from
/// `HomeworkItem`'s (`startDate`/`endDate`) — same kind of record, different shape,
/// do not assume interchangeable. `attachments`' item shape is still UNKNOWN.
@freezed
abstract class CalendarEntryHomework with _$CalendarEntryHomework {
  const factory CalendarEntryHomework({
    required int id,
    required String text,
    required bool completed,
    required DateTime dateTime,
    required DateTime dueDateTime,
    String? remark,
    @Default(<dynamic>[]) List<dynamic> attachments,
  }) = _CalendarEntryHomework;

  factory CalendarEntryHomework.fromJson(Map<String, dynamic> json) => _$CalendarEntryHomeworkFromJson(json);
}

@freezed
abstract class CalendarIntegrationLink with _$CalendarIntegrationLink {
  const factory CalendarIntegrationLink({
    required int id,
    required String name,
    required String url,
    required String type,
    required bool hideBrowserControls,
    required bool reloadDetailsOnResume,
    String? iconName,
    String? appId,
  }) = _CalendarIntegrationLink;

  factory CalendarIntegrationLink.fromJson(Map<String, dynamic> json) => _$CalendarIntegrationLinkFromJson(json);
}

/// The "tap a period" drill-down detail for one calendar entry. Deliberately models
/// only the fields not already available from the `GridEntry` the user tapped
/// (subject/room/teacher/klasses/status/type/times are all already shown from the
/// grid entry itself — re-modeling them here would just be duplicate data). Because
/// of that, this model does **not** aim for full round-trip parity with the raw
/// response — see the model test for why no `findUnparsedKeys` assertion is used here.
@freezed
abstract class CalendarEntryDetail with _$CalendarEntryDetail {
  @JsonSerializable(explicitToJson: true)
  const factory CalendarEntryDetail({
    required int id,
    String? notesAll,
    String? notesStaff,
    String? substText,
    @Default(<CalendarEntryHomework>[]) List<CalendarEntryHomework> homeworks,
    @JsonKey(includeToJson: false) Map<String, dynamic>? exam,
    @Default(<CalendarIntegrationLink>[]) List<CalendarIntegrationLink> integrationsSection,
  }) = _CalendarEntryDetail;

  factory CalendarEntryDetail.fromJson(Map<String, dynamic> json) => _$CalendarEntryDetailFromJson(json);
}

@freezed
abstract class CalendarEntryDetailResponse with _$CalendarEntryDetailResponse {
  @JsonSerializable(explicitToJson: true)
  const factory CalendarEntryDetailResponse({
    @Default(<CalendarEntryDetail>[]) List<CalendarEntryDetail> calendarEntries,
  }) = _CalendarEntryDetailResponse;

  factory CalendarEntryDetailResponse.fromJson(Map<String, dynamic> json) => _$CalendarEntryDetailResponseFromJson(json);
}
