import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:your_schedule/utils.dart';

part 'time_grid_entry.freezed.dart';
part 'time_grid_entry.g.dart';

@freezed
abstract class TimeGridEntry with _$TimeGridEntry {
  const factory TimeGridEntry(
    String label,
    @TimeOfDaySerializer() TimeOfDay startTime,
    @TimeOfDaySerializer() TimeOfDay endTime,
  ) = _TimeGridEntry;

  const TimeGridEntry._();

  factory TimeGridEntry.fromJson(Map<String, dynamic> json) =>
      _$TimeGridEntryFromJson(json);

  Duration get length => Duration(
        minutes: (endTime.hour * 60 + endTime.minute) -
            (startTime.hour * 60 + startTime.minute),
      );
}

extension TimeGridMedian on List<TimeGridEntry> {
  /// The period whose [TimeGridEntry.length] is the median across the whole time grid —
  /// deliberately the median and not the mean, so that a single outlier block (e.g. one
  /// long afternoon double period) can't skew the height every other period is scaled
  /// against. Throws on an empty grid, like the `first`/`last` accesses that surround
  /// every call site.
  TimeGridEntry get medianPeriod =>
      (toList()..sort((a, b) => a.length.compareTo(b.length)))[length ~/ 2];

  Duration get medianPeriodLength => medianPeriod.length;
}
