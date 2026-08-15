import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:your_schedule/core/untis/models/timetable/grid_entry.dart';
import 'package:your_schedule/util/date.dart';

part 'timetable_entries_response.freezed.dart';
part 'timetable_entries_response.g.dart';

/// A resource's timetable, keyed by day. `TimetableDay.status` distinguishes "no
/// data because outside the school year" (`NOT_ALLOWED`)/"no data for this date"
/// (`NO_DATA`) from a day that's genuinely empty of periods (`REGULAR` with empty
/// `gridEntries`) — check it before treating an empty day as "nothing scheduled".
typedef TimeTableWeek = Map<Date, TimetableDay>;

@freezed
abstract class TimetableResource with _$TimetableResource {
  const factory TimetableResource({
    required int id,
    String? shortName,
    String? longName,
    String? displayName,
  }) = _TimetableResource;

  factory TimetableResource.fromJson(Map<String, dynamic> json) => _$TimetableResourceFromJson(json);
}

/// One resource's (class/student/teacher) timetable for one day.
///
/// `status` (a plain `String`, not a closed enum — see `grid_entry.dart` for why):
/// observed `REGULAR`, `NOT_ALLOWED` (dates outside the school's active school-year
/// range), `NO_DATA`.
@freezed
abstract class TimetableDay with _$TimetableDay {
  @JsonSerializable(explicitToJson: true)
  const factory TimetableDay({
    required DateTime date,
    required String resourceType,
    required TimetableResource resource,
    required String status,
    @Default([]) List<GridEntry> gridEntries,
  }) = _TimetableDay;

  factory TimetableDay.fromJson(Map<String, dynamic> json) => _$TimetableDayFromJson(json);
}

@freezed
abstract class TimetableEntriesResponse with _$TimetableEntriesResponse {
  @JsonSerializable(explicitToJson: true)
  const factory TimetableEntriesResponse({
    required int format,
    @Default([]) List<TimetableDay> days,
  }) = _TimetableEntriesResponse;

  factory TimetableEntriesResponse.fromJson(Map<String, dynamic> json) => _$TimetableEntriesResponseFromJson(json);
}
