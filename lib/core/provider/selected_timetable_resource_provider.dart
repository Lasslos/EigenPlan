import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/logger.dart';
import 'package:your_schedule/util/shared_preferences.dart';

part 'selected_timetable_resource_provider.g.dart';

/// Which timetable is currently displayed — `null` for the session owner's own
/// timetable (the default, and the only thing shown before the "switch timetable"
/// picker existed), a specific [TimetableResourceRef] once the user picks something
/// else via the picker. Persisted per-user like [Filters], since it's scoped to
/// whichever session is currently active rather than being a session-agnostic app
/// setting (see `lib/settings/` for those).
@riverpod
class SelectedTimetableResource extends _$SelectedTimetableResource {
  late final int _userId;

  @override
  TimetableResourceRef? build() {
    if (ref.watch(
      untisSessionsProvider.select(
        (value) => value.isEmpty || value.first is InactiveUntisSession,
      ),
    )) {
      return null;
    }

    _userId = ref.watch(
      selectedUntisSessionProvider.select(
        (value) => (value as ActiveUntisSession).userData.id,
      ),
    );

    try {
      final json = sharedPreferences.getString(
        '$_userId.selectedTimetableResource',
      );
      if (json == null) {
        return null;
      }
      return TimetableResourceRef.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
    } catch (e, s) {
      Sentry.captureException(e, stackTrace: s);
      getLogger().e(
        'Error while parsing selected timetable resource',
        error: e,
        stackTrace: s,
      );
    }
    return null;
  }

  Future<void> select(TimetableResourceRef resource) async {
    state = resource;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_userId.selectedTimetableResource',
      jsonEncode(resource.toJson()),
    );
  }

  Future<void> resetToOwn() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_userId.selectedTimetableResource');
  }
}

/// [SelectedTimetableResource], resolved: the picked resource if one was picked,
/// otherwise [session]'s own resource — `null` only for the rare case where the
/// session itself has no timetable resource at all (`userData.type` is null, e.g.
/// some anonymous accounts; see [TimetableResourceRef.own]). Call sites that need
/// "whichever timetable should be shown right now" should watch this rather than
/// [selectedTimetableResourceProvider] directly.
@riverpod
TimetableResourceRef? effectiveTimetableResource(
  Ref ref,
  UntisSession session,
) {
  assert(session is ActiveUntisSession, 'Session must be active');
  final selected = ref.watch(selectedTimetableResourceProvider);
  return selected ?? TimetableResourceRef.own(session as ActiveUntisSession);
}
