import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/custom_subject_color/custom_subject_color.dart';
import 'package:your_schedule/util/logger.dart';

part 'custom_subject_colors.g.dart';

@riverpod
class CustomSubjectColors extends _$CustomSubjectColors {
  late int _userId;

  @override
  Map<int, CustomSubjectColor> build() {
    if (ref.watch(untisSessionsProvider.select((value) => value.isEmpty || value.first is InactiveUntisSession))) {
      return {};
    }
    _userId = ref.watch(selectedUntisSessionProvider.select((value) => (value as ActiveUntisSession).userData.id));

    try {
      initializeFromPrefs();
    } catch (e, s) {
      Sentry.captureException(e, stackTrace: s);
      getLogger().e('Error while parsing json', error: e, stackTrace: s);
    }
    return {};
  }

  void add(CustomSubjectColor color) {
    state = Map.unmodifiable(Map.from(state)..addAll({color.subjectId: color}));
    saveToPrefs();
  }

  void addAll(Map<int, CustomSubjectColor> colors) {
    state = Map.unmodifiable(Map.from(state)..addAll(colors));
    saveToPrefs();
  }

  void remove(int id) {
    state = Map.unmodifiable(Map.from(state)..remove(id));
    saveToPrefs();
  }

  void reset() {
    state = Map.unmodifiable({});
    saveToPrefs();
  }

  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_userId.custom_subject_colors',
      jsonEncode(
        state.values.map((e) => e.toJson()).toList(),
      ),
    );
  }

  Future<void> initializeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final customSubjectColors = prefs.getString('$_userId.custom_subject_colors');
    if (customSubjectColors != null) {
      state = Map.unmodifiable({
        for (var e in jsonDecode(customSubjectColors) as List) e['subjectId'] as int: CustomSubjectColor.fromJson(e),
      });
    }
  }
}
