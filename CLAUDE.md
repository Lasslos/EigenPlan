# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

EigenPlan (package name `your_schedule`) is a Flutter (Android-only; iOS/web/desktop are not configured) third-party
mobile client for the Untis school timetable system. It reverse-engineers the private Untis Mobile app's RPC API
(no official public API is used) to let users log in with their school credentials and view a filtered, color-customized
timetable, exams, homework, and messages.

## Current initiative: API/data-layer rewrite

This project received no active development for ~2 years (maintenance-only) and is now being refreshed. The
Untis Mobile backend has changed substantially since the existing `lib/core/untis/` implementation was
written — it now speaks a **hybrid** of the original JSON-RPC 2.0 API (`jsonrpc_intern.do`, still used
exclusively by the current code) and a newer REST-ish API under `/WebUntis/api/**` (bearer-JWT auth) that now
carries the richer/primary data for the home screen, messages, and above all the timetable, which has a
materially different shape than `getTimetable2017` ever returned.

A full reverse-engineered spec of the current API — covering all four credentialed schools (normal
password+SSO login, **anonymous login**, and **SSO/key-based login**), with explicit "UNKNOWN" markers for
anything that couldn't be confirmed from the captures — lives at `docs/api/spec/openapi.yaml` (schema
reference, Swagger-UI-renderable) and `docs/api/spec/NOTES.md` (prose: per-school login walkthroughs, open
questions, and a list of concrete concerns with the *current* implementation worth reconsidering during the
rewrite — e.g. credentials being persisted unencrypted via `SharedPreferences` despite an unused
`flutter_secure_storage` instance already in the codebase). **Nothing in the existing architecture described
below is settled for the rewrite** — patterns below reflect the pre-refresh implementation, not a mandate;
read `docs/api/spec/NOTES.md` §5 before assuming the current `UntisSession`/auth/model shapes should be
carried forward as-is, and flag anything else that looks like it should change rather than silently
preserving it.

## Commands

```shell
# Install dependencies
flutter pub get

# Regenerate generated code (freezed models, json_serializable, riverpod_generator)
# Required after changing any @freezed class, @riverpod provider, or *.g.dart-backed model
dart run build_runner build --delete-conflicting-outputs

# Watch mode while iterating on models/providers
dart run build_runner watch --delete-conflicting-outputs

# Static analysis / lint (uses flutter_lints + riverpod_lint, see analysis_options.yaml)
flutter analyze

# Run the app (Android device/emulator required)
flutter run

# Build a release APK
flutter build apk

# Offline tests (fixtures, no network/credentials)
flutter test

# Live API coverage tests — real credentials, local-only, never run this in CI;
# see test/live/README.md. Both flags matter: --run-skipped overrides
# dart_test.yaml's default skip for the 'live' tag.
flutter test --tags=live --run-skipped
```

## Verification

