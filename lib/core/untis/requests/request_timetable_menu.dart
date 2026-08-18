import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/rpc_request/rpc.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/logger.dart';

part 'request_timetable_menu.g.dart';

/// Requests the "switch timetable" picker's curated shortlist via
/// `GET /timetable/menu`. Cached via [CachedTimetableMenu]/composed via
/// `TimetableMenu` (`lib/core/provider/timetable_menu_provider.dart`) since it's
/// fetched every time the picker opens and should still show something offline.
@Riverpod(keepAlive: true)
class RequestTimetableMenu extends _$RequestTimetableMenu {
  @override
  Future<TimetableMenuResponse?> build(UntisSession activeSession) async {
    assert(activeSession is ActiveUntisSession, 'Session must be active!');
    ActiveUntisSession session = activeSession as ActiveUntisSession;

    listenSelf((previous, data) {
      if (previous == data) {
        return;
      }
      data.when(
        data: (data) {
          ref
              .read(cachedTimetableMenuProvider(session).notifier)
              .setCachedTimetableMenu(data);
        },
        error: (error, stackTrace) {
          logRequestError(
            'Error while requesting timetable menu',
            error,
            stackTrace,
          );
        },
        loading: () {},
      );
    });

    final uri = Uri.https(
      session.school.server,
      '/WebUntis/api/rest/view/v1/timetable/menu',
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
        'Error while requesting timetable menu',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }

    switch (response.statusCode) {
      case 200:
        return TimetableMenuResponse.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
        );
      case 404:
        // Documented "no timetable available for this account" response (see
        // docs/api/spec/openapi.yaml's timetable/menu 404) — not exceptional, e.g.
        // some anonymous accounts.
        getLogger().i('No timetable menu for this account ($uri)');
        return null;
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
