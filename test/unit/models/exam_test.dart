import 'package:flutter_test/flutter_test.dart';
import 'package:your_schedule/core/untis.dart';

import '../../support/fixtures.dart';
import '../../support/json_parity.dart';

void main() {
  test('parses an exam item, all fields round-trip', () {
    // No capture ever observed a populated `exams` array (see
    // docs/api/spec/NOTES.md §3) — this fixture is hand-constructed to match the
    // `Exam`/`Invigilators` models' own fields, not derived from a real response.
    // It only proves the model parses its own shape correctly; the live coverage
    // test (test/live/) is what actually validates this against the real API.
    final raw = loadFixtureMap('exam_item_synthetic.json');

    final exam = Exam.fromJson(raw);

    expect(exam.id, 501);
    expect(exam.subjectId, 1530);
    expect(exam.invigilators, hasLength(1));
    expect(exam.invigilators.single.startTime.hour, 7);
    expect(findUnparsedKeys(raw, exam.toJson()), isEmpty);
  });
}
