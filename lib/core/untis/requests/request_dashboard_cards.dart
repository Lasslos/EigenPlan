import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/rpc_request/rpc.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/logger.dart';

part 'request_dashboard_cards.g.dart';

/// School-posted announcements pinned to the home screen
/// (`GET /WebUntis/api/rest/view/v1/dashboard/cards`). Deliberately not cached/kept
/// alive like the rest of the data layer — staleness doesn't matter for an
/// announcement banner (unlike homework/exams/messages), and the dashboard's
/// `AnnouncementsCard` is meant to render nothing at all while loading, on error, or
/// when empty, which a plain `AsyncValue` already gives for free.
@riverpod
Future<List<DashboardCard>> requestDashboardCards(Ref ref, UntisSession activeSession) async {
  assert(activeSession is ActiveUntisSession, 'Session must be active');
  final session = activeSession as ActiveUntisSession;

  final uri = Uri.https(
    session.school.server,
    '/WebUntis/api/rest/view/v1/dashboard/cards',
    {'school': session.school.loginName},
  );

  final authToken =
      session.loginMode == LoginMode.anonymous ? null : await ref.read(authTokenProvider(session).future);

  http.Response response;
  try {
    response = await http.get(uri, headers: session.restAuthHeaders(authToken));
  } catch (e, s) {
    getLogger().e('Error while requesting dashboard cards', error: e, stackTrace: s);
    rethrow;
  }

  switch (response.statusCode) {
    case 200:
      return DashboardCardsResponse.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      ).cards;
    default:
      getLogger().e('HTTP Error: ${response.statusCode} ${response.reasonPhrase}');
      throw HttpException(response.statusCode, response.reasonPhrase.toString(), uri: uri);
  }
}
