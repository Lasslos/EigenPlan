import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/rpc_request/rpc.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/date.dart';

part 'request_messages_of_day.g.dart';

/// `getMessagesOfDay2017` for [date] — see [MessageOfDay] for why this JSON-RPC
/// method (rather than the REST `/dashboard/cards` endpoint) is what carries real
/// attachment links. Not cached/kept alive, matching [requestDashboardCards] — this
/// is enrichment data for a card that's fine rendering nothing when it's unavailable.
@riverpod
Future<List<MessageOfDay>> requestMessagesOfDay(Ref ref, UntisSession activeSession, Date date) async {
  assert(activeSession is ActiveUntisSession, 'Session must be active');
  final session = activeSession as ActiveUntisSession;

  final response = await rpcRequest(
    method: 'getMessagesOfDay2017',
    params: [
      {
        'date': date.format(DateFormat('yyyy-MM-dd')),
        ...session.authParams.toJson(),
      },
    ],
    serverUrl: Uri.parse(session.school.rpcUrl),
  );

  switch (response) {
    case RPCResponseResult():
      final messages = (response.result as Map<String, dynamic>)['messages'] as List<dynamic>;
      return messages.map((e) => MessageOfDay.fromJson(e as Map<String, dynamic>)).toList();
    case RPCResponseError():
      throw response.error;
  }
}
