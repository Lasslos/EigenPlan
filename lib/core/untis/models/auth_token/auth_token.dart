import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_token.freezed.dart';
part 'auth_token.g.dart';

@freezed
abstract class AuthToken with _$AuthToken {
  const factory AuthToken({
    required String jwt,
  }) = _AuthToken;
  const AuthToken._();

  factory AuthToken.fromJson(Map<String, dynamic> json) =>
      _$AuthTokenFromJson(json);

  /// Decodes the JWT payload without verifying the signature.
  Map<String, dynamic> get _payload {
    final parts = jwt.split('.');
    if (parts.length != 3) {
      throw const FormatException('Invalid JWT: expected 3 parts');
    }
    final normalized = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(normalized));
    return jsonDecode(decoded) as Map<String, dynamic>;
  }

  /// Returns the expiry as a [DateTime], or null if no `exp` claim is present.
  DateTime? get expiry {
    final exp = _payload['exp'];
    if (exp == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch((exp as int) * 1000);
  }

  /// Returns true if the token has expired or has no `exp` claim.
  bool get isExpired {
    final exp = expiry;
    if (exp == null) {
      return true;
    }
    return DateTime.now().isAfter(exp);
  }
}
