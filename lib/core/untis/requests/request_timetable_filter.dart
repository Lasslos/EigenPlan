import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/rpc_request/rpc.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/logger.dart';

part 'request_timetable_filter.g.dart';

/// Fetches the "switch timetable" picker's searchable directory for one
/// [resourceType] via `GET /timetable/filter`. No caching — this is the picker's
/// per-tab search list, inherently fetched fresh (no `query` param exists server-side;
/// the caller filters the returned list client-side as the user types, matching
/// `filter_screen.dart`'s existing search pattern). `autoDispose` (the default here,
/// unlike the `keepAlive: true` three-tier providers) lets Riverpod's own
/// memoization avoid re-fetching per keystroke while the picker is open, and
/// releases the (potentially large — a full student roster) response once it closes.
@riverpod
Future<TimetableFilterResponse> requestTimetableFilter(
  Ref ref,
  UntisSession activeSession,
  String resourceType,
) async {
  assert(activeSession is ActiveUntisSession, 'Session must be active!');
  ActiveUntisSession session = activeSession as ActiveUntisSession;

  final uri = Uri.https(
    session.school.server,
    '/WebUntis/api/rest/view/v1/timetable/filter',
    {
      'resourceType': resourceType,
      'includePublicTimetables': 'true',
      'school': session.school.loginName,
    },
  );

  AuthToken? authToken = session.loginMode == LoginMode.anonymous
      ? null
      : await ref.read(authTokenProvider(session).future);

  http.Response response;
  try {
    response = await http.get(uri, headers: session.restAuthHeaders(authToken));
  } catch (e, s) {
    getLogger().e(
      'Error while requesting timetable filter',
      error: e,
      stackTrace: s,
    );
    rethrow;
  }

  switch (response.statusCode) {
    case 200:
      return TimetableFilterResponse.fromJson(
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
