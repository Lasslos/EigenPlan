import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:http/http.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/rpc_request/rpc.dart';
import 'package:your_schedule/core/untis/untis_session.dart';
import 'package:your_schedule/settings/sentry_provider.dart';
import 'package:your_schedule/util/logger.dart';
import 'package:your_schedule/util/shared_preferences.dart';
import 'package:your_schedule/util/storage_migration.dart';

part 'initialization.g.dart';

Future<void> initializeApp() async {
  getLogger().i('Initializing started');
  // Ensure that plugin services are initialized so that `SharedPreferences` can be used before `runApp()`
  var widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Keep splash screen visible while Flutter engine is initializing
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Date formatting
  Intl.defaultLocale = 'de';
  await initializeDateFormatting('de_DE', null);

  // Shared Preferences
  await initSharedPreferences();

  // Wipe storage on a breaking persisted-model shape change (see storage_migration.dart) —
  // must run before loadSessionsFromDisk, which would otherwise crash trying to parse
  // old-shaped session data.
  await migrateStorageIfNeeded();

  // Session list (school/userData from SharedPreferences, credentials from secure storage)
  await loadSessionsFromDisk();

  // Enable sentry if consent is given
  if (sharedPreferences.getBool('sentryEnabled') == true) {
    await enableSentry();
  }
}

enum StartupDestination { login, home }

class StartupFailure implements Exception {
  const StartupFailure(this.message, [this.details]);
  final String message;
  final String? details;
}

@riverpod
Future<StartupDestination> appStartup(Ref ref) async {
  getLogger().i('App startup started');

  final sessions = ref.read(untisSessionsProvider);
  if (sessions.isEmpty) {
    getLogger().i('No sessions found, navigating to login screen');
    return StartupDestination.login;
  }

  final connectivity = await Connectivity().checkConnectivity();
  bool canMakeRequest = !connectivity.contains(ConnectivityResult.none);
  getLogger().d('Connectivity: $connectivity, canMakeRequest: $canMakeRequest');

  if (!canMakeRequest) {
    getLogger().i('Offline, using cached data');
    getLogger().i('Navigating to home screen');
    return StartupDestination.home;
  }

  try {
    getLogger().i('Refreshing session');
    final newSession = await refreshSession(sessions[0] as ActiveUntisSession);
    ref.read(untisSessionsProvider.notifier).updateSession(sessions[0], newSession);
  } on RPCError catch (e, s) {
    await _handleRPCError(ref, sessions, e, s);
  } on (SocketException, TimeoutException, ClientException) {
    getLogger().w('No internet connection, using cached data');
  }
  return StartupDestination.home;
}

Future<void> _handleRPCError(
  Ref ref, List<UntisSession> sessions, RPCError e, StackTrace s,
) async {
  switch (e.code) {
    case RPCError.invalidClientTime:
      throw const StartupFailure(
        'Die Zeit deines Geräts ist nicht korrekt. Bitte stelle sie richtig ein.',
      );
    case RPCError.authenticationFailed:
      final session = sessions.first;
      if (session.loginMode == LoginMode.anonymous) {
        throw const StartupFailure(
          'Deine Sitzung ist nicht mehr gültig. Bitte melde dich erneut an.',
        );
      }
      getLogger().w('Bad credentials, reauthenticating');
      final newSession = UntisSession.inactive(
        loginMode: session.loginMode,
        username: session.username,
        password: session.password,
        school: session.school,
      );
      try {
        final activated = await activateSession(newSession);
        ref.read(untisSessionsProvider.notifier).updateSession(session, activated);
        getLogger().i('Reauthenticated');
      } on RPCError catch (e) {
        throw StartupFailure(
          e.code == RPCError.authenticationFailed
              ? 'Deine Anmeldedaten sind nicht mehr gültig. Bitte melde dich erneut an.'
              : 'Ein unbekannter Fehler ist aufgetreten.',
          e.toString(),
        );
      }
    default:
      throw StartupFailure('Ein unbekannter Fehler ist aufgetreten.', e.toString());
  }
}
