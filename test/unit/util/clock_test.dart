import 'package:flutter_test/flutter_test.dart';
import 'package:your_schedule/core/provider/clock_provider.dart';

void main() {
  group('nextMinuteBoundary', () {
    test('lands just after the next whole minute, never on it', () {
      final boundary = nextMinuteBoundary(DateTime(2026, 3, 5, 11, 43, 22, 500));

      expect(boundary.isAfter(DateTime(2026, 3, 5, 11, 44)), isTrue);
      expect(boundary.isBefore(DateTime(2026, 3, 5, 11, 44, 1)), isTrue);
    });

    test('advances a full minute when already exactly on a boundary', () {
      final boundary = nextMinuteBoundary(DateTime(2026, 3, 5, 11, 43));

      expect(boundary.isAfter(DateTime(2026, 3, 5, 11, 44)), isTrue);
      expect(boundary.isBefore(DateTime(2026, 3, 5, 11, 44, 1)), isTrue);
    });

    test('rolls over midnight into the next day', () {
      final boundary = nextMinuteBoundary(DateTime(2026, 3, 5, 23, 59, 59));

      expect(boundary.isAfter(DateTime(2026, 3, 6)), isTrue);
      expect(boundary.isBefore(DateTime(2026, 3, 6, 0, 0, 1)), isTrue);
    });

    test('is always in the future, so a tick can never busy-loop', () {
      for (final now in [
        DateTime(2026, 3, 5, 0, 0, 0, 1),
        DateTime(2026, 3, 5, 11, 43, 59, 999),
        DateTime(2026, 12, 31, 23, 59, 59, 999),
      ]) {
        expect(nextMinuteBoundary(now).isAfter(now), isTrue, reason: '$now');
      }
    });
  });
}
