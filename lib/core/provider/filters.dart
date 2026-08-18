import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/logger.dart';
import 'package:your_schedule/util/shared_preferences.dart';

part 'filters.g.dart';

/// Per-course visibility overrides, keyed by timetable resource then by `courseKey`.
/// A course with no override for its resource is visible by default — only
/// explicitly-hidden (`false`) courses are filtered out; see
/// [courseOverridesForResourceProvider]. Stored as per-course overrides (rather than
/// a resource-wide allow-list) so a single course can be hidden/shown (e.g. the
/// "Kurs ausblenden" quick action in `grid_entry_widget.dart`) without needing to
/// know every other course on that timetable.
@riverpod
class Filters extends _$Filters {
  late final int _userId;

  @override
  Map<String, Map<String, bool>> build() {
    if (ref.watch(untisSessionsProvider.select((value) => value.isEmpty || value.first is InactiveUntisSession))) {
      return {};
    }

    _userId = ref.watch(selectedUntisSessionProvider.select((value) => (value as ActiveUntisSession).userData.id));

    try {
      return initializeFromPrefs();
    } catch (e, s) {
      Sentry.captureException(e, stackTrace: s);
      getLogger().e('Error while parsing json', error: e, stackTrace: s);
    }
    return {};
  }

  void setOverride(String resourceKey, String courseKey, bool visible) {
    final resourceOverrides = Map<String, bool>.of(state[resourceKey] ?? const <String, bool>{});
    resourceOverrides[courseKey] = visible;
    final next = Map<String, Map<String, bool>>.of(state);
    next[resourceKey] = Map<String, bool>.unmodifiable(resourceOverrides);
    state = Map.unmodifiable(next);
    saveToPrefs();
  }

  void setOverridesForResource(String resourceKey, Map<String, bool> overrides) {
    final next = Map<String, Map<String, bool>>.of(state);
    next[resourceKey] = Map<String, bool>.unmodifiable(overrides);
    state = Map.unmodifiable(next);
    saveToPrefs();
  }

  void reset() {
    state = const <String, Map<String, bool>>{};
    saveToPrefs();
  }

  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_userId.course_filters_by_resource', jsonEncode(state));
  }

  Map<String, Map<String, bool>> initializeFromPrefs() {
    final filters = sharedPreferences.getString('$_userId.course_filters_by_resource');
    if (filters == null) {
      return {};
    }
    final json = jsonDecode(filters) as Map<String, dynamic>;
    final result = <String, Map<String, bool>>{};
    for (final entry in json.entries) {
      final overrides = entry.value as Map<String, dynamic>;
      result[entry.key] = Map<String, bool>.unmodifiable(overrides.map((k, v) => MapEntry(k, v as bool)));
    }
    return Map.unmodifiable(result);
  }
}

/// [resource]'s per-course visibility overrides — courses not present here are
/// visible by default; only explicit `false` entries hide a course. Home-screen
/// views and `CourseCustomizationScreen` should both resolve "is this course
/// visible" via `overrides[courseKey] ?? true`.
@riverpod
Map<String, bool> courseOverridesForResource(Ref ref, TimetableResourceRef resource) {
  return ref.watch(filtersProvider)[resource.storageKey] ?? const {};
}
