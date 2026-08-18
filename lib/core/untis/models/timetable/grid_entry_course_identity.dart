import 'package:your_schedule/core/untis/models/timetable/grid_entry.dart';

/// Derives a stable-enough course identity directly from a [GridEntry]'s own content —
/// no numeric course id exists anywhere the app can fetch in bulk (see
/// `docs/api/spec/NOTES.md`; the true per-lesson id, `calendar-entry/detail`'s
/// `lesson.lessonId`, requires one request per period and isn't worth that cost here).
/// Keyed by the subject plus whichever secondary slot actually distinguishes concurrent
/// courses of the same subject: teacher normally, class when viewing a `TEACHER`
/// resource's own timetable (the same fallback `grid_entry_widget.dart` already uses for
/// display).
extension GridEntryCourseIdentity on GridEntry {
  /// Null when there's no subject slot at all (e.g. a non-teaching `EVENT`) — callers
  /// should treat that as "unfilterable, use a default color", not as an error.
  String? get courseKey {
    final subject = positionOfType('SUBJECT')?.current?.shortName;
    if (subject == null) {
      return null;
    }
    final differentiator =
        positionOfType('TEACHER')?.current?.shortName ?? positionOfType('CLASS')?.current?.shortName ?? '';
    return '$subject|$differentiator';
  }
}
