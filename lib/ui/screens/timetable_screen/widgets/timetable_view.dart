import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:your_schedule/core/provider/selected_timetable_resource_provider.dart';
import 'package:your_schedule/core/provider/timetable_provider.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/settings/view_mode_provider.dart';
import 'package:your_schedule/ui/screens/timetable_screen/timetable_screen_date_provider.dart';
import 'package:your_schedule/ui/screens/timetable_screen/widgets/day_view.dart';
import 'package:your_schedule/ui/screens/timetable_screen/widgets/timegrid_widget.dart';
import 'package:your_schedule/ui/screens/timetable_screen/widgets/week_view.dart';
import 'package:your_schedule/utils.dart';

class TimeTableView extends ConsumerWidget {
  const TimeTableView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ViewMode viewMode = ref.watch(viewModeSettingProvider);
    Date date = ref.watch(timetableScreenDateProvider);
    // Eager initialization of the time table providers
    var session = ref.watch(selectedUntisSessionProvider);
    var resource = ref.watch(effectiveTimetableResourceProvider(session));
    if (resource == null) {
      // No timetable resource at all for this session (e.g. some anonymous
      // accounts) — nothing to fetch or display.
      return const SizedBox.shrink();
    }
    DateTime timestamp = ref.watch(
      cachedTimeTableTimestampProvider(session, Week.fromDate(date), resource),
    );
    ref
      ..watch(timeTableProvider(session, Week.fromDate(date), resource))
      ..watch(
        timeTableProvider(session, Week.fromDate(date.addWeeks(1)), resource),
      )
      ..watch(
        timeTableProvider(session, Week.fromDate(date.addWeeks(-1)), resource),
      );

    return RefreshIndicator(
      onRefresh: () async {
        var session = ref.read(selectedUntisSessionProvider);
        ref.invalidate(
          requestTimetableEntriesProvider(
            session,
            Week.fromDate(date),
            resource,
          ),
        );
        await ref.read(
          requestTimetableEntriesProvider(
            session,
            Week.fromDate(date),
            resource,
          ).future,
        );
      },
      child: SafeArea(
        child: TimeGridWidget(
          footer: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8, right: 16, top: 8),
              child: Text(
                'Zuletzt aktualisiert am ${DateFormat.Md().format(timestamp)} um ${DateFormat.Hms().format(timestamp)}.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: viewMode == ViewMode.day
                ? const DayView()
                : const WeekView(),
          ),
        ),
      ),
    );
  }
}
