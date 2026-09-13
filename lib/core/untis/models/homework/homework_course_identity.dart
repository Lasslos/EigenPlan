import 'package:your_schedule/core/untis/models/homework/homework.dart';
import 'package:your_schedule/core/untis/models/user_data/user_data.dart';

/// Derives the [HomeworkLesson] equivalent of `GridEntryCourseIdentity.courseKey`, so
/// homework can be checked against the same per-course visibility overrides
/// (`filtersProvider`) the timetable already uses. Unlike a [GridEntry], which is one
/// concrete period instance with a single differentiator, a [HomeworkLesson] only
/// carries the lesson's *ids* (`subjectId`, `klassenIds`, `teacherIds`) and can span
/// several teachers/classes — so there's no single correct key, only candidates.
extension HomeworkLessonCourseIdentity on HomeworkLesson {
  /// Every `courseKey` this lesson could plausibly map to on some timetable resource.
  /// Empty when the subject itself is unknown — callers should treat that as
  /// "unfilterable, default to visible", same as `GridEntryCourseIdentity.courseKey ==
  /// null`. An unknown teacher/class id falls back to an empty differentiator rather
  /// than being dropped, so a stale/missing master-data entry never silently hides
  /// homework.
  Set<String> courseKeys(UserData userData) {
    final subject = userData.subjects[subjectId]?.name;
    if (subject == null) {
      return const {};
    }
    if (teacherIds.isNotEmpty) {
      return {
        for (final id in teacherIds) '$subject|${userData.teachers[id]?.shortName ?? ''}',
      };
    }
    if (klassenIds.isNotEmpty) {
      return {
        for (final id in klassenIds) '$subject|${userData.klassen[id]?.name ?? ''}',
      };
    }
    return {'$subject|'};
  }
}
