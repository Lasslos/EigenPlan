import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/rpc_request/rpc.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/logger.dart';

part 'untis_session.freezed.dart';
part 'untis_session.g.dart';

/// How a session authenticates, driven by [LoginMeta] at login time.
enum LoginMode {
  /// Normal username + password login. Exchanges the password for an
  /// app-shared-secret via `getAppSharedSecret`, then never touches the raw
  /// password again.
  password,

  /// SSO/key-based login (e.g. `schuldorf`): the stored secret already *is* the
  /// app-shared-secret (scanned from a QR code, or pasted in by hand). `getAppSharedSecret`
  /// is never called.
  ssoKey,

  /// Anonymous login (e.g. `bs-gfv`): no credentials at all. The JSON-RPC `auth`
  /// object is always the fixed sentinel `{user: "#anonymous#", otp: 0}`.
  anonymous,
}

@freezed
sealed class UntisSession with _$UntisSession {
  const factory UntisSession.active(
    School school,
    LoginMode loginMode,
    String? username,
    String? password,
    String? appSharedSecret,
    UserData userData,
  ) = ActiveUntisSession;

  const factory UntisSession.inactive({
    required School school,
    required LoginMode loginMode,
    String? username,
    String? password,
  }) = InactiveUntisSession;

  const UntisSession._();

  /// Display label for UI (drawer, account switcher). Anonymous sessions have no
  /// username to show, and the server's own `getUserData2017` placeholder for them
  /// (`IDC_ANONYMOUSUSER`) is an untranslated i18n key, not fit for display.
  String get displayLabel => switch (loginMode) {
        LoginMode.anonymous => 'Anonym',
        LoginMode.password || LoginMode.ssoKey => username ?? school.displayName,
      };

  factory UntisSession.fromJson(Map<String, dynamic> json) => _$UntisSessionFromJson(json);
}

extension ActiveUntisSessionAuthParams on ActiveUntisSession {
  /// The [AuthParams] to send on every authenticated request for this session.
  AuthParams get authParams => switch (loginMode) {
        LoginMode.anonymous => const AuthParams.anonymous(),
        LoginMode.password || LoginMode.ssoKey =>
          AuthParams.credentials(user: username!, appSharedSecret: appSharedSecret!),
      };
}

/// Activates [session], obtaining an app-shared-secret (where applicable) and the
/// user's master data. [token] is only used for the [LoginMode.password] flow, when
/// the school requires a 2FA token alongside the password.
Future<ActiveUntisSession> activateSession(WidgetRef ref, UntisSession session, {String token = ''}) async {
  String? appSharedSecret;
  UserData userData;

  try {
    switch (session.loginMode) {
      case LoginMode.password:
        appSharedSecret = await requestAppSharedSecret(
          session.school,
          session.username!,
          session.password!,
          token: token,
        );
        userData = await requestUserData(
          session.school,
          AuthParams.credentials(user: session.username!, appSharedSecret: appSharedSecret),
        );
      case LoginMode.ssoKey:
        appSharedSecret = session.password;
        userData = await requestUserData(
          session.school,
          AuthParams.credentials(user: session.username!, appSharedSecret: appSharedSecret!),
        );
      case LoginMode.anonymous:
        userData = await requestUserData(session.school, const AuthParams.anonymous());
    }
  } catch (e, s) {
    logRequestError('Error while requesting session data', e, s);
    rethrow;
  }

  var activeSession = UntisSession.active(
    session.school,
    session.loginMode,
    session.username,
    session.password,
    appSharedSecret,
    userData,
  ) as ActiveUntisSession;
  ref.read(untisSessionsProvider.notifier).updateSession(session, activeSession);
  return activeSession;
}

/// Activates a session for [username]/[password], trying [LoginMode.password] first
/// and automatically retrying the exact same entered value as [LoginMode.ssoKey] if
/// it's specifically rejected as bad credentials — instead of asking the user to
/// pick up front.
///
/// This is *not* gated on `login-meta`'s `ssoLoginEnabled`. A login key is a manual
/// workaround for a specific user (e.g. handed a key/QR code directly), independent
/// of whether the school broadly has SSO configured — a school with SSO disabled
/// can still have a user logging in with a key, so login-meta can't be used to rule
/// the fallback out. Only failures that specifically mean "these credentials are
/// wrong" (`authenticationFailed`/`userLocked`) trigger the retry; a wrong 2FA
/// token, no connection, etc. propagate immediately rather than triggering a
/// pointless retry.
Future<ActiveUntisSession> activateSessionInferringMode(
  WidgetRef ref,
  School school,
  String username,
  String password, {
  String token = '',
}) async {
  var passwordSession = UntisSession.inactive(
    school: school,
    loginMode: LoginMode.password,
    username: username,
    password: password,
  );

  try {
    return await activateSession(ref, passwordSession, token: token);
  } on RPCError catch (e) {
    if (e.code != RPCError.authenticationFailed && e.code != RPCError.userLocked) {
      rethrow;
    }
    getLogger().i('Password login failed, retrying the same value as a login key');
    var ssoKeySession = UntisSession.inactive(
      school: school,
      loginMode: LoginMode.ssoKey,
      username: username,
      password: password,
    );
    return activateSession(ref, ssoKeySession);
  }
}

Future<ActiveUntisSession> refreshSession(WidgetRef ref, ActiveUntisSession session) async {
  UserData userData;
  try {
    userData = await requestUserData(session.school, session.authParams);
  } catch (e, s) {
    logRequestError('Error while requesting session data', e, s);
    rethrow;
  }
  var refreshedSession = session.copyWith(userData: userData);
  ref.read(untisSessionsProvider.notifier).updateSession(
    session,
    refreshedSession,
  );
  return refreshedSession;
}
