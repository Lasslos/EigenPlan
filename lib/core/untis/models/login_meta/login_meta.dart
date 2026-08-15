import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_meta.freezed.dart';
part 'login_meta.g.dart';

/// What login methods a school offers, fetched before any credentials are collected.
///
/// Drives which login flow to present: a normal password form, an SSO/key form when
/// [ssoLoginEnabled] is true and password login is disabled server-side, or a
/// credential-less "continue as guest" flow when [anonymousLoginEnabled] is true.
@Freezed()
abstract class LoginMeta with _$LoginMeta {
  const factory LoginMeta({
    required bool anonymousLoginEnabled,
    required bool ssoLoginEnabled,
  }) = _LoginMeta;

  factory LoginMeta.fromJson(Map<String, dynamic> json) => _$LoginMetaFromJson(json);
}
