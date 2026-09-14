import 'package:flutter_test/flutter_test.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/date.dart';
import 'package:your_schedule/util/exam_visibility.dart';

Exam _exam({required DateTime start, required DateTime end}) => Exam(
      1,
      'Klausur',
      start,
      end,
      7,
      const [],
      const {},
      const [],
      const [],
      'Mathe',
      'Analysis',
    );

void main() {
  final today = Date(DateTime(2026, 9, 14, 8, 56));

  group('isExamPast', () {
    test('an exam still to come today is not past', () {
      final exam = _exam(start: DateTime(2026, 9, 14, 10), end: DateTime(2026, 9, 14, 11, 30));
      expect(isExamPast(exam, today), isFalse);
    });

    test('an exam already written today is still not past', () {
      // The reported mismatch: the dashboard kept this one, the exams screen dropped it
      // the minute it ended. Both keep it now, until the day rolls over.
      final exam = _exam(start: DateTime(2026, 9, 14, 8), end: DateTime(2026, 9, 14, 8, 45));
      expect(isExamPast(exam, today), isFalse);
    });

    test('yesterday is past', () {
      final exam = _exam(start: DateTime(2026, 9, 13, 8), end: DateTime(2026, 9, 13, 9, 30));
      expect(isExamPast(exam, today), isTrue);
    });

    test('a future exam is not past', () {
      final exam = _exam(start: DateTime(2026, 9, 21, 8), end: DateTime(2026, 9, 21, 9, 30));
      expect(isExamPast(exam, today), isFalse);
    });

    test('a multi-day exam survives until its last day is over', () {
      final spanning = _exam(start: DateTime(2026, 9, 13, 8), end: DateTime(2026, 9, 14, 12));
      expect(isExamPast(spanning, today), isFalse);

      final finished = _exam(start: DateTime(2026, 9, 11, 8), end: DateTime(2026, 9, 13, 12));
      expect(isExamPast(finished, today), isTrue);
    });
  });
}
