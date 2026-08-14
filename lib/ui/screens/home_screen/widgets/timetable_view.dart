import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:your_schedule/core/provider/timetable_provider.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/settings/view_mode_provider.dart';
import 'package:your_schedule/ui/screens/home_screen/home_screen_date_provider.dart';
import 'package:your_schedule/ui/screens/home_screen/widgets/day_view.dart';
import 'package:your_schedule/ui/screens/home_screen/widgets/timegrid_widget.dart';
import 'package:your_schedule/ui/screens/home_screen/widgets/week_view.dart';
import 'package:your_schedule/utils.dart';

class TimeTableView extends ConsumerWidget {
  const TimeTableView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ViewMode viewMode = ref.watch(viewModeSettingProvider);
    Date date = ref.watch(homeScreenDateProvider);
    DateTime timestamp = ref.watch(cachedTimeTableTimestampProvider(Week.fromDate(date)));
    // Eager initialization of the time table providers
    var session = ref.watch(selectedUntisSessionProvider);
    ref
      ..watch(timeTableProvider(session, Week.fromDate(date)))
      ..watch(timeTableProvider(session, Week.fromDate(date.addWeeks(1))))
      ..watch(timeTableProvider(session, Week.fromDate(date.addWeeks(-1))));

    return RefreshIndicator(
      onRefresh: () async {
        var session = ref.read(selectedUntisSessionProvider);
        ref.invalidate(requestTimeTableProvider(session, Week.fromDate(date)));
        await ref.read(requestTimeTableProvider(session, Week.fromDate(date)).future);
      },
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: TimeGridWidget(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: viewMode == ViewMode.day ? const DayView() : const WeekView(),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16, right: 16, top: 8),
                child: Text(
                  'Zuletzt aktualisiert am ${DateFormat.Md().format(timestamp)} um ${DateFormat.Hms().format(timestamp)}.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
