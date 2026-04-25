import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/rpc_request/rpc.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/logger.dart';

part 'request_auth_token_rest.g.dart';

@Riverpod(keepAlive: true)
Future<String> authTokenRest(
    Ref ref,
    UntisSession session,
    String appSharedSecret,
    { String oneTimePassword = '' })
async {

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
        'oneTimePassword': oneTimePassword,
      }),
    );
  } catch (e, s) {
    getLogger().e('Error while requesting auth token', error: e, stackTrace: s);
    rethrow;
  }

  switch (response.statusCode) {
    case 200:
      getLogger().i('Successful auth token request');
      final token = AuthToken.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
      return token.jwt;

    default:
      getLogger().e('HTTP Error: ${response.statusCode} ${response.reasonPhrase}');
      throw HttpException(
        response.statusCode,
        response.reasonPhrase.toString(),
        uri: uri,
      );
  }
}
