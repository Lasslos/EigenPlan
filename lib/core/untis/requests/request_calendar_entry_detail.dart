import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/rpc_request/rpc.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/logger.dart';

part 'request_calendar_entry_detail.g.dart';

/// Confirmed live (2026-08 probe): `STUDENT` = 5, `TEACHER` = 2. `CLASS`/`ROOM`/`SUBJECT`
/// are still unconfirmed — returns `null` for those so callers can skip the drill-down
/// rather than guess a wrong value (`7`/`8` were tried live and returned HTTP 500).
int? elementTypeForResourceType(String? userDataType) => switch (userDataType) {
  'STUDENT' => 5,
  'TEACHER' => 2,
  _ => null,
};

/// Fetches the "tap a period" drill-down detail for a specific timetable slot. No
/// caching — always an on-demand fetch for whichever period the user just tapped,
/// mirroring `request_attachment_storage_url.dart` rather than the live-vs-cached
/// three-provider pattern. [elementId] is the *resource's own* id
/// (`session.userData.id`) — **not** a period/`GridEntry.ids[]` value, confirmed via a
/// live probe: querying with a period id reliably returns zero `calendarEntries`.
@riverpod
Future<List<CalendarEntryDetail>> requestCalendarEntryDetail(
  Ref ref,
  UntisSession activeSession,
  int elementType,
  int elementId,
  DateTime start,
  DateTime end,
) async {
  assert(activeSession is ActiveUntisSession, 'Session must be active!');
  ActiveUntisSession session = activeSession as ActiveUntisSession;

  final uri = Uri.https(
    session.school.server,
    '/WebUntis/api/rest/view/v2/calendar-entry/detail',
    {
      'elementType': elementType.toString(),
      'elementId': elementId.toString(),
      'startDateTime': start.toIso8601String().substring(0, 19),
      'endDateTime': end.toIso8601String().substring(0, 19),
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
      'Error while requesting calendar entry detail',
      error: e,
      stackTrace: s,
    );
    rethrow;
  }

  switch (response.statusCode) {
    case 200:
      final decoded =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return CalendarEntryDetailResponse.fromJson(decoded).calendarEntries;
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
