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
  Map<String, CustomSubjectColor> build() {
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
    state = Map.unmodifiable(Map.from(state)..addAll({color.courseKey: color}));
    saveToPrefs();
  }

  void addAll(Map<String, CustomSubjectColor> colors) {
    state = Map.unmodifiable(Map.from(state)..addAll(colors));
    saveToPrefs();
  }

  void remove(String courseKey) {
    state = Map.unmodifiable(Map.from(state)..remove(courseKey));
    saveToPrefs();
  }

  void reset() {
    state = Map.unmodifiable({});
    saveToPrefs();
  }

  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_userId.course_colors',
      jsonEncode(
        state.values.map((e) => e.toJson()).toList(),
      ),
    );
  }

  Future<void> initializeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final customSubjectColors = prefs.getString('$_userId.course_colors');
    if (customSubjectColors != null) {
      state = Map.unmodifiable({
        for (var e in jsonDecode(customSubjectColors) as List)
          e['courseKey'] as String: CustomSubjectColor.fromJson(e),
      });
    }
  }
}
