import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/rpc_request/rpc.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/logger.dart';

part 'request_mobile_data.g.dart';

/// Requests tenant + logged-in-user summary via `GET /api/rest/view/v3/mobile/data`.
/// Cached via [CachedMobileData]/composed via `AccountInfo` (`lib/core/provider/mobile_data_provider.dart`)
/// for the drawer avatar and Settings' account section.
@Riverpod(keepAlive: true)
class RequestMobileData extends _$RequestMobileData {
  @override
  Future<MobileData> build(UntisSession activeSession) async {
    assert(activeSession is ActiveUntisSession, 'Session must be active!');
    ActiveUntisSession session = activeSession as ActiveUntisSession;

    listenSelf((previous, data) {
      if (previous == data) {
        return;
      }
      data.when(
        data: (data) {
          ref
              .read(cachedMobileDataProvider(session).notifier)
              .setCachedMobileData(data);
        },
        error: (error, stackTrace) {
          logRequestError(
            'Error while requesting mobile data',
            error,
            stackTrace,
          );
        },
        loading: () {},
      );
    });

    final uri = Uri.https(
      session.school.server,
      '/WebUntis/api/rest/view/v3/mobile/data',
      {'school': session.school.loginName},
    );

    AuthToken? authToken = session.loginMode == LoginMode.anonymous
        ? null
        : await ref.read(authTokenProvider(session).future);

    http.Response response;
    try {
      response = await http.get(
        uri,
        headers: session.restAuthHeaders(authToken),
      );
    } catch (e, s) {
      getLogger().e(
        'Error while requesting mobile data',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }

    switch (response.statusCode) {
      case 200:
        return MobileData.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
        );
      default:
        getLogger().e(
          'HTTP Error: ${response.statusCode} ${response.reasonPhrase}',
        );
        throw HttpException(
          response.statusCode,
          response.reasonPhrase.toString(),
          uri: uri,
        );
    }
  }
}
