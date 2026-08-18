import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:your_schedule/core/untis.dart';

part 'timetable_resource_ref.freezed.dart';
part 'timetable_resource_ref.g.dart';

/// Which resource's timetable to request — the client-side counterpart of
/// `timetable/entries`'s `resourceType`+`resources` params (see
/// `docs/api/spec/NOTES.md` §4b). [TimetableResourceRef.own] represents "my own
/// timetable" as a concrete value instead of a null/magic default, so
/// `RequestTimetableEntries` never has to special-case "no resource picked".
@freezed
abstract class TimetableResourceRef with _$TimetableResourceRef {
  const factory TimetableResourceRef({
    required String resourceType,
    required int resourceId,
    String? displayName,
  }) = _TimetableResourceRef;

  factory TimetableResourceRef.fromJson(Map<String, dynamic> json) =>
      _$TimetableResourceRefFromJson(json);

  const TimetableResourceRef._();

  /// Stable key for maps keyed by "which timetable" — e.g. the per-resource
  /// visibility map in `filters.dart`. Deliberately excludes [displayName], which is
  /// display-only and can legitimately differ between two refs to the same resource.
  String get storageKey => '$resourceType:$resourceId';

  /// The session owner's own resource — `null` if `userData.type`/`.id` are
  /// themselves null (an account with no timetable resource on file, e.g. some
  /// anonymous accounts — see `RequestTimetableEntries`'s existing guard).
  static TimetableResourceRef? own(ActiveUntisSession session) {
    final type = session.userData.type;
    final id = session.userData.id;
    if (type == null) {
      return null;
    }
    return TimetableResourceRef(
      resourceType: type,
      resourceId: id,
      displayName: session.userData.displayName,
    );
  }
}
