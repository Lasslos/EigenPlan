import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/utils.dart';

class TimeGridWidget extends ConsumerStatefulWidget {
  const TimeGridWidget({
    required this.child,
    this.footer,
    super.key,
  });

  final Widget child;

  /// An optional widget placed after the time-grid/[child] row, inside the same
  /// [SingleChildScrollView] — it scrolls together with the grid instead of being a
  /// fixed overlay, and sits below the fixed-height grid row rather than sharing its
  /// height budget, so it can never compress/overlap the periods near the end of the day.
  final Widget? footer;

  @override
  ConsumerState<TimeGridWidget> createState() => _TimeGridWidgetState();
}

class _TimeGridWidgetState extends ConsumerState<TimeGridWidget> {
  @override
  Widget build(BuildContext context) {
    var timeGrid = ref.watch(
      selectedUntisSessionProvider.select((value) => (value as ActiveUntisSession).userData.timeGrid),
    );
    TimeOfDay startTime = timeGrid.first.startTime;
    TimeOfDay endTime = timeGrid.last.endTime;
    Duration dayDuration = endTime.difference(startTime);

    Duration medianClassDuration = (timeGrid
        .map((e) => e.length)
        .toList()
        ..sort())[timeGrid.length ~/ 2];

    // One class duration should be 82 pixels.
    // The header is 42 pixels.

    double height = dayDuration.inMinutes / medianClassDuration.inMinutes * 82 + 42;
    height = max(150, height);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: height,
            child: Row(
              children: [
                Column(
                  children: [
                    const SizedBox(height: 42),
                    Expanded(
                      child: _buildTimeGridWidget(context),
                    ),
                  ],
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 0.7,
                ),
                const SizedBox(width: 4),
                Expanded(child: widget.child),
                const SizedBox(width: 4),
              ],
            ),
          ),
          if (widget.footer != null) widget.footer!,
        ],
      ),
    );
  }

  Widget _buildTimeGridWidget(BuildContext context) {
    var timeGrid = ref.watch(
      selectedUntisSessionProvider.select((value) => (value as ActiveUntisSession).userData.timeGrid),
    );
    TimeOfDay startTime = timeGrid.first.startTime;
    TimeOfDay endTime = timeGrid.last.endTime;

    var firstDifference = startTime.difference(startTime).inMinutes;
    List<Widget> children = [
      if (firstDifference > 1)
        Spacer(
          flex: firstDifference,
        ),
    ];

    int timeGridLength = timeGrid.length;
    for (int i = 0; i < timeGridLength; i++) {
      var entry = timeGrid[i];
      TimeOfDay? nextStartTime =
          timeGridLength - 1 != i ? timeGrid[i + 1].startTime : null;
      int? difference = nextStartTime?.difference(entry.endTime).inMinutes;

      children.addAll([
        if (children.isEmpty || children.last.runtimeType != Divider)
          const Divider(
            thickness: 0.7,
            height: 1,
          ),
        Flexible(
          flex: entry.length.inMinutes,
          child: TimeGridColumnElement(entry: entry),
        ),
        const Divider(
          thickness: 0.7,
          height: 1,
        ),
      ]);

      if (difference != null && difference > 1) {
        children.addAll([
          Spacer(
            flex: difference,
          ),
        ]);
      } else if (difference != null && difference < 0) {
        getLogger().w(
          'Difference between consecutive period schedule entries is smaller than 0'
          ' (difference: $difference, entry: $entry, nextStartTime: $nextStartTime)',
        );
      }
    }

    var lastDifference = endTime.difference(timeGrid.last.endTime).inMinutes;
    if (lastDifference > 1) {
      children.add(
        Spacer(
          flex: lastDifference,
        ),
      );
    }

    return SizedBox(
      width: 50,
      child: Column(
        children: children,
      ),
    );
  }
}

class TimeGridColumnElement extends StatelessWidget {
  const TimeGridColumnElement({required this.entry, super.key});

  final TimeGridEntry entry;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 8),
                Text(
                  entry.startTime.toHHMM(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 8,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          Text(
            entry.label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.clip,
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Spacer(),
                Text(
                  entry.endTime.toHHMM(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 8,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
