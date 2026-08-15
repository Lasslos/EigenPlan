import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/logger.dart';
import 'package:your_schedule/util/secure_storage_util.dart';
import 'package:your_schedule/util/shared_preferences.dart';

part 'untis_session_provider.g.dart';

/// Stable per-session key for [secureStorage] entries — school + username (or the
/// anonymous sentinel), which doesn't change across a session's inactive-\>active
/// transition, unlike anything derived from [ActiveUntisSession.userData].
String sessionSecretKey(School school, String? username) => '${school.loginName}::${username ?? '#anonymous#'}';

/// Populated by [loadSessionsFromDisk] during app startup (see `main.dart`'s
/// `_initializeApp`), before [UntisSessionsProvider] is ever read. Secrets
/// (`password`/`appSharedSecret`) live in [secureStorage], not `SharedPreferences`,
/// so hydrating them requires an async read — this lets `UntisSessions.build()` stay
/// synchronous (like every other provider that reads it) by doing that read once,
/// up front, the same way `sharedPreferences` itself is a late-initialized singleton
/// populated before `runApp()`.
List<UntisSession> loadedSessions = [];

Future<void> loadSessionsFromDisk() async {
  final sessionsJson = sharedPreferences.getStringList('sessions');
  if (sessionsJson == null || sessionsJson.isEmpty) {
    loadedSessions = const [];
    return;
  }

  final sessions = <UntisSession>[];
  for (final json in sessionsJson) {
    try {
      var session = UntisSession.fromJson(jsonDecode(json) as Map<String, dynamic>);
      final key = sessionSecretKey(session.school, session.username);
      final password = await secureStorage.read(key: passwordKey(key));
      session = switch (session) {
        InactiveUntisSession() => session.copyWith(password: password),
        ActiveUntisSession() => session.copyWith(
            password: password,
            appSharedSecret: await secureStorage.read(key: appSharedSecretKey(key)),
          ),
      };
      sessions.add(session);
    } catch (e, s) {
      // Old-shaped or otherwise corrupt stored session — should be rare now that
      // migrateStorageIfNeeded wipes storage on a breaking schema-version bump, but
      // one bad entry shouldn't take the whole app down at startup. It's dropped
      // in-memory only; it'll keep failing to parse (harmlessly) until the next
      // schema bump clears it out, or the user re-adds that account.
      getLogger().e('Dropping unparseable stored session', error: e, stackTrace: s);
    }
  }
  loadedSessions = List.unmodifiable(sessions);
}

Future<void> _persistSessions(List<UntisSession> sessions) async {
  final jsonList = <String>[];
  for (final session in sessions) {
    final key = sessionSecretKey(session.school, session.username);
    if (session.password != null) {
      await secureStorage.write(key: passwordKey(key), value: session.password);
    }
    final appSharedSecret = session is ActiveUntisSession ? session.appSharedSecret : null;
    if (appSharedSecret != null) {
      await secureStorage.write(key: appSharedSecretKey(key), value: appSharedSecret);
    }

    // Strip secrets before persisting the rest — only school/loginMode/username/userData
    // (all non-secret) end up in SharedPreferences.
    final stripped = switch (session) {
      InactiveUntisSession() => session.copyWith(password: null),
      ActiveUntisSession() => session.copyWith(password: null, appSharedSecret: null),
    };
    jsonList.add(jsonEncode(stripped.toJson()));
  }
  await sharedPreferences.setStringList('sessions', jsonList);
}

/// The first session is the currently used session.
@Riverpod(keepAlive: true)
class UntisSessions extends _$UntisSessions {
  @override
  List<UntisSession> build() {
    listenSelf((previous, next) {
      if (previous != null && previous != next) {
        _persistSessions(next);
      }
    });
    return loadedSessions;
  }

  void addSession(UntisSession session) {
    state = List.unmodifiable([session, ...state]);
  }

  void removeSession(UntisSession session) {
    state = List.unmodifiable([...state]..remove(session));
  }

  UntisSession? _sessionMarkedForRemoval;

  /// Mark a session for removal. The session will be removed on the next call to removeMarkedSession,
  /// typically called by welcome_screen.dart
  void markSessionForRemoval(UntisSession session) {
    _sessionMarkedForRemoval = session;
    // Remove sessions after small delay
    removeMarkedSession();
    getLogger().i('Removed session!');
  }

  Future<void> removeMarkedSession() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (_sessionMarkedForRemoval != null) {
      removeSession(_sessionMarkedForRemoval!);
      _sessionMarkedForRemoval = null;
    }
  }

  void clearSessions() {
    state = List.unmodifiable([]);
  }

  void updateSession(UntisSession oldSession, UntisSession newSession) {
    //places the new session in the list at the same index as the old session
    //index of session is preserved
    state = List.unmodifiable(
      state.map(
        (e) => e == oldSession ? newSession : e,
      ),
    );
  }

  set currentlyUsedSession(UntisSession session) {
    state = List.unmodifiable([
      session,
      ...[...state]..remove(session),
    ]);
  }
}

@riverpod
UntisSession selectedUntisSession(Ref ref) {
  return ref.watch(untisSessionsProvider.select((value) => value[0]));
}
