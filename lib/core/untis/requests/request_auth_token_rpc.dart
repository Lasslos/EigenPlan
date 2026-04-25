import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/rpc_request/rpc.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/logger.dart';

part 'request_auth_token_rpc.g.dart';

@Riverpod(keepAlive: true)
Future<AuthToken> authToken(
    Ref ref, UntisSession activeSession,
) async {
  assert(activeSession is ActiveUntisSession, "Session must be active!");
  final session = activeSession as ActiveUntisSession;

  final authParams = AuthParams(
    user: session.username,
    appSharedSecret: session.appSharedSecret,
  ).toJson();

  final response = await rpcRequest(
      method: 'getAuthToken',
      params: [{ ...authParams }],
      serverUrl: Uri.parse(session.school.rpcUrl),
  );

  switch (response) {
    case RPCResponseResult():
      final tokenString = response.result['token'] as String;
      final authToken = AuthToken(jwt: tokenString);

      if (authToken.expiry != null) {
        Duration ttl = authToken.expiry!.difference(DateTime.now()) - const Duration(seconds: 30);
        final timer = Timer(ttl, () {
          ref.invalidateSelf();
          getLogger().i("Invalidated auth token");
        });
        ref.onDispose(timer.cancel);
      }

      return authToken;
    case RPCResponseError():
      throw response.error;
  }
}
