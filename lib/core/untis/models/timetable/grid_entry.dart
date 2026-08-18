import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'grid_entry.freezed.dart';
part 'grid_entry.g.dart';

/// `type`/`status` fields throughout this file are deliberately plain [String], not
/// closed Dart enums — the reverse-engineered spec (`docs/api/spec/openapi.yaml`)
/// only documents the values actually observed in captures, and a strict enum throws
/// on any value the server sends that we haven't seen yet (exactly the crash a strict
/// `LoginMode` enum caused for stored session data early in this rewrite — see
/// `storage_migration.dart`). A server sending an unrecognized status shouldn't take
/// the whole timetable down.
@freezed
abstract class GridEntryPositionElement with _$GridEntryPositionElement {
  const factory GridEntryPositionElement({
    required String type,
    required String status,
    String? shortName,
    String? longName,
    String? displayName,
    String? displayNameLabel,
  }) = _GridEntryPositionElement;

  factory GridEntryPositionElement.fromJson(Map<String, dynamic> json) => _$GridEntryPositionElementFromJson(json);
}

@freezed
abstract class GridEntryPositionItem with _$GridEntryPositionItem {
  const factory GridEntryPositionItem({
    /// Null when a substitution removed this position with nothing filling it back
    /// in — e.g. a lesson's teacher is absent with no covering teacher assigned.
    /// [removed] still carries the pre-substitution value in that case.
    GridEntryPositionElement? current,
    /// The pre-substitution value, when [current] is a substitution (room change,
    /// covering teacher, ...). Populated with `current`/`removed` both set and their
    /// respective `status` set to `ADDED`/`REMOVED`.
    GridEntryPositionElement? removed,
  }) = _GridEntryPositionItem;

  factory GridEntryPositionItem.fromJson(Map<String, dynamic> json) => _$GridEntryPositionItemFromJson(json);
}

@freezed
abstract class GridEntryText with _$GridEntryText {
  const factory GridEntryText({
    required String type,
    required String text,
  }) = _GridEntryText;

  factory GridEntryText.fromJson(Map<String, dynamic> json) => _$GridEntryTextFromJson(json);
}

@freezed
abstract class GridEntryDuration with _$GridEntryDuration {
  const factory GridEntryDuration({
    required DateTime start,
    required DateTime end,
  }) = _GridEntryDuration;

  factory GridEntryDuration.fromJson(Map<String, dynamic> json) => _$GridEntryDurationFromJson(json);
}

/// One rendered timetable cell (`GET /timetable/entries`). Supersedes the legacy
/// `getTimetable2017`'s flat `TimeTablePeriod` list.
///
/// The server also returns a suggested `layoutStartPosition`/`layoutWidth`/
/// `layoutGroup` (0-1000 fractions of the day column), deliberately not modeled here —
/// they assume every period the server knows about is being rendered, which breaks
/// down once the filter screen can hide individual courses. Layout is instead computed
/// client-side over whatever's actually visible; see `grid_entry_layout.dart` and
/// `docs/api/spec/NOTES.md` §4.
@freezed
abstract class GridEntry with _$GridEntry {
  @JsonSerializable(explicitToJson: true)
  const factory GridEntry({
    required GridEntryDuration duration,
    required String type,
    required String status,
    @Default([]) List<int> ids,
    String? statusDetail,
    /// Suggested default color only — never authoritative. It tracks period
    /// status/type more than a stable per-subject identity; the app's own
    /// `customSubjectColorsProvider` choice must always win once a user has picked one.
    String? color,
    String? notesAll,
    @Default([]) List<String> icons,
    List<GridEntryPositionItem>? position1,
    List<GridEntryPositionItem>? position2,
    List<GridEntryPositionItem>? position3,
    List<GridEntryPositionItem>? position4,
    List<GridEntryPositionItem>? position5,
    List<GridEntryPositionItem>? position6,
    List<GridEntryPositionItem>? position7,
    @Default([]) List<GridEntryText> texts,
    String? lessonText,
    String? lessonInfo,
    String? substitutionText,
  }) = _GridEntry;

  const GridEntry._();

  factory GridEntry.fromJson(Map<String, dynamic> json) => _$GridEntryFromJson(json);

  List<List<GridEntryPositionItem>?> get positionSlots =>
      [position1, position2, position3, position4, position5, position6, position7];

  /// The first position slot whose *current* element has the given [type] (e.g.
  /// `SUBJECT`, `TEACHER`, `ROOM`, `CLASS`, `INFO`). Position-slot ordering is
  /// resource-type-dependent (see the schema notes in `openapi.yaml`), so entries are
  /// matched by their own `type` field rather than by a fixed position index.
  GridEntryPositionItem? positionOfType(String type) {
    for (final slot in positionSlots) {
      if (slot == null) {
        continue;
      }
      for (final item in slot) {
        if (item.current?.type == type) {
          return item;
        }
      }
    }
    return null;
  }

  /// All position items of the given [type] in this entry — plural because a single
  /// slot can hold more than one value (e.g. two co-teachers on a joint event).
  List<GridEntryPositionItem> allPositionsOfType(String type) => [
        for (final slot in positionSlots)
          if (slot != null) for (final item in slot) if (item.current?.type == type) item,
      ];

  bool get isCancelled => status == 'CANCELLED';
  bool get isChanged => status == 'CHANGED';
  bool get isExam => type == 'EXAM';

  /// True if any position slot in this entry represents a substitution (room change,
  /// covering teacher, ...) — i.e. has a non-null `removed` value.
  bool get hasSubstitution => positionSlots.any((slot) => slot?.any((item) => item.removed != null) ?? false);
}
