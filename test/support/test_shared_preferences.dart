import 'package:shared_preferences/shared_preferences.dart';
import 'package:your_schedule/util/shared_preferences.dart';

bool _initialized = false;

/// Initializes the app's global [sharedPreferences] against an in-memory fake.
///
/// Needed by any test that reads a `request*` provider using the "live vs. cached"
/// pattern (see CLAUDE.md) — those write to [sharedPreferences] as a side effect via
/// `listenSelf`, which otherwise throws `LateInitializationError` outside a real app
/// bootstrap (normally done once in `main()`). Safe to call more than once per test
/// file/isolate — [sharedPreferences] is a `late final`, so only the first call
/// actually initializes it.
Future<void> initTestSharedPreferences() async {
  if (_initialized) {
    return;
  }
  SharedPreferences.setMockInitialValues({});
  await initSharedPreferences();
  _initialized = true;
}
