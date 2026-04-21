import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/rpc_request/rpc.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/logger.dart';

part 'request_auth_token_v2.g.dart';

@Riverpod(keepAlive: true)
Future<AuthToken> authTokenV2(
    Ref ref,
    UntisSession session,
    String appSharedSecret,
    ) async {
  final uri = Uri.https(
    session.school.server,
    '/WebUntis/jsonrpc_intern.do',
    {'school': session.school.loginName},
  );

  final authParams = AuthParams(
    user: session.username,
    appSharedSecret: appSharedSecret,
  ).toJson();

  http.Response response;
  try {
    response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'id': 'untis-mobile-android-6.5.2',
        'method': 'getAuthToken',
        'params': [authParams],
      }),
    );
  } catch (e, s) {
    getLogger().e('Error while requesting auth token v2', error: e, stackTrace: s);
    rethrow;
  }

  switch (response.statusCode) {
    case 200:
      getLogger().i('Successful auth token v2 request');
      final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final tokenString = (body['result'] as Map<String, dynamic>)['token'] as String;
      final authToken = AuthToken(jwt: tokenString);

      Duration ttl;
      try {
        final expiry = authToken.expiry;
        if (expiry != null) {
          ttl = expiry.difference(DateTime.now()) - const Duration(seconds: 30);
        } else {
          ttl = const Duration(minutes: 14);
        }
      } on FormatException {
        // token is not a JWT — fall back to a fixed refresh interval
        ttl = const Duration(minutes: 14);
      }

      if (ttl > Duration.zero) {
        final timer = Timer(ttl, () => ref.invalidateSelf());
        ref.onDispose(timer.cancel);
      }

      return authToken;

    default:
      getLogger().e('HTTP Error: ${response.statusCode} ${response.reasonPhrase}');
      throw HttpException(
        response.statusCode,
        response.reasonPhrase.toString(),
        uri: uri,
      );
  }
}
