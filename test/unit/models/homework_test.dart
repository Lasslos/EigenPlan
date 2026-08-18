import 'package:flutter_test/flutter_test.dart';
import 'package:your_schedule/core/untis.dart';

import '../../support/fixtures.dart';
import '../../support/json_parity.dart';

void main() {
  test('parses a real getHomeWork2017 response, all fields round-trip', () {
    final raw = loadFixtureMap('homework_response.json');

    final homework = Homework.fromJson(raw);

    expect(homework.homeWorks, hasLength(3));
    expect(homework.homeWorks[0].lessonId, 7553);
    expect(homework.homeWorks[0].completed, isFalse);
    expect(homework.lessonsById[7553]!.subjectId, 15);
    expect(homework.lessonsById[7655]!.klassenIds, [1517]);
    expect(findUnparsedKeys(raw, homework.toJson()), isEmpty);
  });
}
