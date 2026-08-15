import 'package:your_schedule/core/rpc_request/rpc.dart';
import 'package:your_schedule/core/untis.dart';

/// Requests the user data for [school], authenticating with [authParams].
///
/// Takes [School] + [AuthParams] directly (rather than a whole session) so it works
/// uniformly for every login mode, including anonymous sessions which have no
/// username/app-shared-secret to read off a session object.
Future<UserData> requestUserData(School school, AuthParams authParams) async {
  var response = await rpcRequest(
    method: 'getUserData2017',
    params: [
      {
        'elementId': 0,
        'deviceOs': 'AND',
        'deviceOsVersion': '',
        ...authParams.toJson(),
      }
    ],
    serverUrl: Uri.parse(school.rpcUrl),
  );

  return switch (response) {
    RPCResponseResult() => UserData.fromJson(response.result),
    RPCResponseError() => throw response.error,
  };
}
