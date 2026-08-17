import 'dart:convert';

import 'package:http/http.dart' as http;

/// One request/response pair observed by a [CapturingClient].
class CapturedExchange {
  final Uri url;
  final String method;
  final int statusCode;
  final String responseBody;
  final String? requestBody;

  const CapturedExchange(this.url, this.method, this.statusCode, this.responseBody, this.requestBody);

  /// A short, human-readable label for this exchange — the JSON-RPC `method` for RPC
  /// POSTs (which all share the same URL, so the URL alone isn't distinguishing), or
  /// the REST method + path otherwise. Used only for printing which endpoints a live
  /// test run touched — never includes request/response content.
  String get requestLabel {
    final body = requestBody;
    // A GET's request.body is '' (empty string), not null — must check both, or
    // jsonDecode('') throws "Unexpected end of input".
    if (body != null && body.isNotEmpty) {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['method'] is String) {
        return 'RPC ${decoded['method']}';
      }
    }
    return '$method ${url.path}';
  }
}

/// Shared, long-lived record of every exchange seen across a whole
/// `http.runWithClient` session. Needed because `package:http`'s top-level
/// convenience functions (`http.get`/`http.post`, which every production request
/// function here uses) call the `clientFactory` passed to `runWithClient` fresh for
/// *every single call* and close whatever it returns immediately after — see
/// `_withClient` in `package:http/http.dart`. A [CapturingClient] instance is
/// therefore one-shot; this log is what survives across the whole flow.
class ExchangeLog {
  final List<CapturedExchange> exchanges = [];

  /// The most recently completed exchange — call this immediately after `await`ing
  /// the production call under test, since exchanges are recorded in request order.
  CapturedExchange get last => exchanges.last;
}

/// A real [http.Client] (backed by the platform's default client) that also records
/// every request/response pair it sees into a shared [ExchangeLog], so live tests
/// can run the actual production request functions unmodified and still get at the
/// raw exchange afterwards — needed to run [findUnparsedKeys]
/// (see `test/support/json_parity.dart`) against what the real API just returned,
/// and to report which endpoint was checked.
///
/// One-shot by design (see [ExchangeLog]) — pass `() => CapturingClient(log)` as
/// `runWithClient`'s `clientFactory`, not a single shared instance, or the second
/// request will throw "Client is already closed".
class CapturingClient extends http.BaseClient {
  CapturingClient(this._log);

  final ExchangeLog _log;
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request);
    final bytes = await response.stream.toBytes();
    _log.exchanges.add(
      CapturedExchange(
        request.url,
        request.method,
        response.statusCode,
        utf8.decode(bytes),
        request is http.Request ? request.body : null,
      ),
    );
    return http.StreamedResponse(
      Stream.value(bytes),
      response.statusCode,
      contentLength: bytes.length,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
