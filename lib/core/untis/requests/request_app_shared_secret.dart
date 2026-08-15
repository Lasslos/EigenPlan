import 'package:your_schedule/core/rpc_request/rpc.dart';
import 'package:your_schedule/core/untis.dart';

/// Requests the app-shared-secret for a username+password login to [school].
///
/// Only meaningful for the normal password-login mode — SSO/key schools never call
/// this (the stored secret already *is* the app-shared-secret), and anonymous schools
/// don't have credentials to exchange at all.
///
/// The shared secret is used to authenticate the app with the server.
/// Returns a [Future] with the shared secret. If authentication fails,
/// 2FA is required or an invalid 2FA token was provided, a [RPCError] is thrown.
/// See [RPCError.authenticationFailed], [RPCError.twoFactorRequired}
/// and [RPCError.invalidTwoFactor} respectively.
Future<String> requestAppSharedSecret(
  School school,
  String username,
  String password, {
  String token = '',
}) async {
  var response = await rpcRequest(
    method: 'getAppSharedSecret',
    params: [
      AppSharedSecretParams(username: username, password: password, token: token).toJson(),
    ],
    serverUrl: Uri.parse(school.rpcUrl),
  );

  return switch (response) {
    RPCResponseResult() => response.result,
    RPCResponseError() => throw response.error,
  };
}
