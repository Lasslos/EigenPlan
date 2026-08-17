import 'dart:convert';
import 'dart:io';

import 'package:your_schedule/core/untis.dart';

/// One account to exercise the live API with. [schoolSearch] is passed to the real
/// `searchSchool` RPC (same as the login screen would use) — the school matching
/// [schoolSearch] as its `loginName` is picked from the results.
class LiveCredential {
  final String schoolSearch;
  final LoginMode loginMode;
  final String? username;
  final String? password;

  /// The app-shared-secret itself, for [LoginMode.ssoKey].
  final String? key;

  const LiveCredential({
    required this.schoolSearch,
    required this.loginMode,
    this.username,
    this.password,
    this.key,
  });

  factory LiveCredential.fromJson(Map<String, dynamic> json) {
    return LiveCredential(
      schoolSearch: json['school'] as String,
      loginMode: LoginMode.values.byName(json['loginMode'] as String),
      username: json['username'] as String?,
      password: json['password'] as String?,
      key: json['key'] as String?,
    );
  }
}

/// Loads the accounts to test against, checking `UNTIS_LIVE_CREDENTIALS` (a JSON
/// array, for quick one-off shell invocations) before falling back to the gitignored
/// `test/live/credentials.local.json`. Returns an empty list if neither is present —
/// callers should skip rather than fail in that case. See `test/live/README.md`.
List<LiveCredential> loadLiveCredentials() {
  final envJson = Platform.environment['UNTIS_LIVE_CREDENTIALS'];
  String? raw;
  if (envJson != null && envJson.trim().isNotEmpty) {
    raw = envJson;
  } else {
    final file = File('test/live/credentials.local.json');
    if (file.existsSync()) {
      raw = file.readAsStringSync();
    }
  }
  if (raw == null) {
    return [];
  }
  final decoded = jsonDecode(raw) as List<dynamic>;
  return decoded.map((e) => LiveCredential.fromJson(e as Map<String, dynamic>)).toList();
}
