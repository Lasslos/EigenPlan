import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/logger.dart';
import 'package:your_schedule/util/shared_preferences.dart';

part 'untis_session_provider.g.dart';

/// The first session is the currently used session.
@Riverpod(keepAlive: true)
class UntisSessions extends _$UntisSessions {
  @override
  List<UntisSession> build() {
    listenSelf((previous, next) {
      if (previous != null && previous != next) {
        _setCachedSessions(next);
      }
    });
    return _getCachedSessions();
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

  List<UntisSession> _getCachedSessions() {
    final sessions = sharedPreferences.getStringList('sessions');
    if (sessions == null || sessions.isEmpty) {
      return List.unmodifiable([]);
    }
    return List.unmodifiable(
      sessions.map((e) => UntisSession.fromJson(jsonDecode(e))).toList(),
    );
  }

  Future<void> _setCachedSessions(List<UntisSession> sessions) async {
    await sharedPreferences.setStringList(
      'sessions',
      sessions.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }
}

@riverpod
UntisSession selectedUntisSession(Ref ref) {
  return ref.watch(untisSessionsProvider.select((value) => value[0]));
}
