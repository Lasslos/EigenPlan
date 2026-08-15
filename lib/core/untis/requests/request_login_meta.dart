import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/rpc_request/rpc.dart';
import 'package:your_schedule/core/untis/models/login_meta/login_meta.dart';
import 'package:your_schedule/core/untis/models/school_search/school.dart';
import 'package:your_schedule/util/logger.dart';

part 'request_login_meta.g.dart';

/// Requests which login methods [school] offers. No authentication — this is called
/// right after a school is picked, before any credentials are collected, to decide
/// which login form to present.
@riverpod
Future<LoginMeta> requestLoginMeta(Ref ref, School school) async {
  final uri = Uri.https(
    school.server,
    '/WebUntis/api/public/v1/login-meta',
    {'school': school.loginName},
  );

  http.Response response;
  try {
    response = await http.get(uri);
  } catch (e, s) {
    getLogger().e('Error while requesting login-meta', error: e, stackTrace: s);
    rethrow;
  }

  switch (response.statusCode) {
    case 200:
      return LoginMeta.fromJson(
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
