import 'package:your_schedule/core/untis.dart';

/// [homework] with hidden courses filtered out, per [overrides] (the Filter screen's
/// per-course visibility map — same `overrides[courseKey] ?? true` rule
/// `schedule_status.dart`/`week_view.dart`/`day_view.dart` use for the timetable). A
/// [HomeworkItem] can map to several candidate `courseKey`s (see
/// [HomeworkLessonCourseIdentity.courseKeys]) since its lesson may span multiple
/// teachers/classes — it's kept if ANY candidate is visible, only dropped once every
/// candidate is explicitly hidden. Items whose lesson is missing from [homework]'s
/// `lessonsById`, or whose subject is unknown, are always kept (unfilterable).
Homework filterHomeworkByVisibility(
  Homework homework,
  UserData userData,
  Map<String, bool> overrides,
) {
  if (overrides.isEmpty) {
    return homework;
  }

  bool isVisible(HomeworkItem item) {
    final lesson = homework.lessonsById[item.lessonId];
    if (lesson == null) {
      return true;
    }
    final keys = lesson.courseKeys(userData);
    if (keys.isEmpty) {
      return true;
    }
    return keys.any((key) => overrides[key] ?? true);
  }

  return Homework(homework.homeWorks.where(isVisible).toList(), homework.lessonsById);
}
