import 'package:your_schedule/core/untis/models/timetable/grid_entry.dart';
import 'package:your_schedule/core/untis/models/user_data/subject.dart';

/// Resolves a [GridEntry]'s subject against `getUserData2017`'s master data, matched
/// by short name.
///
/// Unlike the legacy `getTimetable2017`, `GridEntryPositionElement` carries no
/// numeric id (see `docs/api/spec/NOTES.md`) — only `shortName`/`longName`/
/// `displayName`, which is enough to render text directly without any resolution.
/// Subject *id* is the one thing still needed from master data: custom colors and
/// subject filters are keyed by it (`customSubjectColorsProvider`, `filtersProvider`
/// — both predate this rewrite and there's no reason to migrate their storage key
/// just because the timetable transport changed). If no match is found (a genuinely
/// non-teaching entry, or a name that doesn't appear in master data), returns
/// `null` — callers should treat that as "unfilterable, use a default color", not as
/// an error.
extension GridEntryResolution on GridEntry {
  MapEntry<int, Subject>? resolveSubject(Map<int, Subject> subjects) {
    final shortName = positionOfType('SUBJECT')?.current.shortName;
    if (shortName == null) {
      return null;
    }
    for (final entry in subjects.entries) {
      if (entry.value.name == shortName) {
        return entry;
      }
    }
    return null;
  }
}
