import 'package:flutter_test/flutter_test.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/ui/screens/timetable_screen/widgets/grid_entry_layout.dart';

GridEntry _entry(int startHour, int endHour) => GridEntry(
  duration: GridEntryDuration(
    start: DateTime(2026, 1, 1, startHour),
    end: DateTime(2026, 1, 1, endHour),
  ),
  type: 'NORMAL_TEACHING_PERIOD',
  status: 'REGULAR',
);

GridEntryPlacement _placementFor(List<GridEntryPlacement> placements, GridEntry entry) =>
    placements.firstWhere((p) => identical(p.entry, entry));

void main() {
  group('packGridEntries', () {
    test('non-overlapping entries each take the full column width', () {
      var a = _entry(8, 9);
      var b = _entry(9, 10);

      var placements = packGridEntries([a, b]);

      for (var placement in placements) {
        expect(placement.columnCount, 1);
        expect(placement.columnSpan, 1);
      }
    });

    test('two overlapping entries split the width evenly', () {
      var a = _entry(8, 9);
      var b = _entry(8, 9);

      var placements = packGridEntries([a, b]);

      expect(placements, hasLength(2));
      for (var placement in placements) {
        expect(placement.columnCount, 2);
        expect(placement.columnSpan, 1);
      }
      expect(
        placements.map((p) => p.column).toSet(),
        {0, 1},
      );
    });

    test('hiding one of two overlapping entries lets the other reclaim the full width', () {
      var a = _entry(8, 9);
      var b = _entry(8, 9);

      // Both visible: split.
      var both = packGridEntries([a, b]);
      expect(_placementFor(both, a).columnCount, 2);

      // b hidden by the filter screen (simply not passed in) — a should now be alone.
      var onlyA = packGridEntries([a]);
      expect(_placementFor(onlyA, a).columnCount, 1);
      expect(_placementFor(onlyA, a).columnSpan, 1);
    });

    test('an entry expands rightward into a column that frees up before it starts', () {
      // x and y overlap 8-9 (two columns); z runs 9-10, colliding with neither, and
      // ends up sharing x's column — since y's column has nothing colliding with z, z
      // should expand to span both columns (full width) for its own duration.
      var x = _entry(8, 9);
      var y = _entry(8, 9);
      var z = _entry(9, 10);

      var placements = packGridEntries([x, y, z]);

      expect(_placementFor(placements, z).columnSpan, 2);
      expect(_placementFor(placements, z).columnCount, 2);
    });
  });
}
