import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/rpc_request/rpc.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/utils.dart';

part 'request_timetable.g.dart';

/// Requests the timetable for the given [week].
///
/// The request is send to [apiBaseUrl] and uses the [authParams] to authenticate.
/// Returns a [Future] with a [Map] of [Date]s and [List]s of [TimeTablePeriod]s.
/// All [Date]s are normalized to the start of the day.
@Riverpod(keepAlive: true)
class RequestTimeTable extends _$RequestTimeTable {
  @override
  Future<TimeTableWeek> build(UntisSession activeSession, Week week) async {
    assert(activeSession is ActiveUntisSession, 'Session must be active!');
    ActiveUntisSession session = activeSession as ActiveUntisSession;
    // Cache/Log results by listening for changes
    listenSelf((previous, data) {
      if (previous == data) {
        return;
      }
      data.when(
        data: (data) {
          ref
              .read(cachedTimeTableProvider(session, week).notifier)
              .setCachedTimeTable(data);
        },
        error: (error, stackTrace) {
          logRequestError(
              'Error while requesting timetable for $week', error, stackTrace);
        },
        loading: () {},
      );
    });

    var response = await rpcRequest(
      method: 'getTimetable2017',
      params: [
        {
          'id': session.userData.id,
          'type': session.userData.type,
          'startDate': week.startDate.format(DateFormat('yyyy-MM-dd')),
          'endDate': week.endDate.format(DateFormat('yyyy-MM-dd')),
          'masterDataTimestamp': session.userData.timeStamp,
          'timetableTimestamp': 0,
          'timetableTimestamps': [],
          ...session.authParams.toJson(),
        }
      ],
      serverUrl: Uri.parse(session.school.rpcUrl),
    );

    switch (response) {
      case RPCResponseResult():
        {
          var timeTablePeriodList = (response
              .result['timetable']['periods'] as List<dynamic>).map((e) =>
              TimeTablePeriod.fromJson(e)).toList();
          var timeTablePeriodMap = <Date, List<TimeTablePeriod>>{
            for (var i = 0; i < 7; i++) week.startDate.addDays(i): [],
          };
          for (var timeTablePeriod in timeTablePeriodList) {
            timeTablePeriodMap[timeTablePeriod.startTime.normalized()]!
                .add(timeTablePeriod);
          }
          for (var i = 0; i < 7; i++) {
            timeTablePeriodMap[week.startDate.addDays(i)]!.sort((a, b) =>
                a.startTime.compareTo(b.startTime));
          }
          return timeTablePeriodMap;
        }
      case RPCResponseError():
        throw response.error;
    }
  }
}
