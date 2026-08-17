import 'package:flutter_test/flutter_test.dart';
import 'package:your_schedule/core/rpc_request/rpc.dart';

import '../../support/fixtures.dart';

void main() {
  test('parses a real successful RPC envelope', () {
    final raw = loadFixtureMap('exams_rpc_response_empty.json');

    final response = RPCResponse.fromJson(raw);

    expect(response, isA<RPCResponseResult>());
    final result = response as RPCResponseResult;
    expect(result.id, '0');
    expect((result.result as Map<String, dynamic>)['exams'], isEmpty);
  });

  test('parses an RPC error envelope', () {
    final json = {
      'jsonrpc': '2.0',
      'id': '0',
      'error': {
        'code': RPCError.authenticationFailed,
        'message': 'Login failed',
        'data': null,
      },
    };

    final response = RPCResponse.fromJson(json);

    expect(response, isA<RPCResponseError>());
    final error = response as RPCResponseError;
    expect(error.error.code, RPCError.authenticationFailed);
    expect(error.error.message, 'Login failed');
  });
}
