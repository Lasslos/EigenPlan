import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/shared_preferences.dart';
import 'package:your_schedule/utils.dart';

part 'cached_exams.g.dart';

@Riverpod(keepAlive: true)
class CachedExams extends _$CachedExams {
  @override
  Map<Date, List<Exam>> build(UntisSession activeSession, Week week) {
    assert(activeSession is ActiveUntisSession, 'Session must be active');
    ActiveUntisSession session = activeSession as ActiveUntisSession;
    if (!sharedPreferences.containsKey('${session.userData.id}.exams.$week')) {
      return {
        for (var i = 0; i < 7; i++) week.startDate.addDays(i): const <Exam>[],
      };
    }

    final json = jsonDecode(sharedPreferences.getString('${session.userData.id}.exams.$week')!);

    return {
      for (var entry in json.entries) Date.fromMillisecondsSinceEpoch(int.parse(entry.key)): entry.value.map<Exam>((e) => Exam.fromJson(e)).toList(),
    };
  }

  Future<void> setCachedExams(Map<Date, List<Exam>> exams) async {
    Map<String, dynamic> json = {
      for (var entry in exams.entries) entry.key.millisecondsSinceEpoch.toString(): entry.value.map((e) => e.toJson()).toList(),
    };
    await sharedPreferences.setString('${(activeSession as ActiveUntisSession).userData.id}.exams.$week', jsonEncode(json));
    state = exams;
  }
}
