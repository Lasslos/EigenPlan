import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/rpc_request/rpc.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/logger.dart';

part 'request_specified_message.g.dart';

@riverpod
class RequestSpecifiedMessage extends _$RequestSpecifiedMessage {
  @override
  Future<SpecifiedMessage> build(UntisSession activeSession, int messageId) async {
    assert(activeSession is ActiveUntisSession, "Session must be active");
    ActiveUntisSession session = activeSession as ActiveUntisSession;

    listenSelf((previous, data) {
      if (previous == data) {
        return;
      }
      data.when(
        data: (data) {
          ref
              .read(cachedSpecifiedMessageProvider(session, messageId).notifier)
              .setCachedSpecifiedMessage(data);
          ref.invalidate(requestMessagesProvider(session));
        },
        error: (error, stackTrace) {
          logRequestError("Error while requesting message $messageId", error, stackTrace);
        },
        loading: () {},
      );
    });

    final uri = Uri.https(
      session.school.server,
      '/WebUntis/api/rest/view/v1/messages/$messageId',
      {'school': session.school.loginName},
    );

    AuthToken authToken = await ref.read(authTokenProvider(session).future);

    http.Response response;
    try {
      response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${authToken.jwt}',
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept-Encoding': 'gzip',
          'Cache-Control': 'public, no-cache',
        },
      );
    } catch (e, s) {
      getLogger().e("Error while requesting specified message", error: e, stackTrace: s);
      rethrow;
    }

    switch (response.statusCode) {
      case 200:
        getLogger().i("Successful specified message request");
        return SpecifiedMessage.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
        );
      default:
        getLogger().e('HTTP Error: ${response.statusCode} ${response.reasonPhrase}');
        throw HttpException(
          response.statusCode,
          response.reasonPhrase.toString(),
          uri: uri,
        );
    }
  }
}
