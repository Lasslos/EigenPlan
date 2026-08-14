import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_shared_secret_params.freezed.dart';
part 'app_shared_secret_params.g.dart';

@freezed
abstract class AppSharedSecretParams with _$AppSharedSecretParams {
  const factory AppSharedSecretParams({
    @JsonKey(name: 'userName') required String username,
    required String password, required String token,
  }) = _AppSharedSecretParams;

  factory AppSharedSecretParams.fromJson(Map<String, dynamic> json) =>
      _$AppSharedSecretParamsFromJson(json);
}
