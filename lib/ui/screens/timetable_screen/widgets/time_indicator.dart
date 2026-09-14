import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:your_schedule/core/provider/clock_provider.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/date_utils.dart';

class TimeIndicator extends ConsumerWidget {
  const TimeIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var timeGrid = ref.watch(
      selectedUntisSessionProvider.select((value) => (value as ActiveUntisSession).userData.timeGrid),
    );
    // The line's position is computed in whole minutes, so the per-minute tick is all the
    // resolution it can show anyway — and it lands on the boundary rather than near it.
    TimeOfDay startTime = timeGrid.first.startTime;
    TimeOfDay endTime = timeGrid.last.endTime;
    TimeOfDay now = TimeOfDay.fromDateTime(ref.watch(currentMinuteProvider));

    double relativePosition;

    if (now.difference(startTime) < Duration.zero) {
      relativePosition = 0;
    } else if (now.difference(endTime) > Duration.zero) {
      relativePosition = 1;
    } else {
      relativePosition = now.difference(startTime).inMinutes /
          endTime.difference(startTime).inMinutes;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            if (relativePosition != 0)
              Spacer(
                flex: (relativePosition * constraints.maxHeight).floor(),
              ),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.black
                        : Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1.25,
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.black
                        : Colors.white,
                  ),
                ),
              ],
            ),
            if (relativePosition != 1)
              Spacer(
                flex: (constraints.maxHeight -
                        (relativePosition * constraints.maxHeight))
                    .floor(),
              ),
          ],
        );
      },
    );
  }
}
