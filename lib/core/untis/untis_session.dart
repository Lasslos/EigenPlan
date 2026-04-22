import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/rpc_request/rpc.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/logger.dart';

part 'untis_session.freezed.dart';
part 'untis_session.g.dart';

@freezed
sealed class UntisSession with _$UntisSession {
  const factory UntisSession.active(
      School school,
      String username,
      String password,
      String appSharedSecret,
      @JsonKey(defaultValue: false) bool passwordIsAppSharedSecret,
      UserData userData,
      ) = ActiveUntisSession;

  const factory UntisSession.inactive({
    required School school,
    required String username,
    required String password,
  }) = InactiveUntisSession;

  factory UntisSession.fromJson(Map<String, dynamic> json) => _$UntisSessionFromJson(json);
}

Future<ActiveUntisSession> activateSession(WidgetRef ref, UntisSession session, {String token = ""}) async {
  String appSharedSecret;
  bool passwordIsAppSharedSecret = false;
  UserData? userData;

  try {
    appSharedSecret = await requestAppSharedSecret(session, token: token);
  } on RPCError catch (e, s) {
    if (e.code == RPCError.authenticationFailed || e.code == RPCError.userLocked) {
      // Maybe, password is secret? This is the case in QR-Codes, for example.
      getLogger().i("Trying password as key");
      try {
        userData = await requestUserData(session, session.password);
      } catch (_) {
        // Didn't work. Throw e.
        logRequestError("Error while requesting session data", e, s);
        throw e;
      }
      // It worked! Set the variables to it.
      appSharedSecret = session.password;
      passwordIsAppSharedSecret = true;
    } else {
      rethrow;
    }
  } catch (e, s) {
    logRequestError("Error while requesting session data", e, s);
    rethrow;
  }

  if (userData == null) {
    try {
      userData = await requestUserData(session, appSharedSecret);
    } catch (e, s) {
      logRequestError("Error while requesting session data", e, s);
      rethrow;
    }
  }

  var activeSession = UntisSession.active(
    session.school,
    session.username,
    session.password,
    appSharedSecret,
    passwordIsAppSharedSecret,
    userData,
  ) as ActiveUntisSession;
  ref.read(untisSessionsProvider.notifier).updateSession(session, activeSession);
  ref.read(authTokenProvider(activeSession, appSharedSecret, oneTimePassword: token).future).ignore();
  return activeSession;
}

Future<ActiveUntisSession> refreshSession(WidgetRef ref, ActiveUntisSession session) async {
  UserData userData;
  try {
    userData = await requestUserData(session, session.appSharedSecret);
  } catch (e, s) {
    logRequestError("Error while requesting session data", e, s);
    rethrow;
  }
  var refreshedSession = session.copyWith(userData: userData);
  ref.read(untisSessionsProvider.notifier).updateSession(
    session,
    refreshedSession,
  );
  return refreshedSession;
}
