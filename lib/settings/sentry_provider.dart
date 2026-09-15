import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:your_schedule/util/logger.dart';
import 'package:your_schedule/util/shared_preferences.dart';

part 'sentry_provider.g.dart';

@Riverpod(keepAlive: true)
class SentrySettings extends _$SentrySettings {
  @override
  bool? build() {
    return sharedPreferences.getBool('sentryEnabled');
  }

  Future<void> setSentryEnabled(bool enabled) async {
    getLogger().d('Sentry consent changed to: $enabled');
    await sharedPreferences.setBool('sentryEnabled', enabled);
    enabled ? await enableSentry() : await disableSentry();
    state = enabled;
  }
}

Future<void> enableSentry() async {
  if (Sentry.isEnabled) {
    return;
  }

  await SentryFlutter.init((options) {
      options
        ..dsn = 'https://1be6b663150041f6be6a7a4375e5599f@o4504990166155264.ingest.sentry.io/4504990173167616'
        ..tracesSampleRate = 0.2
        ..debug = false
        ..beforeSend = (event, hint) {
          if (sharedPreferences.getBool('sentryEnabled') != true) {
            return null;
          }
          return event;
        };
    },
  );
}

Future<void> disableSentry() async {
  if (!Sentry.isEnabled) {
    return;
  }
  await Sentry.close();
}
