# Live API coverage tests (tier 4b)

These tests hit the **real** Untis API with **real school credentials**. They exist to answer a
question fixtures can't: does everything the live server sends today actually parse, and is there
API surface we don't model at all yet?

They call the same production `request*` functions/providers the app uses — nothing is
reimplemented — and diff every raw response against the resulting model to flag any field the
server sent that no `fromJson` picks up.

**Local-only, always.** These tests are never run in CI. They *do* run as part of the Claude Code
Stop hook's `full` verification level (see `CLAUDE.md`) — but that hook only ever executes on your
own machine, and without `test/live/credentials.local.json` present these tests just run a trivial
placeholder and pass instantly, so it's safe to leave that as the default. `dart_test.yaml` tags
these tests `live` and skips that tag unless explicitly requested.

## Running

```shell
flutter test --tags=live --run-skipped
```

Both flags matter: `--tags=live` selects only these tests, and `--run-skipped` is required to
actually execute them — `dart_test.yaml` marks the `live` tag skip-by-default, and `--tags=live`
alone doesn't override that (you'd otherwise just get "All tests skipped").

## Providing credentials

Create `test/live/credentials.local.json` (gitignored — never commit this file) with one entry per
account, e.g.:

```json
[
  { "school": "cjd-koewi", "loginMode": "password", "username": "...", "password": "..." },
  { "school": "bs-gfv", "loginMode": "anonymous" },
  { "school": "schuldorf", "loginMode": "ssoKey", "username": "...", "key": "..." },
  { "school": "wolfsburger-oberschule", "loginMode": "password", "username": "...", "password": "..." }
]
```

- `school` is passed to the real school search (`searchSchool`) and matched by `loginName` — use
  the same value you'd type into the school picker.
- `loginMode` is one of `password`, `ssoKey`, `anonymous` (matches `LoginMode` in
  `lib/core/untis/untis_session.dart`).
- `password` mode needs `username` + `password`. `ssoKey` mode needs `username` + `key` (the
  app-shared-secret/login key itself — what you'd scan from a QR code or paste in by hand).
  `anonymous` mode needs neither.

All accounts in the list are exercised in one `flutter test --tags=live --run-skipped` run.

Alternatively, set the environment variable `UNTIS_LIVE_CREDENTIALS` to the same JSON (checked
first, useful for a quick one-off run without creating the file). If neither is present, the test
suite reports a clear skip instead of failing.

## What gets checked, and what doesn't

Every read-only endpoint in `docs/api/spec/openapi.yaml` is called at least once per account, and
"list" responses are chased into whatever "detail" endpoint they imply — not a fixed id/date chosen
up front, so this adapts to whatever each account actually has:

- School search, login-meta, login (`getUserData2017`), `mobile/data`, `profile/user-email`,
  `trigger/startup`, `statistics/usage-statistics-status`, `home`, `dashboard/cards(/status)`.
- Messages: the inbox list, then the detail of *every* message returned, then
  `attachmentstorageurl` *and the actual S3 download* for every storage-backed attachment on each of
  those; also `messages/status`, `messages/permissions`, and the legacy `getMessagesOfDay2017` for
  every day in the 3-week window below (not just today — a message-of-day is inherently per-date).
- Timetable: `timetable/menu`, `timetable/entries/settings`, `timetable/grid`, and entries for a
  3-week window (the current week plus one on each side).
- Exams (`getExams2017`) across that same 3-week window, homework (`getHomeWork2017`, its own
  ~75-day window), student absences (`getStudentAbsences2017`, not gated on having a
  timetable resource — its RPC params don't need one).
- `calendar-entry/detail` for *every distinct period* the 3 timetable weeks contain — deduplicated by
  `GridEntry.ids` (so a merged double-lesson isn't queried twice), not sampled or limited to periods
  flagged with a homework/notes icon — then `getPeriodData2017`, batched across every period id
  `calendar-entry/detail` actually returned.

Two endpoints are deliberately never called: `POST /api/register/` (real push-notification device
registration — a genuine write with a real side effect, and push is intentionally unimplemented, see
`CLAUDE.md`) and `PATCH /api/refresh-device-presence/{id}` (shape entirely uncaptured, needs a
registered device id from the endpoint above).

Responses are diffed against their model for unrecognized fields (`findUnparsedKeys`), and — the
check that actually caught a real doc bug once (`calendar-entry/detail`'s `homeworks[]`/`elementId`
semantics, 2026-08) — fields `openapi.yaml`/`NOTES.md` document as "always empty/null in captures"
are explicitly re-checked, and the run fails loudly if one of them turns out to be populated after
all (`isStillEmpty`/`checkStillEmpty` in `known_gaps.dart`/`api_coverage_live_test.dart`). A field's
presence-based diff alone can't catch that case: a loosely-typed or allow-listed field already
"consumes" its raw key regardless of whether the value is empty or real data. Any exception during
the whole flow is caught and reported per-section rather than aborting the run, so one broken
endpoint doesn't hide problems elsewhere.

These tests assert on structure only — counts, key names, types — never on the content of your
actual school data, and never print or log a raw response body. If a test fails, the failure
message lists dotted key paths (e.g. `sender.newField`), a "populated but documented as always
empty" field name, or exception text — never message content or credentials.
