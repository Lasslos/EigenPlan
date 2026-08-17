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

For each account: school search, login, `getUserData2017`, `mobile/data`, the messages list *and
the detail of every single message returned*, timetable entries for the surrounding few weeks, and
exams — each response is diffed against its model for unrecognized fields, and any exception during
the whole flow is caught and reported per-section rather than aborting the run, so one broken
endpoint doesn't hide problems elsewhere.

These tests assert on structure only — counts, key names, types — never on the content of your
actual school data, and never print or log a raw response body. If a test fails, the failure
message lists dotted key paths (e.g. `sender.newField`) or exception text, never message content or
credentials.
