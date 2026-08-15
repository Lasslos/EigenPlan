import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const secureStorage = FlutterSecureStorage();

/// [sessionKey] is a stable per-session identifier (school + username, see
/// `sessionSecretKey` in `untis_session_provider.dart`) — these builders exist so
/// callers never hand-format secure-storage key strings inline.
String passwordKey(String sessionKey) => '$sessionKey.password';

String appSharedSecretKey(String sessionKey) => '$sessionKey.appSharedSecret';
