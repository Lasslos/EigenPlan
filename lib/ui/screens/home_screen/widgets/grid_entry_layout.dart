import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/ui/screens/home_screen/widgets/grid_entry_widget.dart';

/// Lays out a day's [GridEntry]s using the server-computed
/// `layoutStartPosition`/`layoutWidth` (0-1000, fractions of the day column) and each
/// entry's own start/end time — no client-side collision/packing algorithm needed,
/// unlike the legacy `period_layout.dart` this replaces. See
/// `docs/api/spec/NOTES.md` §4.
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
      selectedUntisSessionProvider.select((value) => (value as ActiveUntisSession).userData.timeGrid),
    );
    var startOfDayMinutes = timeGrid.first.startTime.hour * 60 + timeGrid.first.startTime.minute;
    var endOfDayMinutes = timeGrid.last.endTime.hour * 60 + timeGrid.last.endTime.minute;
    var totalMinutes = endOfDayMinutes - startOfDayMinutes;

    double yFraction(DateTime time) => ((time.hour * 60 + time.minute) - startOfDayMinutes) / totalMinutes;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            for (var entry in entries)
              Positioned(
                left: constraints.maxWidth * entry.layoutStartPosition / 1000,
                width: constraints.maxWidth * entry.layoutWidth / 1000,
                top: constraints.maxHeight * yFraction(entry.duration.start),
                height: constraints.maxHeight * (yFraction(entry.duration.end) - yFraction(entry.duration.start)),
                child: GridEntryWidget(entry: entry, fontSize: fontSize),
              ),
          ],
        );
      },
    );
  }
}
