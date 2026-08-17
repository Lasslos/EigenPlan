import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'mobile_data.freezed.dart';
part 'mobile_data.g.dart';

/// Tenant + logged-in-user summary from `GET /api/rest/view/v3/mobile/data`.
///
/// Deliberately kept as its own model rather than merged into `UserData` (the
/// legacy `getUserData2017` payload) — they're fetched from different transports,
/// refresh independently, and aren't both guaranteed to be present for every login
/// mode (`user` is `null` for anonymous sessions; `UserData.userData` is always
/// present, just synthetic for anonymous). See `docs/api/spec/NOTES.md` §5.4.
@freezed
abstract class MobileData with _$MobileData {
  @JsonSerializable(explicitToJson: true)
  const factory MobileData({
    required Tenant tenant,
    MobileUser? user,
    SchoolYear? schoolYear,
  }) = _MobileData;

  factory MobileData.fromJson(Map<String, dynamic> json) => _$MobileDataFromJson(json);
}

@freezed
abstract class Tenant with _$Tenant {
  const factory Tenant({
    required String id,
    required String displayName,
    required String wuVersion,
    required String language,
    required String schoolLoginName,
  }) = _Tenant;

  factory Tenant.fromJson(Map<String, dynamic> json) => _$TenantFromJson(json);
}

@freezed
abstract class MobilePerson with _$MobilePerson {
  const factory MobilePerson({
    required int id,
    required String displayName,
    String? imageUrl,
  }) = _MobilePerson;

  factory MobilePerson.fromJson(Map<String, dynamic> json) => _$MobilePersonFromJson(json);
}

/// `role` is a plain [String], not a closed enum — observed values are `KLASSE`,
/// `STUDENT`, `TEACHER`, but a parent/guardian role is plausible given
/// `referencedStudents` and wasn't captured. See `grid_entry.dart` for why loosely
/// specified server enums are modeled this way throughout this rewrite.
@freezed
abstract class MobileUser with _$MobileUser {
  @JsonSerializable(explicitToJson: true)
  const factory MobileUser({
    required int id,
    required String username,
    required MobilePerson person,
    required String role,
    @Default([]) List<dynamic> referencedStudents,
    String? locale,
    int? departmentId,
    @Default([]) List<String> permissions,
  }) = _MobileUser;

  factory MobileUser.fromJson(Map<String, dynamic> json) => _$MobileUserFromJson(json);
}

@freezed
abstract class SchoolYearRange with _$SchoolYearRange {
  const factory SchoolYearRange({
    required DateTime start,
    required DateTime end,
  }) = _SchoolYearRange;

  factory SchoolYearRange.fromJson(Map<String, dynamic> json) => _$SchoolYearRangeFromJson(json);
}

@freezed
abstract class SchoolYear with _$SchoolYear {
  @JsonSerializable(explicitToJson: true)
  const factory SchoolYear({
    required int id,
    required String name,
    required SchoolYearRange dateRange,
  }) = _SchoolYear;

  factory SchoolYear.fromJson(Map<String, dynamic> json) => _$SchoolYearFromJson(json);
}
