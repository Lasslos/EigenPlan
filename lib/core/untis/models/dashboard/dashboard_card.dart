import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_card.freezed.dart';
part 'dashboard_card.g.dart';

/// One dashboard "card" — a school-posted announcement/bulletin pinned to the Untis
/// app's home screen (`GET /WebUntis/api/rest/view/v1/dashboard/cards`, see
/// `docs/api/captures/home/dashboard.md`). Unrelated to this app's own dashboard
/// summary cards ([DashboardScreen]) — the naming collision is Untis's, not ours.
@freezed
abstract class DashboardCard with _$DashboardCard {
  const factory DashboardCard({
    required int id,
    required String title,
    String? subtitle,
    @Default(false) bool hasAttachments,
    String? headerColor,
    int? orderNo,
    String? status,
    String? icon,
  }) = _DashboardCard;

  factory DashboardCard.fromJson(Map<String, dynamic> json) => _$DashboardCardFromJson(json);
}

@freezed
abstract class DashboardCardsResponse with _$DashboardCardsResponse {
  @JsonSerializable(explicitToJson: true)
  const factory DashboardCardsResponse({
    @JsonKey(name: 'dashboardCards') required List<DashboardCard> cards,
  }) = _DashboardCardsResponse;

  factory DashboardCardsResponse.fromJson(Map<String, dynamic> json) =>
      _$DashboardCardsResponseFromJson(json);
}
