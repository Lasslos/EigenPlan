import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:your_schedule/core/rpc_request/rpc.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/logger.dart';

Future<AuthToken> requestAuthToken(
    UntisSession session,
    String appSharedSecret, {
      String token = "",
    }) async {
  final schoolEncoded = Uri.encodeComponent(session.school.loginName);
  final uri = Uri.https(
    session.school.server,
    '/WebUntis/api/mobile/v2/$schoolEncoded/authentication',
  );

  http.Response response;
  try {
    response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({
        'username': session.username,
        'password': session.password,
        'oneTimePassword': token,
      }),
    );
  } catch (e, s) {
    getLogger().e("Error while requesting auth token", error: e, stackTrace: s);
    rethrow;
  }

  switch (response.statusCode) {
    case 200:
      getLogger().i("Successful auth token request");
      return AuthToken.fromJson(
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
