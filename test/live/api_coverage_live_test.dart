@Tags(['live'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:your_schedule/core/rpc_request/rpc.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/week.dart';

import '../support/json_parity.dart';
import '../support/test_shared_preferences.dart';
import 'capturing_client.dart';
import 'known_gaps.dart';
import 'live_credentials.dart';

/// Exhaustively exercises the real Untis API with real accounts to answer three
/// questions: does everything parse without throwing; is there API surface we don't
/// model yet (a field the server sends that no `fromJson` picks up, via
/// [findUnparsedKeys]); and — the case that actually caught a real doc bug once
/// (`calendar-entry/detail`'s `homeworks[]`/`elementId` semantics, 2026-08) — has a
/// field `openapi.yaml`/`NOTES.md` documents as "always empty/null in captures"
/// quietly started returning real data ([isStillEmpty], from `known_gaps.dart`).
/// `findUnparsedKeys` alone can't catch that last case: a loosely-typed
/// (`List<dynamic>`/`Map<String,dynamic>?`) or allow-listed field already "consumes"
/// its raw key regardless of whether the value is empty or populated.
///
/// Every read-only endpoint in `openapi.yaml` is called at least once per credential
/// here, and "list" responses are chained into their "detail" endpoint for whatever
/// they return — not sampled, not a fixed date/id chosen up front: messages → the
/// detail of *every* message → attachment-storage-url *and* the actual S3 download
/// for every storage attachment on each; timetable entries (3 weeks: -1/0/+1) →
/// calendar-entry/detail for *every distinct period* those weeks contain (deduped by
/// `GridEntry.ids`, not just the ones flagged with a homework/notes icon) →
/// getPeriodData2017 batched across every period id that comes back; exams and
/// getMessagesOfDay2017 also span the same 3-week/21-day window rather than just
/// "now"/"today". This naturally adapts to whatever each account actually has. Two
/// endpoints are deliberately never called: `POST /api/register/` (real
/// push-notification device registration, a genuine write with a real side effect,
/// and push is intentionally unimplemented — see `CLAUDE.md`) and `PATCH
/// /api/refresh-device-presence/{id}` (entirely uncaptured shape, needs a registered
/// device id from the endpoint above).
///
/// Local-only, real credentials required: see `test/live/README.md`. Never wired
/// into CI. Runs as part of the Claude Code Stop hook's `full` verification level
/// (safe without credentials — see `test/live/README.md`); `dart_test.yaml` skips
/// the `live` tag unless `--run-skipped` is passed.
void main() {
  final credentials = loadLiveCredentials();

  if (credentials.isEmpty) {
    test(
      'live credentials configured',
      () {},
      skip: 'No live credentials found — see test/live/README.md.',
    );
    return;
  }

  for (final credential in credentials) {
    test('${credential.schoolSearch}: full API coverage', () async {
      await initTestSharedPreferences();
      final problems = <String>[];

      stdout.writeln(
        '=== ${credential.schoolSearch} (${credential.loginMode.name}) ===',
      );

      final log = ExchangeLog();

      // Each section gets its own short-lived ProviderContainer, disposed right
      // after — sections must stay isolated from each other. A shared container
      // across the whole flow meant one section's provider ending up in an error
      // state could cascade into "ProviderContainer already disposed"/hangs for
      // every section after it, once package:test's zone-level error handling
      // kicked in and started tearing down early.
      Future<void> section(
        String label,
        Future<void> Function(ProviderContainer) body,
      ) async {
        final sectionContainer = ProviderContainer();
        // Deferred to the whole test's teardown, not disposed right after body()
        // returns: the "live vs cached" pattern's listenSelf (CLAUDE.md) kicks off
        // a detached cache-write side effect that isn't awaited by — and can
        // outlive — the .future body() awaits. Disposing immediately raced that
        // write, intermittently throwing "Cannot use the Ref of
        // cachedTimeTableProvider(...), the associated container was disposed".
        addTearDown(sectionContainer.dispose);
        try {
          // Bounded so one stuck section can't eat the whole run — observed: a
          // provider whose build() threw a non-2xx HTTP/RPC error would sometimes
          // never settle its .future in this test harness (root cause not pinned
          // down; ruled out Sentry.captureException in logRequestError() — its
          // NoOpHub, active whenever SentryFlutter.init() hasn't run, resolves
          // immediately, so that's not it).
          await body(sectionContainer).timeout(const Duration(seconds: 20));
        } catch (e) {
          stdout.writeln('  ✗ $label: threw $e');
          problems.add('$label: threw $e');
        }
      }

      // Like [section], but for a plain read-only HTTP/RPC call with nothing to
      // drive through Riverpod — most of the newly-added "just call it for
      // coverage" endpoints below don't have (and don't need) a production
      // request* function yet.
      Future<void> discover(String label, Future<void> Function() body) async {
        try {
          await body().timeout(const Duration(seconds: 20));
        } catch (e) {
          stdout.writeln('  ✗ $label: threw $e');
          problems.add('$label: threw $e');
        }
      }

      // Prints one line per endpoint checked — status code, method+path, and
      // whether every key in the response was recognized. Counts/paths only, never
      // response content, per test/live/README.md. Unparsed keys already recorded
      // in known_gaps.dart are reported but don't fail the run — only a *new* gap
      // (something that showed up today and isn't already tracked) does.
      void checkParity(
        String label,
        dynamic raw,
        Object? model, {
        Set<String> knownGaps = const {},
      }) {
        final exchange = log.last;
        final unparsed = findUnparsedKeys(raw, model);
        final newGaps = unparsed
            .where((k) => !knownGaps.contains(normalizeKeyPath(k)))
            .toList();
        final outcome = switch ((unparsed.length, newGaps.length)) {
          (0, _) => 'OK',
          (final total, 0) => '$total known unparsed key(s)',
          (final total, final fresh) =>
            '$fresh NEW unparsed key(s) (of $total total)',
        };
        stdout.writeln(
          '  [${exchange.statusCode}] ${exchange.requestLabel} — $label: $outcome',
        );
        if (newGaps.isNotEmpty) {
          problems.add(
            '$label: ${newGaps.length} new unparsed key(s): ${newGaps.join(', ')}',
          );
        }
      }

      // The actually-new check this whole extension exists for: [value] is the raw
      // JSON at some path `openapi.yaml`/`NOTES.md` documents as "always
      // empty/null in captures". If it no longer is, that's real, previously
      // undiscovered API surface — fail loudly rather than silently ignoring it,
      // structure only (never content, matching this file's existing discipline).
      void checkStillEmpty(String label, dynamic value) {
        if (!isStillEmpty(value)) {
          final shape = switch (value) {
            List l when l.isNotEmpty && l.first is Map =>
              'List, length=${l.length}, item keys=${(l.first as Map).keys.toList()}',
            List l when l.isNotEmpty =>
              'List, length=${l.length}, item type=${l.first.runtimeType}',
            List l => 'List, length=${l.length}',
            Map m => 'Map, keys=${m.keys.toList()}',
            String s => 'String, length=${s.length}',
            _ => value.runtimeType.toString(),
          };
          stdout.writeln(
            '  🔎 DISCOVERY: $label is documented as always empty/null but is NOT — $shape',
          );
          problems.add(
            'DISCOVERY: $label is populated (openapi.yaml/NOTES.md documents it as always empty/null) — '
            'update the model/docs to capture it, see the 🔎 line above for shape.',
          );
        }
      }

      final schoolSearchContainer = ProviderContainer();
      addTearDown(schoolSearchContainer.dispose);

      await http.runWithClient(() async {
        // 1. School search — also exercises requestSchoolList's parser.
        final schools = await schoolSearchContainer.read(
          requestSchoolListProvider(credential.schoolSearch).future,
        );
        expect(
          schools,
          isNotEmpty,
          reason:
              'schoolsearch returned no match for "${credential.schoolSearch}"',
        );
        stdout.writeln(
          '  [${log.last.statusCode}] ${log.last.requestLabel} — school search: found ${schools.length}',
        );
        final school = schools.firstWhere(
          (s) => s.loginName == credential.schoolSearch,
          orElse: () => schools.first,
        );

        // 1b. login-meta — safe pre-auth, drives which login UI would be shown.
        await section('login-meta', (container) async {
          final meta = await container.read(
            requestLoginMetaProvider(school).future,
          );
          checkParity('login-meta', jsonDecode(log.last.responseBody), meta);
        });

        // 2. Login, per LoginMode — obtains userData (getUserData2017).
        UserData userData;
        String? appSharedSecret;
        switch (credential.loginMode) {
          case LoginMode.password:
            appSharedSecret = await requestAppSharedSecret(
              school,
              credential.username!,
              credential.password!,
            );
            stdout.writeln(
              '  [${log.last.statusCode}] ${log.last.requestLabel} — app-shared-secret: OK',
            );
            userData = await requestUserData(
              school,
              AuthParams.credentials(
                user: credential.username!,
                appSharedSecret: appSharedSecret,
              ),
            );
          case LoginMode.ssoKey:
            appSharedSecret = credential.key;
            userData = await requestUserData(
              school,
              AuthParams.credentials(
                user: credential.username!,
                appSharedSecret: appSharedSecret!,
              ),
            );
          case LoginMode.anonymous:
            userData = await requestUserData(
              school,
              const AuthParams.anonymous(),
            );
        }
        // getUserData2017's raw body was the *last* RPC exchange right above.
        // requestUserData() (see request_user_data.dart) only ever hands UserData
        // the RPC envelope's `result` — diff against that, not the whole envelope,
        // or `jsonrpc`/`id`/`result` show up as false-positive "unparsed" fields.
        final userDataRaw = jsonDecode(log.last.responseBody);
        final userDataResult = userDataRaw is Map
            ? userDataRaw['result'] as Map<String, dynamic>
            : userDataRaw as Map<String, dynamic>;
        checkParity(
          'userData',
          userDataResult,
          userData,
          knownGaps: userDataKnownGaps,
        );
        checkStillEmpty(
          'getUserData2017.masterData.teachingMethods',
          (userDataResult['masterData']
              as Map<String, dynamic>?)?['teachingMethods'],
        );
        checkStillEmpty(
          'getUserData2017.userData.children',
          (userDataResult['userData'] as Map<String, dynamic>?)?['children'],
        );

        final session =
            UntisSession.active(
                  school,
                  credential.loginMode,
                  credential.username,
                  null,
                  appSharedSecret,
                  userData,
                )
                as ActiveUntisSession;

        // Shared auth token for the plain-HTTP "discover" calls below, which don't
        // go through a production request* function (so nothing else fetches it
        // for them). Fetched once per account, not per endpoint.
        AuthToken? restAuthToken;
        if (credential.loginMode != LoginMode.anonymous) {
          final authContainer = ProviderContainer();
          addTearDown(authContainer.dispose);
          restAuthToken = await authContainer.read(
            authTokenProvider(session).future,
          );
        }

        Future<http.Response> restGet(
          String path, [
          Map<String, String> extraParams = const {},
        ]) {
          final uri = Uri.https(session.school.server, path, {
            'school': session.school.loginName,
            ...extraParams,
          });
          return http.get(uri, headers: session.restAuthHeaders(restAuthToken));
        }

        // 3. mobile/data.
        await section('mobile/data', (container) async {
          final mobileData = await container.read(
            requestMobileDataProvider(session).future,
          );
          checkParity(
            'mobile/data',
            jsonDecode(log.last.responseBody),
            mobileData,
          );
          final mobileDataRaw =
              jsonDecode(log.last.responseBody) as Map<String, dynamic>;
          checkStillEmpty(
            'mobile/data.user.referencedStudents',
            (mobileDataRaw['user']
                as Map<String, dynamic>?)?['referencedStudents'],
          );
        });

        // 3b. profile/user-email, trigger/startup, statistics/usage-statistics-status —
        // small session-scoped endpoints with no dedicated production function yet.
        await discover('profile/user-email', () async {
          final response = await restGet(
            '/WebUntis/api/rest/view/v1/profile/user-email',
          );
          stdout.writeln(
            '  [${response.statusCode}] GET .../profile/user-email',
          );
        });
        await discover('trigger/startup', () async {
          final response = await restGet(
            '/WebUntis/api/rest/view/v1/trigger/startup',
          );
          if (response.statusCode == 200) {
            final decoded =
                jsonDecode(utf8.decode(response.bodyBytes))
                    as Map<String, dynamic>;
            checkStillEmpty(
              'trigger/startup.startupActions',
              decoded['startupActions'],
            );
          }
          stdout.writeln('  [${response.statusCode}] GET .../trigger/startup');
        });
        await discover('statistics/usage-statistics-status', () async {
          final uri = Uri.https(
            session.school.server,
            '/WebUntis/api/rest/view/v1/statistics/usage-statistics-status',
            {'school': session.school.loginName},
          );
          final response = await http.post(
            uri,
            headers: session.restAuthHeaders(restAuthToken),
          );
          stdout.writeln(
            '  [${response.statusCode}] POST .../usage-statistics-status',
          );
        });

        // 3c. Home / dashboard — no production function yet, coverage + light
        // discovery (cell/status enum values, not content, per this file's privacy
        // discipline).
        await discover('home', () async {
          final response = await restGet('/WebUntis/api/rest/view/v2/home');
          if (response.statusCode == 200) {
            final decoded =
                jsonDecode(utf8.decode(response.bodyBytes))
                    as Map<String, dynamic>;
            final cellTypes = <String>{
              for (final s in (decoded['sections'] as List<dynamic>? ?? []))
                for (final cell
                    in ((s as Map<String, dynamic>)['cells']
                            as List<dynamic>? ??
                        []))
                  (cell as Map<String, dynamic>)['type'] as String,
            };
            stdout.writeln(
              '  [${response.statusCode}] GET .../home — cell types observed: $cellTypes',
            );
          } else {
            stdout.writeln('  [${response.statusCode}] GET .../home');
          }
        });
        await discover('dashboard/cards', () async {
          final response = await restGet(
            '/WebUntis/api/rest/view/v1/dashboard/cards',
          );
          if (response.statusCode == 200) {
            final decoded =
                jsonDecode(utf8.decode(response.bodyBytes))
                    as Map<String, dynamic>;
            final cards = decoded['dashboardCards'] as List<dynamic>? ?? [];
            final statuses = cards
                .map((c) => (c as Map<String, dynamic>)['status'])
                .toSet();
            stdout.writeln(
              '  [${response.statusCode}] GET .../dashboard/cards — ${cards.length} card(s), statuses: $statuses',
            );
          } else {
            stdout.writeln(
              '  [${response.statusCode}] GET .../dashboard/cards',
            );
          }
        });
        await discover('dashboard/cards/status', () async {
          final response = await restGet(
            '/WebUntis/api/rest/view/v1/dashboard/cards/status',
          );
          stdout.writeln(
            '  [${response.statusCode}] GET .../dashboard/cards/status',
          );
        });

        // 4. Messages list, then — the case that matters most — the detail of
        //    *every* message returned, and (newly) the attachment-storage-url of
        //    every storage-backed attachment on each of those. Content is the most
        //    heterogeneous data in the API, so this is the most likely place to
        //    catch a field the server added that SpecifiedMessage doesn't know
        //    about yet.
        //
        //    Skipped for anonymous accounts: confirmed (via live testing against
        //    bs-gfv) that the server returns 403 Forbidden for anonymous sessions on
        //    both the list and detail endpoints — a genuine, permanent authorization
        //    boundary, not a bug. RequestMessages/RequestSpecifiedMessage now assert
        //    against being called with an anonymous session, so calling them here
        //    would just trip that assert instead of exercising anything new. The
        //    same applies to messages/status and messages/permissions below.
        if (credential.loginMode == LoginMode.anonymous) {
          stdout.writeln(
            '  – messages / messages-status / messages-permissions: skipped (not available for anonymous sessions)',
          );
        } else {
          await section('messages', (container) async {
            final messages = await container.read(
              requestMessagesProvider(session).future,
            );
            checkParity(
              'messages list (${messages.incomingMessages.length} messages)',
              jsonDecode(log.last.responseBody),
              messages,
            );
            checkStillEmpty(
              'messages.readConfirmationMessages',
              (jsonDecode(log.last.responseBody)
                  as Map<String, dynamic>)['readConfirmationMessages'],
            );

            for (final message in messages.incomingMessages) {
              await section('message ${message.id} detail', (container) async {
                final detail = await container.read(
                  requestSpecifiedMessageProvider(session, message.id).future,
                );
                final detailRaw =
                    jsonDecode(log.last.responseBody) as Map<String, dynamic>;
                checkParity('message ${message.id} detail', detailRaw, detail);
                checkStillEmpty(
                  'message ${message.id}.blobAttachment',
                  detailRaw['blobAttachment'],
                );
                checkStillEmpty(
                  'message ${message.id}.requestConfirmation',
                  detailRaw['requestConfirmation'],
                );
                // Confirmed populated (2026-08 live probe, a message that had actually
                // been replied to) — informational only, not a checkStillEmpty case
                // anymore (see openapi.yaml's MessageDetail.replyHistory).
                final replyHistory =
                    detailRaw['replyHistory'] as List<dynamic>? ?? [];
                if (replyHistory.isNotEmpty) {
                  stdout.writeln(
                    '  message ${message.id}.replyHistory: ${replyHistory.length} repl(y/ies)',
                  );
                }

                for (final attachment in detail.storageAttachments) {
                  await section(
                    'message ${message.id} attachment ${attachment.id} storage-url',
                    (container) async {
                      final storageUrl = await container.read(
                        requestAttachmentStorageUrlProvider(
                          session,
                          attachment.id,
                        ).future,
                      );
                      checkParity(
                        'attachment ${attachment.id} storage-url',
                        jsonDecode(log.last.responseBody),
                        storageUrl,
                      );
                      // Actually exercise the S3 SSE-C download, not just URL
                      // resolution — the `additionalHeaders` replay is the fragile
                      // part (see downloadAttachment's doc comment), so this is the
                      // only way to prove it still works. Byte count only, never content.
                      final bytes = await downloadAttachment(storageUrl);
                      stdout.writeln(
                        '  message ${message.id} attachment ${attachment.id}: downloaded ${bytes.length} byte(s)',
                      );
                    },
                  );
                }
              });
            }
          });

          await discover('messages/status', () async {
            final response = await restGet(
              '/WebUntis/api/rest/view/v1/messages/status',
            );
            stdout.writeln(
              '  [${response.statusCode}] GET .../messages/status',
            );
          });
          await discover('messages/permissions', () async {
            final response = await restGet(
              '/WebUntis/api/rest/view/v1/messages/permissions',
            );
            if (response.statusCode == 200) {
              // Confirmed populated (2026-08 live probe) for both STUDENT and TEACHER
              // accounts — informational only, not a checkStillEmpty case anymore
              // (see openapi.yaml's MessagesPermissions.recipientOptions).
              final decoded =
                  jsonDecode(utf8.decode(response.bodyBytes))
                      as Map<String, dynamic>;
              final recipientOptions =
                  decoded['recipientOptions'] as List<dynamic>? ?? [];
              stdout.writeln(
                '  [${response.statusCode}] GET .../messages/permissions — recipientOptions: ${recipientOptions.length}',
              );
            } else {
              stdout.writeln(
                '  [${response.statusCode}] GET .../messages/permissions',
              );
            }
          });
        }

        // 4b. getMessagesOfDay2017 — legacy "message of the day", distinct from the
        // REST inbox above and not gated on the same anonymous-403 boundary (never
        // confirmed either way), so always attempted; tolerant of failure. Checked
        // for every day across the same 3-week window as timetable entries below
        // (not just today) — a message of the day is inherently per-date, and
        // "today" alone would miss anything scheduled for another day in range.
        var messagesOfDayTotal = 0;
        for (final relative in [-1, 0, 1]) {
          for (final day in Week.relative(relative).daysInWeek) {
            await discover('getMessagesOfDay2017 ($day)', () async {
              final response = await rpcRequest(
                method: 'getMessagesOfDay2017',
                params: [
                  {
                    'date': day.format(DateFormat('yyyy-MM-dd')),
                    ...session.authParams.toJson(),
                  },
                ],
                serverUrl: Uri.parse(session.school.rpcUrl),
              );
              switch (response) {
                case RPCResponseResult():
                  final messages =
                      response.result['messages'] as List<dynamic>? ?? [];
                  messagesOfDayTotal += messages.length;
                case RPCResponseError():
                  stdout.writeln(
                    '  RPC getMessagesOfDay2017 ($day) — error (tolerated): ${response.error.code}',
                  );
              }
            });
          }
        }
        stdout.writeln(
          '  getMessagesOfDay2017: $messagesOfDayTotal message(s) across 21 scanned days',
        );

        // 5+ need a resource (elemType/id) to ask the server for a timetable,
        // exams, homework, or calendar entries against. Some anonymous accounts
        // (confirmed live against bs-gfv) come back from getUserData2017 with a
        // null elemType/id — the server has no resource on file for them — which
        // is a genuine, permanent per-account data gap, not a bug:
        // request_timetable_entries.dart already guards this client-side with a
        // clear StateError, and getExams2017/getHomeWork2017 just hang
        // server-side when asked with a null/-1 id instead of erroring. Skip all
        // of these rather than let any show up as a "problem".
        final hasTimetableResource = session.userData.type != null;
        final ownResource = hasTimetableResource
            ? TimetableResourceRef.own(session)
            : null;

        List<String>? availableTimetables;
        await section('timetable/menu', (container) async {
          final menu = await container.read(
            requestTimetableMenuProvider(session).future,
          );
          if (log.last.statusCode == 200) {
            checkParity(
              'timetable/menu',
              jsonDecode(log.last.responseBody),
              menu,
            );
            availableTimetables = menu?.availableTimetables;
          } else {
            stdout.writeln(
              '  [${log.last.statusCode}] ${log.last.requestLabel} — timetable/menu (expected 404 only for accounts with no timetable resource, e.g. anonymous)',
            );
          }
        });

        // timetable/filter — one call per resourceType the app's own menu offers
        // (falls back to the four known types if menu itself came back empty/404).
        // Anonymous accounts (confirmed live against bs-gfv, 2026-08) get 200 with
        // `anonymous-school-base64` for resourceType=CLASS specifically, but 403
        // Forbidden for STUDENT/TEACHER/ROOM — a genuine, narrower authorization
        // boundary than timetable/menu's (which accepts the header for any type),
        // not something a retry/fix on our end can solve. See docs/api/spec/NOTES.md §2b/§4b.
        final resourceTypesToProbe = credential.loginMode == LoginMode.anonymous
            ? const ['CLASS']
            : availableTimetables ??
                  const ['CLASS', 'STUDENT', 'TEACHER', 'ROOM'];
        for (final resourceType in resourceTypesToProbe) {
          await section('timetable/filter ($resourceType)', (container) async {
            final filter = await container.read(
              requestTimetableFilterProvider(session, resourceType).future,
            );
            checkParity(
              'timetable/filter ($resourceType)',
              jsonDecode(log.last.responseBody),
              filter,
              knownGaps: timetableFilterKnownGaps,
            );
          });
        }

        await discover('timetable/grid', () async {
          final response = await restGet(
            '/WebUntis/api/rest/view/v1/timetable/grid',
          );
          stdout.writeln('  [${response.statusCode}] GET .../timetable/grid');
        });

        // 5. Timetable entries, current week +/- 1. Also feeds calendar-entry/detail
        // and getPeriodData2017 below with real grid entries to drill into.
        final scannedGridEntries = <GridEntry>[];
        if (!hasTimetableResource) {
          stdout.writeln(
            '  – timetable entries / entries settings / calendar-entry / getPeriodData2017: skipped (userData.elemType is null for this session)',
          );
        } else {
          await section('timetable/entries/settings', (container) async {
            final settings = await container.read(
              requestTimetableEntriesSettingsProvider(
                session,
                ownResource!.resourceType,
              ).future,
            );
            checkParity(
              'timetable/entries/settings',
              jsonDecode(log.last.responseBody),
              settings,
            );
          });

          for (final relative in [-1, 0, 1]) {
            final week = Week.relative(relative);
            await section('timetable entries ($week)', (container) async {
              await container.read(
                requestTimetableEntriesProvider(
                  session,
                  week,
                  ownResource!,
                ).future,
              );
              if (log.last.statusCode == 200) {
                // TimetableEntriesResponse isn't exposed by the provider (it returns
                // a day-keyed Map) — re-decode raw against the day list shape by
                // re-parsing the same JSON through the model directly.
                final raw = jsonDecode(log.last.responseBody);
                final reparsed = TimetableEntriesResponse.fromJson(
                  raw as Map<String, dynamic>,
                );
                checkParity(
                  'timetable entries ($week)',
                  raw,
                  reparsed,
                  knownGaps: timetableEntriesKnownGaps,
                );
                for (final day in (raw['days'] as List<dynamic>? ?? [])) {
                  final dayMap = day as Map<String, dynamic>;
                  checkStillEmpty(
                    'timetable entries ($week).days[].dayEntries',
                    dayMap['dayEntries'],
                  );
                  checkStillEmpty(
                    'timetable entries ($week).days[].backEntries',
                    dayMap['backEntries'],
                  );
                }
                for (final entry in reparsed.days) {
                  scannedGridEntries.addAll(entry.gridEntries);
                }
              } else {
                // A 404 ("no data for this range") is handled internally and makes
                // no model to diff against — still worth a line, so the report shows
                // every week that was actually checked.
                stdout.writeln(
                  '  [${log.last.statusCode}] ${log.last.requestLabel} — timetable entries ($week): no data',
                );
              }
            });
          }
          stdout.writeln(
            '  ${scannedGridEntries.length} grid entries scanned across the 3 fetched weeks',
          );
        }

        // 6. Exams — same 3-week window as timetable entries (-1/0/+1), not just
        // the current week, for consistent coverage between the two.
        if (!hasTimetableResource) {
          stdout.writeln(
            '  – exams: skipped (userData.elemType is null for this session)',
          );
        } else {
          for (final relative in [-1, 0, 1]) {
            final week = Week.relative(relative);
            await section('exams ($week)', (container) async {
              await container.read(requestExamsProvider(session, week).future);
              // getExams2017's raw envelope's `result` (not the whole envelope) is what
              // Exam.fromJson consumes per-item; spot-check the envelope shape itself
              // isn't silently missing top-level keys.
              final raw = jsonDecode(log.last.responseBody);
              if (raw is Map && raw['result'] is Map) {
                final examsRaw =
                    (raw['result'] as Map)['exams'] as List<dynamic>;
                stdout.writeln(
                  '  [${log.last.statusCode}] ${log.last.requestLabel} — exams ($week): ${examsRaw.length} exam(s)',
                );
                for (var i = 0; i < examsRaw.length; i++) {
                  final examJson = examsRaw[i] as Map<String, dynamic>;
                  checkParity(
                    'exam ($week)[$i]',
                    examJson,
                    Exam.fromJson(examJson),
                  );
                }
              }
            });
          }
        }

        // 6b. getStudentAbsences2017 — no production function/model yet (item shape
        // entirely UNKNOWN per NOTES.md); raw call, and the whole `absences` array
        // is itself the "documented always empty" claim to re-check. Unlike
        // exams/homework/timetable, its RPC params (includeUnExcused/startDate/
        // endDate/includeExcused/auth) don't take an `id`/`type` at all — not
        // gated behind hasTimetableResource, so this is attempted even for
        // accounts (like anonymous bs-gfv) with no resource on file.
        await discover('getStudentAbsences2017', () async {
          final dateFormat = DateFormat("yyyy-MM-dd'T'HH:mm'Z'");
          final response = await rpcRequest(
            method: 'getStudentAbsences2017',
            params: [
              {
                'includeUnExcused': true,
                'includeExcused': true,
                'startDate': dateFormat.format(
                  DateTime.now().subtract(const Duration(days: 60)),
                ),
                'endDate': dateFormat.format(
                  DateTime.now().add(const Duration(days: 60)),
                ),
                ...session.authParams.toJson(),
              },
            ],
            serverUrl: Uri.parse(session.school.rpcUrl),
          );
          switch (response) {
            case RPCResponseResult():
              checkStillEmpty(
                'getStudentAbsences2017.absences',
                response.result['absences'],
              );
              stdout.writeln(
                '  [${log.last.statusCode}] RPC getStudentAbsences2017 — ${(response.result['absences'] as List).length} absence(s)',
              );
            case RPCResponseError():
              stdout.writeln(
                '  RPC getStudentAbsences2017 — error (tolerated): ${response.error.code}',
              );
          }
        });

        // 7. Homework — now has a full production model/provider (see
        // request_homework.dart); parity-checked like exams/messages above, plus an
        // explicit check that no item's `attachments` (item shape UNKNOWN) has
        // quietly gained real content.
        if (!hasTimetableResource) {
          stdout.writeln(
            '  – homework: skipped (userData.elemType is null for this session)',
          );
        } else {
          await section('homework', (container) async {
            final homework = await container.read(
              requestHomeworkProvider(session).future,
            );
            final raw = jsonDecode(log.last.responseBody);
            checkParity(
              'homework',
              raw is Map && raw['result'] is Map ? raw['result'] : raw,
              homework,
            );
            stdout.writeln('  homework: ${homework.homeWorks.length} item(s)');
            for (final item in homework.homeWorks) {
              checkStillEmpty(
                'homework[${item.id}].attachments',
                item.attachments,
              );
            }
          });
        }

        // 8. calendar-entry/detail — the "tap a period" drill-down (see
        // request_calendar_entry_detail.dart). elementId is the *resource's own*
        // id (session.userData.id), not a period id — confirmed live 2026-08, see
        // that file's doc comment. Queries EVERY distinct period across all
        // scanned weeks (deduplicated by GridEntry.ids — a block/double-lesson
        // grid entry groups >1 underlying period id under one entry, so no entry
        // is skipped or sampled), not just the icon-flagged ones — a period with
        // no HOMEWORK/NOTES icon can still turn out to have notes/an exam/a moved
        // origin, and only exhaustively querying every period actually proves a
        // field is still empty rather than "empty in the sample we happened to
        // check". `exam`/`booking`/`originalCalendarEntry`/`videoCall`/
        // `resources`/`students` aren't modeled by CalendarEntryDetail at all
        // (deliberately, see its doc comment) so are checked against the raw
        // response here, not via checkParity.
        final periodDataIds = <int>{};
        if (!hasTimetableResource) {
          stdout.writeln(
            '  – calendar-entry/detail: skipped (userData.elemType is null for this session)',
          );
        } else {
          final elementType = elementTypeForResourceType(session.userData.type);
          if (elementType == null) {
            stdout.writeln(
              '  – calendar-entry/detail: skipped (elementType for resourceType=${session.userData.type} is unconfirmed — see request_calendar_entry_detail.dart)',
            );
          } else {
            final seenIdSignatures = <String>{};
            final toQuery = <GridEntry>[];
            for (final entry in scannedGridEntries) {
              if (entry.ids.isEmpty) {
                continue;
              }
              final signature = entry.ids.join(',');
              if (seenIdSignatures.add(signature)) {
                toQuery.add(entry);
              }
            }
            stdout.writeln(
              '  calendar-entry/detail: querying all ${toQuery.length} distinct period(s) across ${scannedGridEntries.length} scanned grid entries',
            );
            for (final entry in toQuery) {
              await section('calendar-entry/detail (period ${entry.ids.first})', (
                container,
              ) async {
                await container.read(
                  requestCalendarEntryDetailProvider(
                    session,
                    elementType,
                    session.userData.id,
                    entry.duration.start,
                    entry.duration.end,
                  ).future,
                );
                final raw =
                    jsonDecode(log.last.responseBody) as Map<String, dynamic>;
                final calendarEntries =
                    raw['calendarEntries'] as List<dynamic>? ?? [];
                stdout.writeln(
                  '  [${log.last.statusCode}] ${log.last.requestLabel} — calendar-entry/detail (period ${entry.ids.first}, icons=${entry.icons}): ${calendarEntries.length} entr(y/ies)',
                );
                for (final e in calendarEntries) {
                  final map = e as Map<String, dynamic>;
                  checkStillEmpty(
                    'calendar-entry/detail[${map['id']}].exam',
                    map['exam'],
                  );
                  checkStillEmpty(
                    'calendar-entry/detail[${map['id']}].booking',
                    map['booking'],
                  );
                  // Confirmed populated (2026-08 live probe, a moved/rescheduled period)
                  // — informational only, not a checkStillEmpty case anymore (see
                  // openapi.yaml's CalendarEntry.originalCalendarEntry).
                  if (map['originalCalendarEntry'] != null) {
                    stdout.writeln(
                      '  calendar-entry/detail[${map['id']}].originalCalendarEntry: present',
                    );
                  }
                  checkStillEmpty(
                    'calendar-entry/detail[${map['id']}].videoCall',
                    map['videoCall'],
                  );
                  checkStillEmpty(
                    'calendar-entry/detail[${map['id']}].resources',
                    map['resources'],
                  );
                  checkStillEmpty(
                    'calendar-entry/detail[${map['id']}].students',
                    map['students'],
                  );
                  for (final single
                      in (map['singleEntries'] as List<dynamic>? ?? [])) {
                    periodDataIds.add(
                      (single as Map<String, dynamic>)['id'] as int,
                    );
                  }
                  if ((map['singleEntries'] as List? ?? []).isEmpty) {
                    periodDataIds.add(map['id'] as int);
                  }
                }
              });
            }
          }
        }

        // 9. getPeriodData2017 — chained from whichever period ids calendar-entry/detail
        // (or, failing that, the grid entries themselves) actually returned, not a
        // fixed id. No production function/model yet; checks every "UNKNOWN item
        // shape, always empty" field on PeriodData explicitly.
        if (periodDataIds.isEmpty && scannedGridEntries.isNotEmpty) {
          for (final entry in scannedGridEntries) {
            periodDataIds.addAll(entry.ids);
          }
        }
        if (periodDataIds.isEmpty) {
          stdout.writeln(
            '  – getPeriodData2017: skipped (no period ids discovered)',
          );
        } else {
          await discover('getPeriodData2017', () async {
            final response = await rpcRequest(
              method: 'getPeriodData2017',
              params: [
                {
                  'ttIds': periodDataIds.toList(),
                  ...session.authParams.toJson(),
                },
              ],
              serverUrl: Uri.parse(session.school.rpcUrl),
            );
            switch (response) {
              case RPCResponseResult():
                final result = response.result as Map<String, dynamic>;
                // Confirmed populated (2026-08 live probe, wolfsburger-oberschule
                // TEACHER account) — informational only, not a checkStillEmpty case
                // anymore (see openapi.yaml's RpcResponseGetPeriodData2017.referencedStudents;
                // contains real student PII, count only, never content).
                final referencedStudents =
                    result['referencedStudents'] as List<dynamic>? ?? [];
                if (referencedStudents.isNotEmpty) {
                  stdout.writeln(
                    '  getPeriodData2017.referencedStudents: ${referencedStudents.length} student(s)',
                  );
                }
                final dataByTTId =
                    result['dataByTTId'] as Map<String, dynamic>? ?? {};
                stdout.writeln(
                  '  [${log.last.statusCode}] RPC getPeriodData2017 — ${dataByTTId.length}/${periodDataIds.length} period(s) with data',
                );
                for (final entry in dataByTTId.entries) {
                  final data = entry.value as Map<String, dynamic>;
                  // exemptions/seatingPlan are still genuinely unconfirmed-empty even
                  // against a TEACHER account (2026-08 probe); the other five fields
                  // this loop used to check here (absences/classRegEvents/classRoles/
                  // prioritizedAttendances/studentAssignments) are now confirmed
                  // populated for teacher accounts — see openapi.yaml's PeriodData.
                  for (final field in ['exemptions', 'seatingPlan']) {
                    checkStillEmpty(
                      'getPeriodData2017[${entry.key}].$field',
                      data[field],
                    );
                  }
                  final homeWorks = data['homeWorks'] as List<dynamic>? ?? [];
                  if (homeWorks.isNotEmpty) {
                    stdout.writeln(
                      '  getPeriodData2017[${entry.key}].homeWorks: ${homeWorks.length} item(s)',
                    );
                  }
                }
              case RPCResponseError():
                stdout.writeln(
                  '  RPC getPeriodData2017 — error (tolerated): ${response.error.code}',
                );
            }
          });
        }
      }, () => CapturingClient(log));

      stdout.writeln(
        problems.isEmpty
            ? '  ✓ ${credential.schoolSearch}: all endpoints checked cleanly'
            : '  ✗ ${credential.schoolSearch}: ${problems.length} problem(s) found',
      );

      expect(problems, isEmpty, reason: problems.join('\n'));
    }, timeout: const Timeout(Duration(minutes: 5)));
  }
}
