import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/rpc_request/rpc.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/utils.dart';

part 'request_timetable_entries.g.dart';

/// Every period type the app is interested in — the app always requests the full
/// list (observed in every capture), rather than filtering server-side.
const _periodTypes = [
  'NORMAL_TEACHING_PERIOD',
  'ADDITIONAL_PERIOD',
  'STAND_BY_PERIOD',
  'OFFICE_HOUR',
  'EXAM',
  'BREAK_SUPERVISION',
  'EVENT',
  'MEETING',
  'PLATFORM_CALENDAR_EVENT',
  'PERSONAL_CALENDAR_EVENT',
];

/// Requests the timetable for [week] via the new REST `timetable/entries` endpoint —
/// supersedes the legacy `getTimetable2017`, which is unreliable on the current
/// server generation (see `docs/api/spec/NOTES.md` §4: confirmed to both silently
/// return zero periods and NPE server-side for real accounts with real data).
@Riverpod(keepAlive: true)
class RequestTimetableEntries extends _$RequestTimetableEntries {
  @override
  Future<TimeTableWeek> build(UntisSession activeSession, Week week) async {
    assert(activeSession is ActiveUntisSession, 'Session must be active!');
    ActiveUntisSession session = activeSession as ActiveUntisSession;

    listenSelf((previous, data) {
      if (previous == data) {
        return;
      }
      data.when(
        data: (data) {
          ref.read(cachedTimeTableProvider(session, week).notifier).setCachedTimeTable(data);
        },
        error: (error, stackTrace) {
          logRequestError('Error while requesting timetable for $week', error, stackTrace);
        },
        loading: () {},
      );
    });

    final resourceType = session.userData.type;
    if (resourceType == null) {
      // The legacy getTimetable2017 sent this straight through as `type: null` and let
      // the server NPE on it — don't repeat that; fail clearly on the client instead.
      throw StateError('Cannot request a timetable: userData.elemType is null for this session.');
    }

    final uri = Uri.https(session.school.server, '/WebUntis/api/rest/view/v1/timetable/entries', {
      'start': week.startDate.format(DateFormat('yyyy-MM-dd')),
      'end': week.endDate.format(DateFormat('yyyy-MM-dd')),
      'format': '1',
      'resourceType': resourceType,
      'resources': session.userData.id.toString(),
      'periodTypes': _periodTypes.join(','),
      'layout': 'PRIORITY',
      'school': session.school.loginName,
    });

    AuthToken? authToken =
        session.loginMode == LoginMode.anonymous ? null : await ref.read(authTokenProvider(session).future);

    http.Response response;
    try {
      response = await http.get(
        uri,
        headers: session.restAuthHeaders(authToken),
      );
    } catch (e, s) {
      getLogger().e('Error while requesting timetable entries', error: e, stackTrace: s);
      rethrow;
    }

    switch (response.statusCode) {
      case 200:
        getLogger().i('Successful timetable entries request');
        var entries = TimetableEntriesResponse.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
        );
        return {
          for (var day in entries.days) Date(day.date): day,
        };
      case 404:
        // Not an exceptional failure — this is the documented "no timetable data for
        // this resource/date range" response (e.g. a school year that hasn't started
        // yet), not a real error. See docs/api/spec/openapi.yaml's `timetable/entries`
        // 404 response and NOTES.md.
        getLogger().i('No timetable entries for $week ($uri)');
        return {};
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
