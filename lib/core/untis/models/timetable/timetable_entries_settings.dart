import 'package:freezed_annotation/freezed_annotation.dart';

part 'timetable_entries_settings.freezed.dart';
part 'timetable_entries_settings.g.dart';

/// `GET /timetable/entries/settings` — per-resourceType display overlay toggles for
/// the timetable UI. All fields boolean; see `docs/api/spec/openapi.yaml`'s
/// `TimetableEntriesSettings` schema.
@freezed
abstract class TimetableEntriesSettings with _$TimetableEntriesSettings {
  const factory TimetableEntriesSettings({
    required bool showSymbols,
    required bool showTeacherAbsences,
    required bool showStudentAbsences,
    required bool showRoomLocks,
    required bool showResourceLocks,
    required bool showForeignSubstitutions,
    required bool showICal,
    required bool showICalExport,
    required bool showAllDropdownElements,
    required bool highlightChanges,
    required bool highlightExams,
    required bool highlightCancellations,
    required bool highlightExternalEntries,
  }) = _TimetableEntriesSettings;

  factory TimetableEntriesSettings.fromJson(Map<String, dynamic> json) =>
      _$TimetableEntriesSettingsFromJson(json);
}
