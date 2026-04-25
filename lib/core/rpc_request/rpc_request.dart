import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:otp/otp.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:your_schedule/core/rpc_request/rpc.dart';
import 'package:your_schedule/utils.dart';

part 'rpc_request.freezed.dart';

/// Authentication parameters for the Untis API
@Freezed(toJson: false, fromJson: false)
abstract class AuthParams with _$AuthParams {
  const factory AuthParams({
    required String user,
    required String appSharedSecret,
  }) = _AuthParams;

  const AuthParams._();

  Map<String, dynamic> toJson() => {
        'auth': {
          'user': user,
          'otp': OTP.generateTOTPCode(
            appSharedSecret.trim(),
            DateTime.now().millisecondsSinceEpoch,
            algorithm: Algorithm.SHA1,
            isGoogle: true,
          ),
          'clientTime': DateTime.now().millisecondsSinceEpoch,
        },
      };
}

// Identifier counter for RPC requests.
// The Server MUST reply with the same value in the Response object if included. See [jsonrpc.org](https://www.jsonrpc.org/specification).
// In the past, the untis server has been known to ignore the id field in the request and respond with a different id.
// In that case, the response is discarded and an Exception is thrown.
int _id = 0;

/// Posts a request to the Untis API and returns a Future&lt;RPCResponse&gt; as specified on [jsonrpc.org](https://www.jsonrpc.org/specification).
Future<RPCResponse> rpcRequest({
  required String method,
  required Uri serverUrl,
  dynamic params = const {},
}) async {
  // Set id for current request.
  int id = _id++;
  // Add breadcrumb to Sentry, scrub sensitive data.
  Sentry.addBreadcrumb(
    Breadcrumb(
      message: 'Performing rpc request $method to $serverUrl',
      category: 'rpc.info',
      data: {
        'id': id,
        'method': method,
        if (params is List && params[0] is Map<String, dynamic>)
          'params': ({...(params[0] as Map<String, dynamic>)})
            ..scrubIfPresent('auth', (value) => 'scrubbed')
            ..scrubIfPresent('userName', (value) => 'scrubbed')
            ..scrubIfPresent('password', (value) => 'scrubbed'),
      },
      level: SentryLevel.info,
    ),
  );

  // Send request to server.
  http.Response response;
  try {
    response = await http.post(
      serverUrl,
      body: jsonEncode({
        'jsonrpc': '2.0',
        'id': id.toString(),
        'method': method,
        'params': ?params,
      }),
      headers: {
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 15));
  } catch (e, s) {
    // Capture error with Sentry and log it.
    Sentry.captureException(
      e,
      stackTrace: s,
      hint: Hint.withMap(
        {
          'serverUrl': serverUrl.toString(),
          'method': method,
          'params': params,
        },
      ),
    );
    getLogger().e("Error while performing rpcRequest $method to server $serverUrl", error: e, stackTrace: s);
    rethrow;
  }

  switch (response.statusCode) {
    case 200:
      var rpcResponse = RPCResponse.fromJson(jsonDecode(response.body));
      if (rpcResponse.id != id.toString()) {
        getLogger().f('id of response does not match id of request');
        throw const IllegalIdTokenException();
      }
      getLogger().i("Successful RPC Request: $method"
          "\n${rpcResponse.toStringNoResult()}");
      return rpcResponse;
    case 404:
      try {
        var rpcResponse = RPCResponse.fromJson(jsonDecode(response.body));
        getLogger().w("404 RPC Request: $method"
            "\n${rpcResponse.toStringNoResult()}");
        return rpcResponse;
      } catch (e, s) {
        getLogger().e("Error while performing rpcRequest $method to server $serverUrl", error: e, stackTrace: s);
        rethrow;
      }
    default:
      getLogger().e(
        'HTTP Error: ${response.statusCode} ${response.reasonPhrase}',
        error: response,
        stackTrace: StackTrace.current,
      );
      throw HttpException(
        response.statusCode,
        response.reasonPhrase.toString(),
        uri: serverUrl,
      );
  }
}

class IllegalIdTokenException implements Exception {
  const IllegalIdTokenException();

  @override
  String toString() {
    return 'IllegalIdTokenException: id of response does not match id of request';
  }
}

class HttpException implements Exception {
  final int statusCode;
  final String message;
  final Uri? uri;

  const HttpException(this.statusCode, this.message, {this.uri});

  @override
  String toString() {
    return 'HttpException: $message';
  }
}
