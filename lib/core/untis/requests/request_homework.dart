import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/rpc_request/rpc.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/utils.dart';

part 'request_homework.g.dart';

const _pastWindowDays = 14;
const _futureWindowDays = 60;

/// Requests all homework in a fixed rolling window (today - [_pastWindowDays] days .. today +
/// [_futureWindowDays] days), not per-[Week] like exams/timetable — the only consumer is a flat
/// "all homework" list, not a per-week grid, and `getHomeWork2017` already documents accepting an
/// arbitrary date range. Since this provider is `keepAlive` and keyed only by session, the window
/// doesn't slide forward on its own if the app stays alive for days without a rebuild — acceptable,
/// as it self-corrects on every manual refresh (see [HomeworkScreen]'s `RefreshIndicator`) or cold start.
@Riverpod(keepAlive: true)
class RequestHomework extends _$RequestHomework {
  @override
  Future<Homework> build(UntisSession activeSession) async {
    assert(activeSession is ActiveUntisSession, 'Session must be active!');
    ActiveUntisSession session = activeSession as ActiveUntisSession;

    listenSelf((previous, data) {
      if (previous == data) {
        return;
      }
      data.when(
        data: (data) {
          ref
              .read(cachedHomeworkProvider(session).notifier)
              .setCachedHomework(data);
        },
        error: (error, stackTrace) {
          logRequestError('Error while requesting homework', error, stackTrace);
        },
        loading: () {},
      );
    });

    final dateFormat = DateFormat('yyyy-MM-dd');
    var response = await rpcRequest(
      method: 'getHomeWork2017',
      params: [
        {
          'id': session.userData.id,
          'type': session.userData.type,
          'startDate': Date.now()
              .subtractDays(_pastWindowDays)
              .format(dateFormat),
          'endDate': Date.now().addDays(_futureWindowDays).format(dateFormat),
          ...session.authParams.toJson(),
        },
      ],
      serverUrl: Uri.parse(session.school.rpcUrl),
    );

    switch (response) {
      case RPCResponseResult():
        return Homework.fromJson(response.result as Map<String, dynamic>);
      case RPCResponseError():
        throw response.error;
    }
  }
}
