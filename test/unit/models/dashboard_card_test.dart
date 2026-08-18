import 'package:flutter_test/flutter_test.dart';
import 'package:your_schedule/core/untis.dart';

import '../../support/fixtures.dart';
import '../../support/json_parity.dart';

void main() {
  test('parses a real dashboard-cards response with no unrecognized fields', () {
    final raw = loadFixtureMap('dashboard_cards_response.json');

    final response = DashboardCardsResponse.fromJson(raw);

    expect(response.cards, hasLength(1));
    expect(response.cards.first.id, 146);
    expect(response.cards.first.title, 'Login zu WebUntis und UntisMobile');
    expect(response.cards.first.hasAttachments, isTrue);
    expect(response.cards.first.icon, 'megaphone');
    expect(findUnparsedKeys(raw, response.toJson()), isEmpty);
  });

  test('parses an empty dashboard-cards response', () {
    final response = DashboardCardsResponse.fromJson({'dashboardCards': <dynamic>[]});
    expect(response.cards, isEmpty);
  });
}
