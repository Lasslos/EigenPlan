# API reverse-engineering notes (2026 generation)

Companion to [`openapi.yaml`](./openapi.yaml). That file is the schema reference; this file is the prose —
per-school login walkthroughs, a consolidated list of open questions, and my take on what in the *current*
codebase (`lib/core/untis/`, `lib/core/rpc_request/`) should change for the rewrite, since you asked to hear
it. Source captures this was derived from live under `docs/api/captures/home/` and `docs/api/captures/startup/`
(raw HTTP Toolkit dumps, app v6.7.0 against WU server 2027.0.2, redacted before being committed — see each
file for the exact endpoint).

## 1. What actually changed since the app was last touched

The single biggest structural change: **the backend now speaks two APIs**, not one.

- The *old* app (and 100% of the current EigenPlan implementation) only ever spoke JSON-RPC 2.0 against
  `jsonrpc_intern.do`. That endpoint is still there and still works — `getUserData2017`, `getTimetable2017`,
  `getExams2017`, `getHomeWork2017`, `getStudentAbsences2017`, `getPeriodData2017` all still return data.
- The *new* app additionally — and, based on which endpoints carry the richer data, **primarily** — talks to a
  REST-ish API under `/WebUntis/api/**`, authenticated with a JWT bearer token. This is where the home screen,
  the messages inbox, and above all the **timetable rendering** now live (`timetable/grid` + `timetable/entries`
  produce a pre-laid-out grid model with none of `getTimetable2017`'s simplicity — see §4).

Practically: a rewrite should treat JSON-RPC as the "master data + legacy fallback" transport and REST as the
transport for anything user-facing, not port the old 1:1 RPC-call-per-provider structure forward. See §5 for
why I'd go further than that.

## 2. Login flow per school

All four schools start the same way:

1. `POST https://schoolsearch.webuntis.com/schoolquery2` (`searchSchool`) → pick a `SchoolInfo`.
2. `GET /WebUntis/api/public/v1/login-meta?school=...` → `{ anonymousLoginEnabled, ssoLoginEnabled }`. **This
   response should drive which login UI you show and which of the three flows below you run** — today's
   `activateSession()` instead tries password-login first and falls back to "maybe the password is actually a
   secret" on auth failure, which only accidentally covers the SSO case and doesn't cover anonymous at all.

### 2a. Normal password login — `cjd-koewi`, `wolfsburger-oberschule`

```
POST /WebUntis/api/mobile/v2/{school}/authentication   { username, password }  →  { jwt, ... }
      -- or, the JSON-RPC equivalent --
POST jsonrpc_intern.do  getAppSharedSecret  { userName, password }  →  app-shared-secret (persist this, not the password)
POST jsonrpc_intern.do  getAuthToken        { auth: { user, otp, clientTime } }  →  JWT
```

Both paths were observed in the captures and **it's genuinely unclear whether they're interchangeable** — the
original capture notes ask this exact question and I couldn't resolve it from the data alone (see §3). Until
it's re-verified, I'd pick *one* deliberately rather than keep both "just in case": the JSON-RPC path is
strictly more useful because it also gives you the long-lived app-shared-secret to persist (letting you
recompute OTPs indefinitely without asking for the password again), whereas `/authentication` only gives you a
short-lived JWT. I'd standardize on `getAppSharedSecret` → `getAuthToken`, and only reach for
`/authentication` if a follow-up capture shows the two JWTs are *not* interchangeable for some REST endpoint.

### 2b. Anonymous login — `bs-gfv`

No credentials collected at all. `login-meta` reports `anonymousLoginEnabled: true`.

- JSON-RPC calls use the literal auth object `{ "user": "#anonymous#", "otp": 0, "clientTime": <now> }` — no
  shared secret, no TOTP computation.
- Some REST GETs instead take an `anonymous-school-base64` header (base64 of the school's `loginName`) in
  place of `Authorization: Bearer`. Directly observed on `home`, `dashboard/cards`, `timetable/menu`.
- **Open question (see §3):** whether *every* REST endpoint accepts that header, or whether the app also calls
  `getAuthToken` with the anonymous auth object to get a real (if low-privilege) JWT and uses bearer auth
  everywhere else. I'd bet on the latter given `trigger/startup` was captured for bs-gfv described as "auth
  header like always" — but it wasn't captured precisely enough to be sure. **Recommendation: re-capture a
  full bs-gfv session end-to-end before implementing, specifically watching whether `getAuthToken` is called
  at all for this account.**

### 2c. SSO / key-based login — `schuldorf`

`login-meta` reports `ssoLoginEnabled: true`; regular password login is disabled server-side for this school.
The Untis Mobile app's UI for this case is: scan a QR code, or paste in a "key" by hand. **That key is used
directly as the app-shared-secret** — it's fed straight into TOTP generation, `getAppSharedSecret` is never
called. This is exactly the "maybe password is secret" fallback branch that already exists in
`activateSession()` today (added for QR-code logins) — for an SSO school it isn't a fallback, it's the *only*
path, so I'd promote it to a first-class login mode selected by `login-meta.ssoLoginEnabled`, rather than
something you only discover by trying normal login and catching the failure.

### 2d. Bootstrap sequence after obtaining a token (all schools)

Roughly, in observed order:

1. `getAppInfo` (JSON-RPC, no auth) — version info, sanity check.
2. Get a token (§2a/b/c).
3. `getUserData2017` (JSON-RPC) — master data (klassen/rooms/subjects/teachers/absence reasons/etc.) + the
   legacy per-user `userData`/`settings` blocks.
4. `GET /api/rest/view/v3/mobile/data` (REST) — tenant + logged-in-user summary. **Distinct payload from
   step 3's `userData`** — don't conflate them into one model (see §5).
5. `POST https://push.webuntis.com/api/register/` — register FCM token. Currently unimplemented/disabled in
   EigenPlan on purpose (see `CLAUDE.md`); documented for completeness only.
6. `GET /api/rest/view/v1/profile/user-email`, `GET /api/rest/view/v1/trigger/startup` — small ancillary calls.
7. `GET /api/rest/view/v1/messages/status`, `GET /api/rest/view/v1/dashboard/cards/status` — badge counts.
8. `POST /api/rest/view/v1/statistics/usage-statistics-status` — opt-in telemetry status check.

## 3. Consolidated list of open questions (things marked **UNKNOWN** in the spec)

Grouped by how much they matter for a rewrite:

**Blocking / worth a re-capture before implementing:**
- Does `/authentication`'s JWT work everywhere `getAuthToken`'s JWT does, or should the app pick one path per
  school and stick to it? (§2a)
- `bs-gfv` (anonymous): does *every* REST endpoint accept `anonymous-school-base64`, or is a real (anonymous)
  bearer JWT obtained and used for most of them? (§2b)
- `GET /timetable/menu`'s 200 response shape was never captured — every account tested happened to hit the
  404/`NO_TIMETABLES_AVAILABLE_FOR_YOUR_USER` path. Needed before you can build the "switch resource" UI.
- `resourceType` for `timetable/entries` / `calendar-entry/detail`'s `elementType` — only `STUDENT`/`CLASS`
  (and `elementType=5`) were observed; teacher/room/subject views are almost certainly needed for the
  `wolfsburger-oberschule` teacher account and weren't captured.

**Nice to resolve, not blocking:**
- Whether the server uses the JSON-RPC `auth` object's `clientTime` only to reject requests with too much
  clock drift, or also uses it to independently derive the expected OTP (relevant for how tightly a rewrite
  needs to keep client/server clocks in sync).
- How reliably `masterDataTimestamp`-based change detection works in practice — i.e. when the server actually
  considers `getUserData2017`'s master data stale and worth re-fetching, versus just always re-sending it.
- `timetable/entries`'s `format` query parameter's actual effect (response `format` was always `1` regardless
  of what was requested).
- Several always-empty arrays whose item shape is genuinely unknown because no account had real data:
  `exams`, `absences` (both the JSON-RPC and `calendar-entry` flavors), `dayEntries`, `backEntries`,
  `resources`, `students`, `homeworks` (calendar-entry's flavor), `recipientOptions`, `replyHistory`,
  `startupActions`, `teachingMethods`. All marked in `openapi.yaml`; low risk since freezed will just need a
  `List<dynamic>` or a best-guess model you can loosen later.
- `MessageDetail.blobAttachment` / `requestConfirmation` — always `null`, shape unknown, third
  attachment/reply mechanism alongside the two that are documented.

None of these block starting the rewrite — they block specific screens (timetable resource-switching,
exams, absences). I'd sequence the rewrite to hit the well-understood endpoints first (home, messages,
timetable for the resource you're already logged in as) and re-capture for the rest as you get to those
screens.

## 4. The new timetable model, briefly

`getTimetable2017` (`periods: [...]`, one flat list, `elements: [{type, id}]`) is gone from the UI's
perspective, replaced by two REST calls:

- `GET /timetable/grid` — layout metadata: weekday/period-slot geometry, and multiple named **format
  presets** a school can define (e.g. a lesson-numbered grid vs. a wall-clock grid) — cache this, it's not
  resource-specific.
- `GET /timetable/entries` — the actual data, one `TimetableDay` per date, each with `gridEntries[]` that are
  *already laid out* for rendering: `layoutGroup`/`layoutStartPosition`/`layoutWidth` describe how to place
  overlapping periods side-by-side, and `position1..position7` are independently-populated slots each carrying
  a `current`/`removed` pair so substitutions can show "was X, now Y" in one cell.

This is a meaningfully bigger model than the old `TimetablePeriod`. I would not try to map the new shape onto
the existing `TimetablePeriod`/`TimetablePeriodElement` freezed classes — model it fresh (`GridEntry`,
`GridEntryPositionItem` etc., as scaffolded in `openapi.yaml`) and let the UI layer consume the pre-computed
layout instead of re-deriving overlap logic itself, which is what `layoutGroup`/`layoutWidth` exist to let you
stop doing.

**Resolved during the Phase 3a design spike** (live curl capture against a real teacher account with a
genuine overlap — see `../captures/home/timetable_entries_overlap_example.md`, superseding the "unconfirmed
for other resource types"/"always `0`/`1000`" caveats above and in `openapi.yaml`'s earlier draft):
`layoutStartPosition`/`layoutWidth` are real and worth rendering directly — no client-side collision/packing
algorithm needed, `period_layout.dart`'s manual layout math should be retired outright rather than adapted.
The server proportionally shares width among whatever's genuinely concurrent at each moment (full width alone,
split evenly when things coincide), while a day-long entry can hold a fixed-width column for its whole span.
Position-slot ordering is resource-type-dependent: `STUDENT`/`CLASS` resources get `position1=TEACHER`
(array-valued when co-taught), `position2=SUBJECT`, `position3=ROOM`; `TEACHER` resources get
`position1=CLASS`, `position2=SUBJECT`/`INFO`, `position3=ROOM`, `position4=TEACHER` (populated only for a
second co-teacher). `position5`-`position7` still unobserved for any resource type.

**Also surfaced by that same capture, unrelated to the layout question**: `getTimetable2017` is not reliable
on the current server generation — a live check against a real account (real periods confirmed to exist via
`timetable/entries` for the identical date range) returned **zero periods** from `getTimetable2017` with no
error at all, and in an earlier app-level test the same call NPE'd server-side
(`Cannot invoke "...ElementType.getWuType()" because "request.type" is null`) for the same account. Neither
failure mode is something the client can work around (the REST endpoint has genuinely different, correct
data). This raises the priority of the REST timetable migration from "nice architecture" to "the legacy
endpoint may already be silently broken for some schools" — don't treat Phase 3 as deferrable.

## 5. Things I'd genuinely reconsider in the existing codebase

You asked for this, so — concretely, in priority order:

1. **Credentials are persisted in plaintext via `SharedPreferences`, not `flutter_secure_storage`.**
   `UntisSessionsProvider` (`lib/core/provider/untis_session_provider.dart`) JSON-serializes the *entire*
   `UntisSession` — including `password` and, worse, the long-lived `appSharedSecret` (functionally a
   permanent credential, since it's what generates every future OTP) — and writes it through
   `sharedPreferences.setStringList`. Meanwhile `lib/util/secure_storage_util.dart` defines a `secureStorage`
   (`FlutterSecureStorage`) instance that is **never referenced anywhere else in the codebase** — it's
   dead/scaffolded code. On Android, `SharedPreferences` backs onto an unencrypted XML file readable by
   anything with root/backup access to the app's data dir. For a rewrite, I'd store `password`/`appSharedSecret`
   in `secureStorage` keyed by session id, and keep only non-secret identifiers (school, username, userData)
   in the freezed/`SharedPreferences`-backed session model.

2. **`getAppSharedSecret`/`getAuthToken` vs. `/authentication` needs one canonical path, not two.** Right now
   the plan would be to keep both "just in case" — I'd rather pick one deliberately (see §2a) so there's only
   one login code path per non-SSO, non-anonymous school to test and maintain.

3. **Login-mode should be data-driven from `login-meta`, not inferred from a caught exception.** The existing
   `activateSession()` fallback ("try password login, and if that specifically fails with
   `authenticationFailed`/`userLocked`, retry treating the password as a shared secret") happens to work for
   `schuldorf` by accident, and silently can't work for `bs-gfv` at all (there's no password to fail with).
   Calling `login-meta` first and branching on `ssoLoginEnabled`/`anonymousLoginEnabled` up front is both more
   correct and lets the login *UI* adapt (hide the password field for anonymous, show "paste your key" copy
   for SSO) instead of always presenting a password form.

4. **Two different "who is the user" payloads exist now (`getUserData2017`'s `userData` vs. `mobile/data`'s
   `user`) and they are not the same shape or the same data.** Worth two distinct providers/models rather than
   merging fields from both into one `UserData` class the way the current `lib/core/untis/models/user_data/`
   does — they're fetched from different transports, refresh independently, and (per §2b/§2c) aren't even both
   guaranteed to be present for every login mode (`mobile/data.user` is `null` for anonymous logins;
   `getUserData2017.userData` is always present, just synthetic).

5. **The `getPeriodData2017`/`calendar-entry/detail` two-step (grid entry → `ttIds`/`elementId` → detail
   fetch) is now the real path to homework/notes/attachances for a period**, not `getHomeWork2017`'s flat
   date-range list, if you're already rendering the new REST timetable grid. Worth deciding up front whether
   the homework screen stays a flat `getHomeWork2017`-backed list (simpler, keeps working) or switches to
   being derived from calendar entries per visible period (matches what the new grid UI does, more calls).
   I'd lean toward keeping `getHomeWork2017` for a dedicated "all homework" list screen and only using
   `calendar-entry/detail` for the "tap a period" drill-down — no need to migrate something that isn't broken.

None of this is committed to code yet — it's flagged here per your ask, for you to weigh in on before it
shapes the freezed models/providers.

## 6. A note on the "live vs. cached" three-provider pattern

`CLAUDE.md`'s documented `request*`/`cached*`/user-facing-provider pattern (for offline support) still applies
cleanly to the REST endpoints — nothing about the transport change affects that shape. The one adjustment:
since REST responses are now the richer source of truth for timetable/messages/home, those three screens'
`cached*` providers should snapshot the REST response shapes (`TimetableEntriesResponse`,
`MessagesListResponse`, `HomeResponse`), not the old JSON-RPC ones.

## 7. What's *not* covered here

- Push notifications (`push.webuntis.com/api/register/`, the barely-captured `refresh-device-presence`
  endpoint) — intentionally out of scope per `CLAUDE.md` ("Not yet implemented"), documented in `openapi.yaml`
  for completeness only.
- Anything involving *writing* data (composing a message, marking homework complete, absence check-in) — none
  of the captures exercised a write path, so none is documented. `MessagesPermissions` suggests composing is
  possible for at least some accounts (`maxFileSize`/`maxFileCount`/`recipientSearchMaxResult` imply a compose
  form exists) but the request shape for it was never captured.
