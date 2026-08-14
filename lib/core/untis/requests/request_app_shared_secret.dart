import 'package:your_schedule/core/rpc_request/rpc.dart';
import 'package:your_schedule/core/untis.dart';

/// Requests the shared secret for the app.
///
/// The shared secret is used to authenticate the app with the server.
/// Returns a [Future] with the shared secret. If authentication fails,
/// 2FA is required or an invalid 2FA token was provided, a [RPCError] is thrown.
/// See [RPCError.authenticationFailed], [RPCError.twoFactorRequired}
/// and [RPCError.invalidTwoFactor} respectively.
Future<String> requestAppSharedSecret(UntisSession session, {String token = '',}
) async {
  var response = await rpcRequest(
    method: 'getAppSharedSecret',
    params: [
      AppSharedSecretParams(username: session.username, password: session.password, token: token).toJson(),
    ],
    serverUrl: Uri.parse(session.school.rpcUrl),
  );

  return switch (response) {
    RPCResponseResult() => response.result,
    RPCResponseError() => throw response.error,
  };
}
