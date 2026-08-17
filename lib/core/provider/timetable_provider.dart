import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/provider/connectivity_provider.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/utils.dart';

part 'timetable_provider.g.dart';

@riverpod
class TimeTable extends _$TimeTable {
  @override
  TimeTableWeek build(UntisSession session, Week week) {
    assert(session is ActiveUntisSession, 'Session must be active');
    if (ref.watch(canMakeRequestProvider)) {
      var timeTable = ref.watch(requestTimetableEntriesProvider(session, week));
      if (timeTable.hasValue) {
        return timeTable.requireValue;
      }
    }
    return ref.watch(cachedTimeTableProvider(session, week));
  }
}
