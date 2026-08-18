import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:your_schedule/core/provider/filters.dart';
import 'package:your_schedule/core/provider/selected_timetable_resource_provider.dart';
import 'package:your_schedule/core/provider/timetable_provider.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/settings/view_mode_provider.dart';
import 'package:your_schedule/ui/screens/home_screen/home_screen_date_provider.dart';
import 'package:your_schedule/ui/screens/home_screen/widgets/grid_entry_layout.dart';
import 'package:your_schedule/ui/screens/home_screen/widgets/time_indicator.dart';
import 'package:your_schedule/utils.dart';

class DayView extends ConsumerStatefulWidget {
  const DayView({super.key});

  @override
  ConsumerState<DayView> createState() => _DayViewState();
}

class _DayViewState extends ConsumerState<DayView> {
  late PageController _pageController;
  late Date currentDate;

  @override
  void initState() {
    super.initState();
    currentDate = ref.read(homeScreenDateProvider);
    var index = _dateToIndex(currentDate);
    _pageController = PageController(initialPage: index);
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Date>(homeScreenDateProvider, (previous, next) {
      if (currentDate != next) {
        _pageController.animateToPage(
          _dateToIndex(next),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      }
    });

    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        currentDate = _indexToDate(index);
        if (currentDate != ref.read(homeScreenDateProvider)) {
          ref.read(homeScreenDateProvider.notifier).date = currentDate;
        }
      },
      itemBuilder: (BuildContext context, int index) => _Page(index: index),
    );
  }
}

class _Page extends ConsumerWidget {
  final int index;

  const _Page({required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Date currentDate = _indexToDate(index);

    var session = ref.watch(selectedUntisSessionProvider) as ActiveUntisSession;
    var resource = ref.watch(effectiveTimetableResourceProvider(session));
    var timetableDay = resource == null
        ? null
        : ref.watch(
            timeTableProvider(session, Week.fromDate(currentDate), resource),
          )[currentDate];
    var overrides = resource == null
        ? const <String, bool>{}
        : ref.watch(courseOverridesForResourceProvider(resource));

    return Center(
      child: Column(
        children: [
          SizedBox(
            height: 42,
            child: InkWell(
              onTap: () {
                ref.read(viewModeSettingProvider.notifier).switchViewMode();
              },
              child: Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: currentDate.format(DateFormat('EEEE\n')),
                    style: Theme.of(context).textTheme.bodyLarge,
                    children: [
                      TextSpan(
                        text: currentDate.format(DateFormat('d. MMMM')),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                GridEntryLayout(
                  fontSize: 12,
                  entries: (timetableDay?.gridEntries ?? []).where((entry) {
                    var courseKey = entry.courseKey;
                    return courseKey == null || (overrides[courseKey] ?? true);
                  }).toList(),
                ),
                if (index == _dateToIndex(Date.now())) const TimeIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//To allow backwards scrolling, today's index is set to 1 << 30 (Max int32 value / 2)
int _dateToIndex(Date date) {
  return date.differenceInDays(Date.now()) + (1 << 30);
}

Date _indexToDate(int index) {
  return Date.now().addDays(index - (1 << 30));
}
