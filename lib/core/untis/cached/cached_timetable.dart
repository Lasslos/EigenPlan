import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/shared_preferences.dart';
import 'package:your_schedule/utils.dart';

part 'cached_timetable.g.dart';

@Riverpod(keepAlive: true)
class CachedTimeTable extends _$CachedTimeTable {
  @override
  TimeTableWeek build(
    UntisSession activeSession,
    Week week,
    TimetableResourceRef resource,
  ) {
    assert(activeSession is ActiveUntisSession, 'Session must be active!');
    ActiveUntisSession session = activeSession as ActiveUntisSession;
    final key =
        '${session.userData.id}.timetable.${resource.resourceType}.${resource.resourceId}.$week';
    final json = sharedPreferences.getString(key);
    if (json == null) {
      return {};
    }

    try {
      return {
        for (var dayJson in jsonDecode(json) as List<dynamic>)
          Date(
            DateTime.parse((dayJson as Map<String, dynamic>)['date'] as String),
          ): TimetableDay.fromJson(
            dayJson,
          ),
      };
    } catch (e, s) {
      // Old-shaped or otherwise corrupt cached timetable — drop it rather than crash;
      // the live request will repopulate it. See storage_migration.dart's schema-version
      // gate for the general version of this same defensiveness.
      getLogger().e(
        'Dropping unparseable cached timetable',
        error: e,
        stackTrace: s,
      );
      return {};
    }
  }

  Future<void> setCachedTimeTable(TimeTableWeek timeTable) async {
    ActiveUntisSession session = activeSession as ActiveUntisSession;
    await ref
        .read(
          cachedTimeTableTimestampProvider(session, week, resource).notifier,
        )
        .setCachedTimeTableTimestamp(DateTime.now());

    await sharedPreferences.setString(
      '${session.userData.id}.timetable.${resource.resourceType}.${resource.resourceId}.$week',
      jsonEncode(timeTable.values.map((day) => day.toJson()).toList()),
    );

    state = timeTable;
  }
}

@Riverpod(keepAlive: true)
class CachedTimeTableTimestamp extends _$CachedTimeTableTimestamp {
  @override
  DateTime build(
    UntisSession activeSession,
    Week week,
    TimetableResourceRef resource,
  ) {
    assert(activeSession is ActiveUntisSession, 'Session must be active!');
    ActiveUntisSession session = activeSession as ActiveUntisSession;
    final key =
        '${session.userData.id}.timetable.${resource.resourceType}.${resource.resourceId}.$week.timestamp';
    final stored = sharedPreferences.getString(key);
    return stored != null ? DateTime.parse(stored) : DateTime.now();
  }

  Future<void> setCachedTimeTableTimestamp(DateTime timestamp) async {
    ActiveUntisSession session = activeSession as ActiveUntisSession;
    await sharedPreferences.setString(
      '${session.userData.id}.timetable.${resource.resourceType}.${resource.resourceId}.$week.timestamp',
      timestamp.toIso8601String(),
    );
    state = timestamp;
  }
}
