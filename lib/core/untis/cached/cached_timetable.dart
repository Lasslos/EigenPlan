import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/shared_preferences.dart';
import 'package:your_schedule/utils.dart';

part 'cached_timetable.g.dart';

@Riverpod(keepAlive: true)
class CachedTimeTable extends _$CachedTimeTable {
  @override
  TimeTableWeek build(UntisSession activeSession, Week week) {
    assert(activeSession is ActiveUntisSession, 'Session must be active!');
    ActiveUntisSession session = activeSession as ActiveUntisSession;
    if (!sharedPreferences.containsKey('${session.userData.id}.timetable.$week')) {
      return {
        for (var i = 0; i < 7; i++) week.startDate.addDays(i): const [],
      };
    }

    final json = jsonDecode(
      sharedPreferences.getString('${session.userData.id}.timetable.$week')!,
    );

    return {
      for (var entry in json.entries)
        Date.fromMillisecondsSinceEpoch(int.parse(entry.key)): entry.value.map<TimeTablePeriod>((e) => TimeTablePeriod.fromJson(e)).toList(),
    };
  }

  Future<void> setCachedTimeTable(TimeTableWeek timeTable) async {
    await ref.read(cachedTimeTableTimestampProvider(week).notifier).setCachedTimeTableTimestamp(DateTime.now());

    Map<String, dynamic> json = {
      for (var entry in timeTable.entries) entry.key.millisecondsSinceEpoch.toString(): entry.value.map((e) => e.toJson()).toList(),
    };

    await sharedPreferences.setString(
      '${(activeSession as ActiveUntisSession).userData.id}.timetable.$week',
      jsonEncode(json),
    );

    state = timeTable;
  }
}

@Riverpod(keepAlive: true)
class CachedTimeTableTimestamp extends _$CachedTimeTableTimestamp {
  @override
  DateTime build(Week week) {
    return sharedPreferences.containsKey('timetable.$week.timestamp')
        ? DateTime.parse(sharedPreferences.getString('timetable.$week.timestamp')!)
        : DateTime.now();
  }

  Future<void> setCachedTimeTableTimestamp(DateTime timestamp) async {
    await sharedPreferences.setString('timetable.$week.timestamp', timestamp.toIso8601String());
    state = timestamp;
  }
}
