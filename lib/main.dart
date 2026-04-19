// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:your_schedule/core/provider/connectivity_provider.dart';
import 'package:your_schedule/core/provider/filters.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/rpc_request/rpc.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/settings/sentry_provider.dart';
import 'package:your_schedule/settings/theme_provider.dart';
import 'package:your_schedule/ui/screens/filter_screen/filter_screen.dart';
import 'package:your_schedule/ui/screens/home_screen/home_screen.dart';
import 'package:your_schedule/ui/screens/loading_screen/loading_error_screen.dart';
import 'package:your_schedule/ui/screens/login_screen/welcome_screen.dart';
import 'package:your_schedule/util/logger.dart';
import 'package:your_schedule/util/shared_preferences.dart';

void main() async {
  await _initializeApp();
  await SentryFlutter.init(
    (options) {
      options
        ..dsn = 'https://1be6b663150041f6be6a7a4375e5599f@o4504990166155264.ingest.sentry.io/4504990173167616'
        ..tracesSampleRate = 1.0
        ..debug = true //TODO
        ..beforeSend = (event, hint) {
          if (sharedPreferences.getBool("sentryEnabled") != true) {
            return null;
          }
          return event;
        };
    },
    appRunner: () => runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    ),
  );
}

Future<void> _initializeApp() async {
  getLogger().i("Initializing started");
  // Ensure that plugin services are initialized so that `SharedPreferences` can be used before `runApp()`
  var widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Keep splash screen visible while Flutter engine is initializing
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Date formatting
  Intl.defaultLocale = 'de';
  initializeDateFormatting('de_DE', null);

  // Shared Preferences
  await initSharedPreferences();


  // periodic background fetching is not supported on IOS due to battery saving restrictions
  //  a workaround would be to use an external push service, but that would require the users to
  //  transfer their passwords to a third party service, which is not acceptable.
  //  Maybe someone will find a better solution in the future. It would be possible to provide a
  //  self-hosted solution per school, but that's some unlikely idea for the future.
  /* ToDo: Add notifications
  if (!kIsWeb && Platform.isAndroid) {
    PermissionStatus? notificationsPermissionStatus;

    await Permission.notification.isDenied.then((value) async {
      if (value) {
        notificationsPermissionStatus = await Permission.notification.request();
      }
    });
    getLogger().i("Notifications permission status: $notificationsPermissionStatus");
    //ToDo: Implement settings for notifications
    bool enableNotifications = true;
    int notificationInterval = 15;

    await Workmanager().cancelAll();
    if (enableNotifications && (notificationsPermissionStatus ?? PermissionStatus.granted).isGranted) {
      await Workmanager().initialize(background.callbackDispatcher, isInDebugMode: kDebugMode);
      await Workmanager().registerPeriodicTask(
          "",
          "",
          frequency: Duration(minutes: notificationInterval),
      );
    }
  }*/

}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var theme = ref.watch(themeSettingProvider);
    return MaterialApp(
      title: 'EigenPlan',
      home: const Initializer(),
      theme: ThemeData(
        colorSchemeSeed: Colors.lightBlue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.lightBlue,
        brightness: Brightness.dark,
      ),
      themeMode: theme,
    );
  }
}

class Initializer extends ConsumerStatefulWidget {
  const Initializer({super.key});

  @override
  ConsumerState createState() => _InitializerState();
}

