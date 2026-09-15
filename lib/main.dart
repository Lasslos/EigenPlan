import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:your_schedule/core/provider/clock_provider.dart';
import 'package:your_schedule/settings/sentry_provider.dart';
import 'package:your_schedule/settings/theme_provider.dart';
import 'package:your_schedule/ui/screens/loading_screen/loading_error_screen.dart';
import 'package:your_schedule/ui/screens/login_screen/welcome_screen.dart';
import 'package:your_schedule/ui/screens/main_shell/main_shell.dart';
import 'package:your_schedule/util/initialization.dart';


void main() async {
  await initializeApp();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    // Android may freeze the isolate while we're backgrounded, so [currentMinuteProvider]'s
    // own timer can't be trusted to have fired. Re-deriving it here means everything keyed
    // off the clock — countdowns, "Heute"/"Morgen" labels, today's timetable page — is
    // already correct on the first frame the user sees after resuming.
    _lifecycleListener = AppLifecycleListener(
      onResume: () => ref.invalidate(currentMinuteProvider),
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var theme = ref.watch(themeSettingProvider);
    return MaterialApp(
      title: 'EigenPlan',
      home: const ConsentGate(child: Initializer()),
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

class ConsentGate extends ConsumerStatefulWidget {
  const ConsentGate({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<ConsentGate> createState() => _ConsentGateState();
}

class _ConsentGateState extends ConsumerState<ConsentGate> {
  bool _asked = false;

  Future<void> _ask() async {
    _asked = true;
    final consent = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Fehlerberichte senden?'),
          content: const Text('EigenPlan wird kontinuierlich verbessert. Wir verwenden Sentry, um Fehlerberichte zu sammeln. '
              'Fehlerberichte helfen uns dabei, Probleme zu erkennen und zu beheben. Dafür benötigen wir jedoch deine Zustimmung. '
              'Du kannst deine Zustimmung jederzeit in den Einstellungen widerrufen. Möchtest du Fehlerberichte senden?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Ja'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Nein'),
            ),
          ],
        ),
      ),
    );
    await ref.read(sentrySettingsProvider.notifier).setSentryEnabled(consent ?? false);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appStartupProvider, (_, next) {
      if (!_asked && next.hasValue && ref.read(sentrySettingsProvider) == null) {
        _ask();
      }
    });
    return widget.child;
  }
}

class Initializer extends ConsumerWidget {
  const Initializer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(appStartupProvider, (_, next) {
      if (!next.isLoading) {
        FlutterNativeSplash.remove();
      }
    });

    return switch (ref.watch(appStartupProvider)) {
      AsyncLoading() => const Scaffold(),
      AsyncError(:final error) => LoadingErrorScreen(
        message: error is StartupFailure
            ? error.message
            : 'Ein unbekannter Fehler ist aufgetreten.',
        error: error is StartupFailure ? error.details : error.toString(),
      ),
      AsyncValue(:final value) => switch (value!) {
        StartupDestination.login => const WelcomeScreen(),
        StartupDestination.home => const MainShell(),
      },
    };
  }
}
