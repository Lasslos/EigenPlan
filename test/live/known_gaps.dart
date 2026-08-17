/// Known-unmodeled API fields, one set per endpoint, checked against the *live*
/// API's actual responses (see `api_coverage_live_test.dart`). Paths are normalized
/// via `normalizeKeyPath` (array indices collapsed to `[]`), so these stay a fixed
/// size regardless of how many klassen/rooms/subjects/etc. a given school has.
///
/// This list exists so the live-coverage test can tell "field we've never modeled,
/// already known about" apart from "field that showed up today for the first
/// time" — only the latter should ever fail a run. Last verified against real
/// responses from all four credentialed schools on 2026-08-17 (see
/// docs/api/spec/NOTES.md for what each school represents). Adding something here
/// should come with a reason; removing something here (because a model started
/// capturing it) is a good sign, not a bug.
library;

/// `getUserData2017` — deliberately-partial by design (see
/// `lib/core/untis/models/user_data/user_data.dart`): only pulls the subset of
/// master data any screen currently needs.
const userDataKnownGaps = <String>{
  // Whole master-data categories never modeled at all.
  'masterData.absenceReasons',
  'masterData.departments',
  'masterData.duties',
  'masterData.eventReasons',
  'masterData.eventReasonGroups',
  'masterData.excuseStatuses',
  'masterData.teachingMethods',
  'masterData.schoolyears',
  // Per-item fields on klassen/rooms/subjects/teachers not modeled — color
  // theming and department scoping aren't used anywhere in the UI today.
  'masterData.klassen[].departmentId',
  'masterData.klassen[].foreColor',
  'masterData.klassen[].backColor',
  'masterData.rooms[].departmentId',
  'masterData.rooms[].foreColor',
  'masterData.rooms[].backColor',
  'masterData.rooms[].displayAllowed',
  'masterData.subjects[].departmentIds',
  'masterData.subjects[].foreColor',
  'masterData.subjects[].backColor',
  'masterData.subjects[].displayAllowed',
  'masterData.teachers[].departmentIds',
  'masterData.teachers[].foreColor',
  'masterData.teachers[].backColor',
  'masterData.teachers[].entryDate',
  'masterData.teachers[].exitDate',
  'masterData.teachers[].displayAllowed',
  // UserData.fromJson only reads the *first* timeGrid day's units (see its
  // doc comment) — every other day, and each day's own `day` label, is dropped.
  'masterData.timeGrid.days[].day',
  'masterData.timeGrid.days[].units',
  // userData block: only elemType/elemId/displayName/schoolName are read.
  'userData.departmentId',
  'userData.children',
  'userData.klassenIds',
  'userData.rights',
  // The whole `settings` block (absence-check defaults, calendar display prefs)
  // is unused by the app today.
  'settings',
};

/// `GET /timetable/entries` — see `lib/core/untis/models/timetable/grid_entry.dart`
/// and `timetable_entries_response.dart`.
const timetableEntriesKnownGaps = <String>{
  // Always empty in every capture so far; shape/purpose unconfirmed (see
  // docs/api/spec/NOTES.md §3).
  'days[].dayEntries',
  'days[].backEntries',
  // Observed on real gridEntries but not yet in GridEntry — `name` is
  // consistently null so far; the other four have never been captured non-null.
  'days[].gridEntries[].name',
  'days[].gridEntries[].userName',
  'days[].gridEntries[].moved',
  'days[].gridEntries[].durationTotal',
  'days[].gridEntries[].link',
  // A top-level `errors` field observed live, never in any doc capture — shape
  // unknown (was empty/absent-looking in every observed response so far).
  'errors',
};
