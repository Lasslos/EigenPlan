@Tags(['live'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:your_schedule/core/rpc_request/rpc.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/week.dart';

import '../support/json_parity.dart';
import '../support/test_shared_preferences.dart';
import 'capturing_client.dart';
import 'known_gaps.dart';
import 'live_credentials.dart';

/// Exhaustively exercises the real Untis API with real accounts to answer two
/// questions: does everything parse without throwing, and is there API surface we
/// don't model yet (a field the server sends that no `fromJson` picks up)? This
/// drives the actual production `request*` functions/providers — not reimplemented
/// HTTP calls — through a plain [ProviderContainer], and diffs every raw response
/// against the resulting model via [findUnparsedKeys].
///
/// Local-only, real credentials required: see `test/live/README.md`. Never wired
/// into CI. Runs as part of the Claude Code Stop hook's `full` verification level
/// (safe without credentials — see `test/live/README.md`); `dart_test.yaml` skips
/// the `live` tag unless `--run-skipped` is passed.
void main() {
  final credentials = loadLiveCredentials();

  if (credentials.isEmpty) {
    test('live credentials configured', () {}, skip: 'No live credentials found — see test/live/README.md.');
    return;
  }

  for (final credential in credentials) {
    test('${credential.schoolSearch}: full API coverage', () async {
      await initTestSharedPreferences();
      final problems = <String>[];

      stdout.writeln('=== ${credential.schoolSearch} (${credential.loginMode.name}) ===');

      final log = ExchangeLog();

      // Each section gets its own short-lived ProviderContainer, disposed right
      // after — sections must stay isolated from each other. A shared container
      // across the whole flow meant one section's provider ending up in an error
      // state could cascade into "ProviderContainer already disposed"/hangs for
      // every section after it, once package:test's zone-level error handling
      // kicked in and started tearing down early.
      Future<void> section(String label, Future<void> Function(ProviderContainer) body) async {
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

      // Prints one line per endpoint checked — status code, method+path, and
      // whether every key in the response was recognized. Counts/paths only, never
      // response content, per test/live/README.md. Unparsed keys already recorded
      // in known_gaps.dart are reported but don't fail the run — only a *new* gap
      // (something that showed up today and isn't already tracked) does.
      void checkParity(String label, dynamic raw, Object? model, {Set<String> knownGaps = const {}}) {
        final exchange = log.last;
        final unparsed = findUnparsedKeys(raw, model);
        final newGaps = unparsed.where((k) => !knownGaps.contains(normalizeKeyPath(k))).toList();
        final outcome = switch ((unparsed.length, newGaps.length)) {
          (0, _) => 'OK',
          (final total, 0) => '$total known unparsed key(s)',
          (final total, final fresh) => '$fresh NEW unparsed key(s) (of $total total)',
        };
        stdout.writeln('  [${exchange.statusCode}] ${exchange.requestLabel} — $label: $outcome');
        if (newGaps.isNotEmpty) {
          problems.add('$label: ${newGaps.length} new unparsed key(s): ${newGaps.join(', ')}');
        }
      }

      final schoolSearchContainer = ProviderContainer();
      addTearDown(schoolSearchContainer.dispose);

      await http.runWithClient(() async {
        // 1. School search — also exercises requestSchoolList's parser.
        final schools = await schoolSearchContainer.read(requestSchoolListProvider(credential.schoolSearch).future);
        expect(schools, isNotEmpty, reason: 'schoolsearch returned no match for "${credential.schoolSearch}"');
        stdout.writeln(
          '  [${log.last.statusCode}] ${log.last.requestLabel} — school search: found ${schools.length}',
        );
        final school = schools.firstWhere(
          (s) => s.loginName == credential.schoolSearch,
          orElse: () => schools.first,
        );

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
            stdout.writeln('  [${log.last.statusCode}] ${log.last.requestLabel} — app-shared-secret: OK');
            userData = await requestUserData(
              school,
              AuthParams.credentials(user: credential.username!, appSharedSecret: appSharedSecret),
            );
          case LoginMode.ssoKey:
            appSharedSecret = credential.key;
            userData = await requestUserData(
              school,
              AuthParams.credentials(user: credential.username!, appSharedSecret: appSharedSecret!),
            );
          case LoginMode.anonymous:
            userData = await requestUserData(school, const AuthParams.anonymous());
        }
        // getUserData2017's raw body was the *last* RPC exchange right above.
        // requestUserData() (see request_user_data.dart) only ever hands UserData
        // the RPC envelope's `result` — diff against that, not the whole envelope,
        // or `jsonrpc`/`id`/`result` show up as false-positive "unparsed" fields.
        final userDataRaw = jsonDecode(log.last.responseBody);
        checkParity(
          'userData',
          userDataRaw is Map ? userDataRaw['result'] : userDataRaw,
          userData,
          knownGaps: userDataKnownGaps,
        );

        final session = UntisSession.active(
          school,
          credential.loginMode,
          credential.username,
          null,
          appSharedSecret,
          userData,
        ) as ActiveUntisSession;

        // 3. mobile/data.
        await section('mobile/data', (container) async {
          final mobileData = await container.read(requestMobileDataProvider(session).future);
          checkParity('mobile/data', jsonDecode(log.last.responseBody), mobileData);
        });

        // 4. Messages list, then — the case that matters most — the detail of
        //    *every* message returned. Content is the most heterogeneous data in the
        //    API, so this is the most likely place to catch a field the server added
        //    that SpecifiedMessage doesn't know about yet.
        //
        //    Skipped for anonymous accounts: confirmed (via live testing against
        //    bs-gfv) that the server returns 403 Forbidden for anonymous sessions on
        //    both the list and detail endpoints — a genuine, permanent authorization
        //    boundary, not a bug. RequestMessages/RequestSpecifiedMessage now assert
        //    against being called with an anonymous session, so calling them here
        //    would just trip that assert instead of exercising anything new.
        if (credential.loginMode == LoginMode.anonymous) {
          stdout.writeln('  – messages: skipped (not available for anonymous sessions)');
        } else {
          await section('messages', (container) async {
            final messages = await container.read(requestMessagesProvider(session).future);
            checkParity(
              'messages list (${messages.incomingMessages.length} messages)',
              jsonDecode(log.last.responseBody),
              messages,
            );

            for (final message in messages.incomingMessages) {
              await section('message ${message.id} detail', (container) async {
                final detail = await container.read(
                  requestSpecifiedMessageProvider(session, message.id).future,
                );
                checkParity('message ${message.id} detail', jsonDecode(log.last.responseBody), detail);
              });
            }
          });
        }

        // 5 & 6 need a resource (elemType/id) to ask the server for a timetable or
        // exams against. Some anonymous accounts (confirmed live against bs-gfv) come
        // back from getUserData2017 with a null elemType/id — the server has no
        // resource on file for them — which is a genuine, permanent per-account data
        // gap, not a bug: request_timetable_entries.dart already guards this
        // client-side with a clear StateError, and getExams2017 just hangs
        // server-side when asked with a null/-1 id instead of erroring. Skip both
        // sections rather than let either show up as a "problem".
        final hasTimetableResource = session.userData.type != null;

        // 5. Timetable entries, current week +/- 1.
        if (!hasTimetableResource) {
          stdout.writeln('  – timetable entries: skipped (userData.elemType is null for this session)');
        } else {
          for (final relative in [-1, 0, 1]) {
            final week = Week.relative(relative);
            await section('timetable entries ($week)', (container) async {
              await container.read(requestTimetableEntriesProvider(session, week).future);
              if (log.last.statusCode == 200) {
                // TimetableEntriesResponse isn't exposed by the provider (it returns
                // a day-keyed Map) — re-decode raw against the day list shape by
                // re-parsing the same JSON through the model directly.
                final raw = jsonDecode(log.last.responseBody);
                final reparsed = TimetableEntriesResponse.fromJson(raw as Map<String, dynamic>);
                checkParity('timetable entries ($week)', raw, reparsed, knownGaps: timetableEntriesKnownGaps);
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
        }

        // 6. Exams, current week.
        if (!hasTimetableResource) {
          stdout.writeln('  – exams: skipped (userData.elemType is null for this session)');
        } else {
          await section('exams', (container) async {
            await container.read(requestExamsProvider(session, Week.now()).future);
            // getExams2017's raw envelope's `result` (not the whole envelope) is what
            // Exam.fromJson consumes per-item; spot-check the envelope shape itself
            // isn't silently missing top-level keys.
            final raw = jsonDecode(log.last.responseBody);
            if (raw is Map && raw['result'] is Map) {
              final examsRaw = (raw['result'] as Map)['exams'] as List<dynamic>;
              stdout.writeln(
                '  [${log.last.statusCode}] ${log.last.requestLabel} — exams: ${examsRaw.length} exam(s)',
              );
              for (var i = 0; i < examsRaw.length; i++) {
                final examJson = examsRaw[i] as Map<String, dynamic>;
                checkParity('exam[$i]', examJson, Exam.fromJson(examJson));
              }
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
    }, timeout: const Timeout(Duration(minutes: 3)));
  }
}
