import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:your_schedule/core/untis.dart';

part 'timetable_filter_response.freezed.dart';
part 'timetable_filter_response.g.dart';

@freezed
abstract class TimetableFilterClassEntry with _$TimetableFilterClassEntry {
  @JsonSerializable(explicitToJson: true)
  const factory TimetableFilterClassEntry({
    @JsonKey(name: 'class') required TimetableResource classResource,
    /// `null` observed live for some classes on the full (unfiltered) class list —
    /// not every class has a department assigned, despite every class in the small
    /// sample first captured (`docs/api/captures/home/timetable_filter.md`) having one.
    TimetableResource? department,
    TimetableResource? classTeacher1,
    TimetableResource? classTeacher2,
  }) = _TimetableFilterClassEntry;

  factory TimetableFilterClassEntry.fromJson(Map<String, dynamic> json) =>
      _$TimetableFilterClassEntryFromJson(json);
}

@freezed
abstract class TimetableFilterTeacherEntry with _$TimetableFilterTeacherEntry {
  @JsonSerializable(explicitToJson: true)
  const factory TimetableFilterTeacherEntry({
    required TimetableResource teacher,
    @Default([]) List<TimetableResource> departments,
    String? imageUrl,
  }) = _TimetableFilterTeacherEntry;

  factory TimetableFilterTeacherEntry.fromJson(Map<String, dynamic> json) =>
      _$TimetableFilterTeacherEntryFromJson(json);
}

@freezed
abstract class TimetableFilterRoomEntry with _$TimetableFilterRoomEntry {
  @JsonSerializable(explicitToJson: true)
  const factory TimetableFilterRoomEntry({
    required TimetableResource room,
    required int capacity,
    TimetableResource? building,
    TimetableResource? department,
  }) = _TimetableFilterRoomEntry;

  factory TimetableFilterRoomEntry.fromJson(Map<String, dynamic> json) => _$TimetableFilterRoomEntryFromJson(json);
}

@freezed
abstract class TimetableFilterStudentClassMembership with _$TimetableFilterStudentClassMembership {
  @JsonSerializable(explicitToJson: true)
  const factory TimetableFilterStudentClassMembership({
    @JsonKey(name: 'class') required TimetableResource classResource,
    required SchoolYearRange dateRange,
    TimetableResource? department,
  }) = _TimetableFilterStudentClassMembership;

  factory TimetableFilterStudentClassMembership.fromJson(Map<String, dynamic> json) =>
      _$TimetableFilterStudentClassMembershipFromJson(json);
}

@freezed
abstract class TimetableFilterStudentEntry with _$TimetableFilterStudentEntry {
  @JsonSerializable(explicitToJson: true)
  const factory TimetableFilterStudentEntry({
    required TimetableResource student,
    @Default([]) List<TimetableFilterStudentClassMembership> classes,
    String? imageUrl,
  }) = _TimetableFilterStudentEntry;

  factory TimetableFilterStudentEntry.fromJson(Map<String, dynamic> json) =>
      _$TimetableFilterStudentEntryFromJson(json);
}

/// `GET /timetable/filter?resourceType=X` — the "switch timetable" picker's
/// search-directory call. One unified shape regardless of the requested
/// `resourceType`; only the array matching the requested type is populated (see
/// `docs/api/spec/openapi.yaml`'s `TimetableFilterResponse` and
/// `docs/api/captures/home/timetable_filter.md`). Deliberately partial: several
/// top-level fields (`buildings`/`departments`/`roomGroups`/`resourceTypes`/
/// `assignmentGroups`/`resources`/`subjects`) were empty in every capture so far
/// with **UNKNOWN** item shape and aren't modeled here — see the doc comment on
/// those fields in `openapi.yaml` before adding them.
@freezed
abstract class TimetableFilterResponse with _$TimetableFilterResponse {
  @JsonSerializable(explicitToJson: true)
  const factory TimetableFilterResponse({
    required String resourceType,
    TimetableResource? preSelected,
    @Default([]) List<TimetableFilterClassEntry> classes,
    @Default([]) List<TimetableFilterTeacherEntry> teachers,
    @Default([]) List<TimetableFilterRoomEntry> rooms,
    @Default([]) List<TimetableFilterStudentEntry> students,
  }) = _TimetableFilterResponse;

  factory TimetableFilterResponse.fromJson(Map<String, dynamic> json) => _$TimetableFilterResponseFromJson(json);
}
