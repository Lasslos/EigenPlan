import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/rpc_request/rpc.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/logger.dart';

part 'request_mobile_data.g.dart';

/// Requests tenant + logged-in-user summary via `GET /api/rest/view/v3/mobile/data`.
///
/// No offline caching — nothing in the UI consumes this yet (see
/// `docs/api/spec/NOTES.md` §5.4/Phase 1), so the full "live vs cached" three-provider
/// pattern (`CLAUDE.md`) isn't warranted for it at this point; add a cached/live pair
/// alongside whichever screen ends up needing this offline.
@riverpod
Future<MobileData> requestMobileData(Ref ref, UntisSession activeSession) async {
  assert(activeSession is ActiveUntisSession, 'Session must be active!');
  ActiveUntisSession session = activeSession as ActiveUntisSession;

  final uri = Uri.https(
    session.school.server,
    '/WebUntis/api/rest/view/v3/mobile/data',
    {'school': session.school.loginName},
  );

  AuthToken authToken = await ref.read(authTokenProvider(session).future);

  http.Response response;
  try {
    response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer ${authToken.jwt}'},
    );
  } catch (e, s) {
    getLogger().e('Error while requesting mobile data', error: e, stackTrace: s);
    rethrow;
  }

  switch (response.statusCode) {
    case 200:
      return MobileData.fromJson(
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
