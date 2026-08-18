import 'package:freezed_annotation/freezed_annotation.dart';

part 'homework.freezed.dart';
part 'homework.g.dart';

@freezed
abstract class HomeworkLesson with _$HomeworkLesson {
  const factory HomeworkLesson({
    required int id,
    required int subjectId,
    required List<int> klassenIds,
    required List<int> teacherIds,
  }) = _HomeworkLesson;

  factory HomeworkLesson.fromJson(Map<String, dynamic> json) =>
      _$HomeworkLessonFromJson(json);
}

/// One `getHomeWork2017` homework entry. `completed` is read-only — no write endpoint is
/// documented to toggle it. `attachments`' item shape is UNKNOWN (never observed non-empty
/// in any capture, see docs/api/spec/NOTES.md).
@freezed
abstract class HomeworkItem with _$HomeworkItem {
  const factory HomeworkItem({
    required int id,
    required int lessonId,
    required DateTime startDate,
    required DateTime endDate,
    required String text,
    required bool completed,
    String? remark,
    @Default(<dynamic>[]) List<dynamic> attachments,
  }) = _HomeworkItem;

  factory HomeworkItem.fromJson(Map<String, dynamic> json) =>
      _$HomeworkItemFromJson(json);
}

/// `lessonsById` is a JSON object keyed by lesson id as a string, which `json_serializable`
/// can't generate a `Map<int, X>` converter for automatically — hand-written `fromJson`/`toJson`,
/// same pattern as `UserData`.
@Freezed(fromJson: false, toJson: false)
abstract class Homework with _$Homework {
  const factory Homework(
    List<HomeworkItem> homeWorks,
    Map<int, HomeworkLesson> lessonsById,
  ) = _Homework;

  const Homework._();

  factory Homework.fromJson(Map<String, dynamic> json) => Homework(
    (json['homeWorks'] as List<dynamic>)
        .map((e) => HomeworkItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    {
      for (var e in (json['lessonsById'] as Map<String, dynamic>).entries)
        int.parse(e.key): HomeworkLesson.fromJson(
          e.value as Map<String, dynamic>,
        ),
    },
  );

  Map<String, dynamic> toJson() {
    return {
      'homeWorks': homeWorks.map((e) => e.toJson()).toList(),
      'lessonsById': {
        for (var e in lessonsById.entries) e.key.toString(): e.value.toJson(),
      },
    };
  }
}
