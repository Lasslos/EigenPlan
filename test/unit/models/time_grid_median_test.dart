import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:your_schedule/core/untis.dart';

TimeGridEntry _period(String label, int startHour, int startMinute, int lengthMinutes) {
  var start = startHour * 60 + startMinute;
  var end = start + lengthMinutes;
  return TimeGridEntry(
    label,
    TimeOfDay(hour: start ~/ 60, minute: start % 60),
    TimeOfDay(hour: end ~/ 60, minute: end % 60),
  );
}

void main() {
  group('TimeGridMedian', () {
    test('picks the middle period of an odd-sized grid', () {
      var grid = [
        _period('1', 8, 0, 45),
        _period('2', 9, 0, 60),
        _period('3', 10, 0, 90),
      ];

      expect(grid.medianPeriod.label, '2');
      expect(grid.medianPeriodLength, const Duration(minutes: 60));
    });

    test('takes the upper of the two middle periods of an even-sized grid', () {
      var grid = [
        _period('1', 8, 0, 45),
        _period('2', 9, 0, 50),
        _period('3', 10, 0, 60),
        _period('4', 11, 0, 90),
      ];

      expect(grid.medianPeriod.label, '3');
      expect(grid.medianPeriodLength, const Duration(minutes: 60));
    });

    test('is unmoved by a single long outlier block, unlike the mean', () {
      var grid = [
        _period('1', 8, 0, 45),
        _period('2', 9, 0, 45),
        _period('3', 10, 0, 45),
        _period('4', 11, 0, 45),
        _period('Projekt', 12, 0, 300),
      ];

      var mean = Duration(
        minutes:
            grid.map((e) => e.length.inMinutes).reduce((a, b) => a + b) ~/ grid.length,
      );

      expect(grid.medianPeriodLength, const Duration(minutes: 45));
      expect(mean, greaterThan(grid.medianPeriodLength));
    });

    test('is independent of the order periods appear in the grid', () {
      var grid = [
        _period('spät', 14, 0, 30),
        _period('früh', 8, 0, 90),
        _period('mittag', 12, 0, 45),
      ];

      expect(grid.medianPeriodLength, const Duration(minutes: 45));
      // The grid itself keeps its chronological order — sorting happens on a copy.
      expect(grid.map((e) => e.label), ['spät', 'früh', 'mittag']);
    });
  });
}
