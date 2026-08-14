import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/utils.dart';

part 'timetable_period.freezed.dart';
part 'timetable_period.g.dart';

typedef TimeTableDay = List<TimeTablePeriod>;
typedef TimeTableWeek = Map<Date, TimeTableDay>;

@freezed
abstract class TimeTablePeriod with _$TimeTablePeriod {
  @JsonSerializable(explicitToJson: true)
  const factory TimeTablePeriod(
    int id,
    int lessonId,
    @JsonKey(name: 'startDateTime') DateTime startTime,
    @JsonKey(name: 'endDateTime') DateTime endTime,
    @protected @JsonKey(name: 'text') InternalPeriodText internalPeriodText,
    @protected List<TimeTablePeriodElement> elements,
    @JsonKey(name: 'is') List<TimeTablePeriodStatus> periodStatus,
    TimeTableExamInformation? examInformation,
  ) = _TimeTablePeriod;

  const TimeTablePeriod._();

  String get lessonText => internalPeriodText.lesson;

  String get substitutionText => internalPeriodText.substitution;

  String get infoText => internalPeriodText.info;

  ClazzId? get clazz => elements.firstWhereOrNull(
        (element) => element is ClazzId,
      ) as ClazzId?;

  TeacherId? get teacher => elements.firstWhereOrNull(
        (element) => element is TeacherId,
      ) as TeacherId?;

  SubjectId? get subject => elements.firstWhereOrNull(
        (element) => element is SubjectId,
      ) as SubjectId?;

  RoomId? get room => elements.firstWhereOrNull(
        (element) => element is RoomId,
      ) as RoomId?;

  factory TimeTablePeriod.fromJson(Map<String, dynamic> json) =>
      _$TimeTablePeriodFromJson(json);

  bool collidesWith(TimeTablePeriod period) {
    return startTime.isBefore(period.endTime) &&
        endTime.isAfter(period.startTime);
  }
}
