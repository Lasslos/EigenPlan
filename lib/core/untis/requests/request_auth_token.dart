import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:otp/otp.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/rpc_request/rpc.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/logger.dart';

part 'request_auth_token.g.dart';

@Riverpod(keepAlive: true)
Future<AuthToken> authToken(Ref ref, UntisSession activeSession) async {
  assert(activeSession is ActiveUntisSession, "Session must be active!");
  activeSession = activeSession as ActiveUntisSession;

  final schoolEncoded = Uri.encodeComponent(activeSession.school.loginName);
  final uri = Uri.https(
    activeSession.school.server,
    '/WebUntis/api/mobile/v2/$schoolEncoded/authentication',
  );

  final oneTimePassword = OTP.generateTOTPCode(
    activeSession.appSharedSecret.trim(),
    DateTime.now().millisecondsSinceEpoch,
    algorithm: Algorithm.SHA1,
    isGoogle: true,
  );

  http.Response response;
  try {
    response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({
        'username': activeSession.username,
        'password': activeSession.password,
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

      // Auto-invalidate when the token expires so the next read fetches a fresh one
      final expiry = token.expiry;
      if (expiry != null) {
        final ttl = expiry.difference(DateTime.now()) - const Duration(seconds: 30);
        if (ttl > Duration.zero) {
          final timer = Timer(ttl, () => ref.invalidateSelf());
          ref.onDispose(timer.cancel);
        }
      }

      return token;

    default:
      getLogger().e('HTTP Error: ${response.statusCode} ${response.reasonPhrase}');
      throw HttpException(
        response.statusCode,
        response.reasonPhrase.toString(),
        uri: uri,
      );
  }
}
