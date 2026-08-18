import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:your_schedule/core/untis.dart';

part 'timetable_menu.freezed.dart';
part 'timetable_menu.g.dart';

/// One entry of `GET /timetable/menu` — `type` is a plain [String] (a
/// [ResourceType]-like value: observed `CLASS`/`STUDENT`/`TEACHER`/`ROOM`), not a
/// closed Dart enum, matching `GridEntry`'s convention (see its doc comment) so an
/// unrecognized value from the server doesn't crash the picker.
@freezed
abstract class TimetableMenuEntry with _$TimetableMenuEntry {
  @JsonSerializable(explicitToJson: true)
  const factory TimetableMenuEntry({
    required String type,
    required TimetableResource resource,
    String? imageUrl,
  }) = _TimetableMenuEntry;

  factory TimetableMenuEntry.fromJson(Map<String, dynamic> json) => _$TimetableMenuEntryFromJson(json);
}

/// `GET /timetable/menu` — the "switch timetable" picker's first call: the caller's
/// own resource, any dependents (e.g. a parent account's children), and which
/// resource types (`availableTimetables`) the account is allowed to browse via
/// `timetable/filter`. See `docs/api/spec/NOTES.md` §4b and
/// `docs/api/captures/home/timetable_menu.md`.
@freezed
abstract class TimetableMenuResponse with _$TimetableMenuResponse {
  @JsonSerializable(explicitToJson: true)
  const factory TimetableMenuResponse({
    required TimetableMenuEntry myTimetable,
    @Default([]) List<TimetableMenuEntry> dependents,
    @Default([]) List<String> availableTimetables,
  }) = _TimetableMenuResponse;

  factory TimetableMenuResponse.fromJson(Map<String, dynamic> json) => _$TimetableMenuResponseFromJson(json);
}
