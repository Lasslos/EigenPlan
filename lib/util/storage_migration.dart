import 'package:your_schedule/util/secure_storage_util.dart';
import 'package:your_schedule/util/shared_preferences.dart';

/// Bump this whenever a persisted model's shape changes in a breaking way (a new
/// required field, a renamed/removed field — anything that would otherwise crash
/// `fromJson` on old stored data, like [UntisSession] gaining `loginMode`).
///
/// This app has no real migration requirements yet (actively being rewritten, and
/// stored data like the timetable cache is inherently tied to a school year anyway),
/// so on a version mismatch this just wipes storage instead of writing bespoke
/// per-field migrations — except custom subject colors, which are cheap to keep and
/// annoying for a user to lose.
const currentStorageSchemaVersion = 1;

const _schemaVersionKey = 'storageSchemaVersion';

Future<void> migrateStorageIfNeeded() async {
  if (sharedPreferences.getInt(_schemaVersionKey) == currentStorageSchemaVersion) {
    return;
  }

  for (final key in sharedPreferences.getKeys()) {
    if (key.endsWith('.custom_subject_colors')) {
      continue;
    }
    await sharedPreferences.remove(key);
  }
  await secureStorage.deleteAll();
  await sharedPreferences.setInt(_schemaVersionKey, currentStorageSchemaVersion);
}
