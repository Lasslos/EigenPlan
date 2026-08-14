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

@riverpod
class Filters extends _$Filters {
  late final int _userId;

  @override
  Set<int> build() {
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

  void add(int id) {
    state = Set.unmodifiable(Set.from(state)..add(id));
    saveToPrefs();
  }

  void addAll(List<int> ids) {
    state = Set.unmodifiable(Set.from(state)..addAll(ids));
    saveToPrefs();
  }

  void remove(int id) {
    state = Set.unmodifiable(Set.from(state)..remove(id));
    saveToPrefs();
  }

  void reset() {
    state = Set.unmodifiable({});
    saveToPrefs();
  }

  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_userId.filters', jsonEncode(state.toList()));
  }

  Set<int> initializeFromPrefs() {
    final filters = sharedPreferences.getString('$_userId.filters');
    if (filters != null) {
      return Set.unmodifiable(
        (jsonDecode(filters) as List<dynamic>).map((e) => e as int).toSet(),
      );
    }
    return {};
  }
}
