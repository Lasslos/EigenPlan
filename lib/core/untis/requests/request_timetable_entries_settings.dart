import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/rpc_request/rpc.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/logger.dart';

part 'request_timetable_entries_settings.g.dart';

/// Fetches the per-resourceType display overlay toggles via
/// `GET /timetable/entries/settings`. No caching — cheap, purely cosmetic, and only
/// ever needed while a timetable is already rendered (which already has its own
/// online/offline fallback via `TimeTable`).
@riverpod
Future<TimetableEntriesSettings> requestTimetableEntriesSettings(
  Ref ref,
  UntisSession activeSession,
  String resourceType,
) async {
  assert(activeSession is ActiveUntisSession, 'Session must be active!');
  ActiveUntisSession session = activeSession as ActiveUntisSession;

  final uri = Uri.https(
    session.school.server,
    '/WebUntis/api/rest/view/v1/timetable/entries/settings',
    {'resourceType': resourceType, 'school': session.school.loginName},
  );

  AuthToken? authToken = session.loginMode == LoginMode.anonymous
      ? null
      : await ref.read(authTokenProvider(session).future);

  http.Response response;
  try {
    response = await http.get(uri, headers: session.restAuthHeaders(authToken));
  } catch (e, s) {
    getLogger().e(
      'Error while requesting timetable entries settings',
      error: e,
      stackTrace: s,
    );
    rethrow;
  }

  switch (response.statusCode) {
    case 200:
      return TimetableEntriesSettings.fromJson(
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
