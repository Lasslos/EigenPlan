import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/ui/screens/home_screen/widgets/grid_entry_widget.dart';

/// Lays out a day's [GridEntry]s with a client-side overlap-packing algorithm, ported
/// from the legacy (pre-`/timetable/entries`) `period_layout.dart`. The server also
/// returns a suggested `layoutStartPosition`/`layoutWidth`, but those assume every
/// period the server knows about is being rendered — once the filter screen can hide
/// individual courses, only computing layout client-side over whatever's actually in
/// [entries] lets the remaining, visible ones reflow into the space a hidden one frees
/// up. See `docs/api/spec/NOTES.md` §4.
class GridEntryLayout extends ConsumerWidget {
  final List<GridEntry> entries;
  final double fontSize;

  const GridEntryLayout({
    required this.entries,
    required this.fontSize,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var timeGrid = ref.watch(
      selectedUntisSessionProvider.select(
        (value) => (value as ActiveUntisSession).userData.timeGrid,
      ),
    );
    var startOfDayMinutes =
        timeGrid.first.startTime.hour * 60 + timeGrid.first.startTime.minute;
    var endOfDayMinutes =
        timeGrid.last.endTime.hour * 60 + timeGrid.last.endTime.minute;
    var totalMinutes = endOfDayMinutes - startOfDayMinutes;

    double yFraction(DateTime time) =>
        ((time.hour * 60 + time.minute) - startOfDayMinutes) / totalMinutes;

    var placements = packGridEntries(entries);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            for (var placement in placements)
              Positioned(
                left:
                    constraints.maxWidth *
                    placement.column /
                    placement.columnCount,
                width:
                    constraints.maxWidth *
                    placement.columnSpan /
                    placement.columnCount,
                top:
                    constraints.maxHeight *
                    yFraction(placement.entry.duration.start),
                height:
                    constraints.maxHeight *
                    (yFraction(placement.entry.duration.end) -
                        yFraction(placement.entry.duration.start)),
                child: GridEntryWidget(
                  entry: placement.entry,
                  fontSize: fontSize,
                ),
              ),
          ],
        );
      },
    );
  }
}

@visibleForTesting
class GridEntryPlacement {
  final GridEntry entry;
  final int column;
  final int columnCount;
  final int columnSpan;

  GridEntryPlacement({
    required this.entry,
    required this.column,
    required this.columnCount,
    required this.columnSpan,
  });
}

bool _collides(GridEntry a, GridEntry b) =>
    a.duration.start.isBefore(b.duration.end) &&
    b.duration.start.isBefore(a.duration.end);

/// The layout algorithm: entries are sorted by start/end time, split into independent
/// blocks wherever a gap opens up in time, greedily assigned within a block to the
/// first column whose last entry doesn't collide with them, and finally expanded
/// rightward into any empty adjacent columns they don't collide with — so a course
/// sitting next to a hidden one's freed-up column actually widens rather than leaving a
/// gap. Exposed (rather than private) so the pure packing logic can be unit-tested
/// without pumping a widget tree.
@visibleForTesting
List<GridEntryPlacement> packGridEntries(List<GridEntry> entries) {
  var sorted = [...entries]
    ..sort((a, b) {
      var startCompare = a.duration.start.compareTo(b.duration.start);
      if (startCompare != 0) {
        return startCompare;
      }
      return a.duration.end.compareTo(b.duration.end);
    });

  var placements = <GridEntryPlacement>[];
  var block = <List<GridEntry>>[];
  DateTime? blockEnd;

  void flushBlock() {
    if (block.isEmpty) {
      return;
    }
    for (var column = 0; column < block.length; column++) {
      for (var entry in block[column]) {
        var span = 1;
        for (var next = column + 1; next < block.length; next++) {
          if (block[next].any((other) => _collides(other, entry))) {
            break;
          }
          span++;
        }
        placements.add(
          GridEntryPlacement(
            entry: entry,
            column: column,
            columnCount: block.length,
            columnSpan: span,
          ),
        );
      }
    }
    block = [];
  }

  for (var entry in sorted) {
    if (blockEnd != null && entry.duration.start.isAfter(blockEnd)) {
      flushBlock();
      blockEnd = null;
    }

    var placed = false;
    for (var column in block) {
      if (!_collides(column.last, entry)) {
        column.add(entry);
        placed = true;
        break;
      }
    }
    if (!placed) {
      block.add([entry]);
    }

    if (blockEnd == null || entry.duration.end.isAfter(blockEnd)) {
      blockEnd = entry.duration.end;
    }
  }
  flushBlock();

  return placements;
}
