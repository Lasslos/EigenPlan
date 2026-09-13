import 'package:your_schedule/core/untis/models/exams/exam.dart';
import 'package:your_schedule/core/untis/models/user_data/user_data.dart';

/// The [Exam] equivalent of `HomeworkLessonCourseIdentity.courseKeys` — same rationale
/// and shape (see `homework_course_identity.dart`), applied to an [Exam] directly since
/// it already carries `subjectId`/`teacherIds`/`klasseIds` itself, with no separate
/// "lesson" indirection to go through.
extension ExamCourseIdentity on Exam {
  /// Every `courseKey` this exam could plausibly map to on some timetable resource.
  /// Empty when the subject itself is unknown — callers should treat that as
  /// "unfilterable/uncolorable, use the default", same as
  /// `GridEntryCourseIdentity.courseKey == null`.
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
    if (klasseIds.isNotEmpty) {
      return {
        for (final id in klasseIds) '$subject|${userData.klassen[id]?.name ?? ''}',
      };
    }
    return {'$subject|'};
  }
}
