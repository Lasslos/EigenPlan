import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:your_schedule/core/provider/custom_subject_colors.dart';
import 'package:your_schedule/custom_subject_color/custom_subject_color.dart';

/// A course/subject label rendered as a small, rounded, contrast-safe chip using the
/// user's custom color for [courseKey] (`customSubjectColorsProvider`, the same map
/// the timetable grid reads — see `grid_entry_widget.dart`), falling back to
/// [CustomSubjectColor.regularColor] when [courseKey] is `null` or has no override.
/// [style] lets callers keep their surrounding text style (e.g. `titleSmall`); only
/// the color is ever overridden, to guarantee readable contrast against the chip.
///
/// Wrapped in an [Align] so it never stretches to fill its parent's width — several
/// call sites (e.g. `ListTile.title`) hand their child a tight/bounded width, which a
/// plain [Text] doesn't visibly fill (no background) but a colored [Container] would.
class CourseChip extends ConsumerWidget {
  const CourseChip({
    required this.label,
    required this.courseKey,
    this.style,
    super.key,
  });

  final String label;
  final String? courseKey;
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = courseKey;
    final color = key == null
        ? CustomSubjectColor.regularColor
        : ref.watch(customSubjectColorsProvider)[key] ?? CustomSubjectColor.regularColor;

    return Align(
      widthFactor: 1,
      heightFactor: 1,
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        margin: const EdgeInsets.symmetric(vertical: 1),
        decoration: BoxDecoration(
          color: color.color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: (style ?? const TextStyle()).copyWith(color: color.textColor),
        ),
      ),
    );
  }
}