This repo has a four-tier verification pipeline (static analysis, codegen, build, tests — see
`README.md`'s "Verification" section for the full breakdown) enforced two ways: a GitHub Actions
workflow on every PR (tiers 1–3 + offline tests only — never the live-API tier), and a Claude Code
`Stop` hook (`.claude/hooks/verify-before-stop.sh`) that runs before you can finish a turn.

The hook runs at one of three speeds:

- **full** (default): codegen → analyze → offline tests → debug APK build (~30s total). Covers
  everything CI covers.
- **light**: codegen → analyze only. Use this for small, exploratory, or live-debugging turns where
  even a build isn't worth paying for — a single-file fix, iterating on one function, a quick config
  tweak. For anything that changes behavior more substantially — new models/providers/screens,
  anything touching the request/parsing layer, multi-file changes — leave it on the default `full`
  speed so the build and test suite actually run.
- **live**: everything in `full`, plus the tier-4b live-API coverage suite
  (`flutter test --tags=live --run-skipped`), which crawls a real school over the network (message
  attachments, multi-week timetable/exam/homework data) and dominates runtime (~110s on top of
  `full`'s ~30s) whenever `test/live/credentials.local.json` is configured — see
  `test/live/README.md`. Never run in CI, and not run by default in the hook either; opt in only
  when you've touched the request/parsing layer and want to confirm against the real API surface.

To opt into a non-default level for the *next* Stop only, run this before finishing:
```shell
mkdir -p .claude && echo light > .claude/.verify-level   # or: echo live > .claude/.verify-level
```
This is one-shot: the hook deletes the marker after reading it, so the following turn defaults back
to `full` unless you set it again. When in doubt, do nothing — `full` is the safe default.

## Architecture

### Layering

- `lib/core/untis/` — data layer: Untis API models (`models/`), raw HTTP requests (`requests/`), and locally
  persisted/cached copies of API responses (`cached/`). `lib/core/untis.dart` re-exports the whole layer as a single
  barrel import (`package:your_schedule/core/untis.dart`) — prefer importing from that barrel rather than deep paths.
- `lib/core/rpc_request/` — the generic JSON-RPC transport used to talk to a school's Untis server
  (`rpc_request.dart`/`rpc_response.dart`/`rpc_error.dart`), re-exported via `lib/core/rpc_request/rpc.dart`.
- `lib/core/provider/` — Riverpod providers that compose the data layer into app state (sessions, timetable, exams,
  messages, filters, connectivity).
- `lib/settings/` — user-facing app settings as Riverpod providers (theme, Sentry opt-in, view mode).
- `lib/ui/screens/` — one directory per screen, generally with a `widgets/` subfolder for screen-local widgets.
- `lib/util/` and `lib/utils.dart` — shared helpers (custom `Date`/`Week` value types, logging, secure storage,
  shared preferences wrapper).
- `lib/background/service.dart` — Workmanager background task entry point (currently inert; see "Not yet implemented"
  below).

### State management: Riverpod generator pattern

Nearly all state uses `riverpod_generator`/`freezed` codegen: a class extends a generated `_$Foo` base, has a `build()`
method, and lives next to a `part 'foo.g.dart';`. Never hand-write `.g.dart`/`.freezed.dart` files — edit the
annotated source and run `build_runner`.

The recurring "live vs. cached" pattern (see `timetable_provider.dart`, `request_timetable.dart`,
`cached/cached_timetable.dart`) is central to how offline support works:

1. A `request*` provider (`@Riverpod(keepAlive: true)`) performs the network call and, via `listenSelf`, writes
   successful results into the corresponding `cached*` provider as a side effect.
2. A `cached*` provider reads/writes the last known value to `SharedPreferences` (via `lib/util/shared_preferences.dart`),
   keyed by the active user's `userData.id` plus a resource key (e.g. week).
3. A user-facing provider (e.g. `TimeTable`) watches `canMakeRequestProvider` (network connectivity); if online it
   watches the `request*` provider and returns its value once available, otherwise (or while loading) it falls back
   to the `cached*` provider's last-known value.

Follow this same three-provider shape when adding a new piece of data that should work offline.

### Untis session & auth model

`UntisSession` (`lib/core/untis/untis_session.dart`) is a `freezed` sealed union with two states:
`InactiveUntisSession` (school + credentials only) and `ActiveUntisSession` (adds `appSharedSecret` and `userData`
after successful login). `activateSession()` performs the login handshake (`requestAppSharedSecret` →
`requestUserData`), with a fallback path for schools/QR-codes where the stored "password" is actually already an
app-shared-secret/OTP key. `refreshSession()` re-fetches `userData` for an already-active session on app start.
Sessions are stored as a list in `UntisSessionsProvider` (index 0 is the currently active session) and persisted to
`SharedPreferences` as JSON.

Authentication ultimately relies on TOTP (`otp` package) derived from the app-shared-secret, sent as `authParams` on
each RPC call — see `AuthParams` usage in `requests/request_timetable.dart` for the pattern to copy for new requests.

### Multi-tenant school support

Different schools front Untis with different login portals/SSO variants (see `docs/api/captures/startup/00_*_order_of_requests.md`
files: `bs_gfv`, `cjd`, `schuldorf`, `wolfsburger_oberschule`). `School.rpcUrl` builds the per-school JSON-RPC
endpoint from the school's `server`/`loginName`. When touching login/startup flows, check `docs/api/captures/startup/` for the
per-provider request sequences before assuming one flow fits all schools.

### API documentation

`docs/api/` contains reverse-engineered documentation of the private Untis Mobile API (captured via HTTP Toolkit
against an Android emulator running the official Untis app — see `docs/api/index.md` for the interception setup).
`docs/api/captures/` holds the raw, redacted per-request captures (`startup/` for the login/bootstrap sequence per
school-portal variant, `home/` for in-app endpoints — timetable, homework, exams, messages, dashboard);
`docs/api/spec/openapi.yaml` and `docs/api/spec/NOTES.md` are the readable, consolidated reference derived from
those captures — prefer the spec over the raw captures when just looking something up. Model files under
`lib/core/untis/models/**/*.txt` pair raw captured JSON with the freezed models derived from them (see
`lib/core/untis/models/README.md`). When adding or changing a model, check for a matching `.txt` capture first.

### Not yet implemented

Background/local notifications are not on `main` — the scaffolding (`lib/background/service.dart`, the
`Workmanager`/`flutter_local_notifications`/`permission_handler` dependencies, and the disabled block that
called them from `main.dart`'s `_initializeApp`) lives on the `push-notifications` branch instead, since iOS
doesn't support periodic background fetch and this is blocked on a cross-platform design decision. Don't merge
or reintroduce it without checking with the maintainer first.

## Conventions

- German is the UI language (`Intl.defaultLocale = 'de'`); user-facing strings (error dialogs, screen text) are
  written in German, matching the existing screens.
- `analysis_options.yaml` enables `require_trailing_commas`, `always_use_package_imports` (no relative imports),
  `prefer_single_quotes`, and `always_declare_return_types` — match these in new code; `flutter analyze` enforces
  them along with `riverpod_lint`.
- Generated files (`*.g.dart`, `*.freezed.dart`) are gitignored — treat their absence in a fresh checkout as normal
  and run `build_runner build` rather than assuming something is broken.
