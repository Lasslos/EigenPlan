import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/rpc_request/rpc.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/utils.dart';

part 'request_exams.g.dart';

/// Requests the exams for the given [week].
///
/// Returns a [Future] with a [Map] of [Date]s and [List]s of [Exam]s.
/// All [Date]s are normalized to the start of the day.
@Riverpod(keepAlive: true)
class RequestExams extends _$RequestExams {
  @override
  Future<Map<Date, List<Exam>>> build(UntisSession activeSession, Week week) async {
    assert(activeSession is ActiveUntisSession, 'Session must be active!');
    ActiveUntisSession session = activeSession as ActiveUntisSession;
    // Cache/Log results by listening for changes
    listenSelf((previous, data) {
      if (previous == data) {
        return;
      }
      data.when(
        data: (data) {
          ref.read(cachedExamsProvider(session, week).notifier).setCachedExams(
            data,
          );
        },
        error: (error, stackTrace) {
          logRequestError(
              'Error while requesting exams for $week', error, stackTrace);
        },
        loading: () {},
      );
    });

    var authParams = AuthParams(
        user: session.username, appSharedSecret: session.appSharedSecret);
    var response = await rpcRequest(
      method: 'getExams2017',
      params: [
        {
          'id': session.userData.id,
          'type': session.userData.type,
          'startDate': week.startDate.format(DateFormat('yyyy-MM-dd')),
          'endDate': week.endDate.format(DateFormat('yyyy-MM-dd')),
          ...authParams.toJson(),
        }
      ],
      serverUrl: Uri.parse(session.school.rpcUrl),
    );

    switch (response) {
      case RPCResponseResult():
        {
          // Get exam set
          var examSet = (response.result.result['exams'] as List<dynamic>).map((
              e) => Exam.fromJson(e)).toSet();
          //Create empty map
          var examMap = <Date, List<Exam>>{
            for (var i = 0; i < 7; i++) week.startDate.addDays(i): [],
          };

          // Fill map with exams
          for (var exam in examSet) {
            examMap[exam.startDateTime.normalized()]!.add(exam);
          }
          // Sort exams by start time
          for (var i = 0; i < 7; i++) {
            examMap[week.startDate.addDays(i)]!.sort(
                  (a, b) => a.startDateTime.compareTo(b.startDateTime),
            );
          }
          return examMap;
        }
      case RPCResponseError():
        throw response.error;
    }
  }
}