class _InitializerState extends ConsumerState<Initializer> {
  late Future<List<ConnectivityResult>> connectivity;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _postFrameInitialization().onError((e, s) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) {
              return LoadingErrorScreen(message: "Ein unbekannter Fehler ist aufgetreten.\n"
                  "Bitte logge dich erneut ein!", error: e.toString());
            },
          ),
        );
        FlutterNativeSplash.remove();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    connectivity = ref.watch(connectivityProvider.future);
    return Container();
  }

  Future<void> _postFrameInitialization() async {
    getLogger().i("Post frame initialization started");

    // Find sessions
    List<UntisSession> sessions = ref.read(untisSessionsProvider);

    // If there are no sessions, navigate to login screen
    if (sessions.isEmpty) {
      getLogger().i("No sessions found, navigating to login screen");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const WelcomeScreen(),
        ),
      );
    } else {
      // Try to refresh the session

      List<ConnectivityResult> connectivity = await Connectivity().checkConnectivity();
      bool canMakeRequest = !connectivity.contains(ConnectivityResult.none);

      if (canMakeRequest) {
        getLogger().i("Refreshing session");
        bool shouldContinue = await _refreshSession(sessions);
        if (!shouldContinue) {
          return;
        }
      } else {
        getLogger().i("Can't make request, navigating to home screen");
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
      // If there is a session and the filters are empty, navigate to filter screen
      var filters = ref.read(filtersProvider);
      if (filters.isEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FilterScreen()),
        );
      }
    }

    // Remove splash screen
    FlutterNativeSplash.remove();

    // Check if dialog should be shown
    bool? sentryEnabled = ref.read(sentrySettingsProvider);
    if (sentryEnabled == null) {
      await showDialog(
        context: context,
        builder: (context) {
          return Consumer(
            builder: (context, ref, child) {
              return AlertDialog(
                title: const Text("Fehlerberichte senden?"),
                content: const Text("EigenPlan wird kontinuierlich verbessert. Wir verwenden Sentry, um Fehlerberichte zu sammeln. "
                    "Fehlerberichte helfen uns dabei, Probleme zu erkennen und zu beheben. Dafür benötigen wir jedoch deine Zustimmung. "
                    "Du kannst deine Zustimmung jederzeit in den Einstellungen wiederrufen. Die Einstellung wird mit einem App-Neustart aktiv. Möchtest du Fehlerberichte senden?"),
                actions: [
                  TextButton(
                    onPressed: () {
                      ref.read(sentrySettingsProvider.notifier).setSentryEnabled(true);
                      Navigator.pop(context);
                    },
                    child: const Text("Ja"),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(sentrySettingsProvider.notifier).setSentryEnabled(false);
                      Navigator.pop(context);
                    },
                    child: const Text("Nein"),
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }

//Returns true if successful and initialization should continue
  Future<bool> _refreshSession(List<UntisSession> sessions) async {
    // Refreshing session, error handling
    try {
      await refreshSession(ref, sessions[0] as ActiveUntisSession);
    } on RPCError catch (e, s) {
      bool shouldContinue = await _onRPCError(sessions, e, s);
      if (!shouldContinue) {
        return false;
      }
    } on (SocketException, TimeoutException) {
      getLogger().w("No internet connection, using cached data");
    } catch (e, s) {
      await Sentry.captureException(e, stackTrace: s);
      getLogger().e("Error while refreshing session", error: e, stackTrace: s);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) {
            return LoadingErrorScreen(message: "Es ist ein unbekannter Fehler aufgetreten", error: e.toString());
          },
        ),
      );
      return false;
    }
    return true;
  }

//Returns true if the error was handled and initialization should continue
  Future<bool> _onRPCError(List<UntisSession> sessions, RPCError e, StackTrace s) async {
    switch (e.code) {
      case RPCError.invalidClientTime:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) {
              return const LoadingErrorScreen(message: "Die Zeit deines Geräts ist nicht korrekt. Bitte stelle sie richtig ein.");
            },
          ),
        );
        return false;
      case RPCError.authenticationFailed:
        getLogger().w("Bad credentials, reauthenticating");
        var session = sessions.first;
        var newSession = UntisSession.inactive(
          username: session.username,
          password: session.password,
          school: session.school,
        );
        try {
          //Trying to reauthenticate
          ref.read(untisSessionsProvider.notifier).updateSession(session, await activateSession(ref, newSession));
          getLogger().i("Reauthenticated");
          return true;
        } on RPCError catch (e) {
          //Reauthentication failed, deleting session
          if (e.code == RPCError.authenticationFailed) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return const LoadingErrorScreen(message: "Deine Anmeldedaten sind nicht mehr gültig. Bitte melde dich erneut an.");
                },
              ),
            );
          }
          return false;
        } catch (e) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) {
                return LoadingErrorScreen(message: "Während der Reauthentifizierung ist ein unbekannter Fehler aufgetreten.", error: e.toString());
              },
            ),
          );
          return false;
        }
      default:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) {
              return LoadingErrorScreen(message: "Ein unbekannter Fehler ist aufgetreten.", error: e.toString());
            },
          ),
        );
        return false;
    }
  }
}
