import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:your_schedule/core/provider/filters.dart';
import 'package:your_schedule/core/provider/selected_timetable_resource_provider.dart';
import 'package:your_schedule/core/provider/timetable_provider.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/settings/view_mode_provider.dart';
import 'package:your_schedule/ui/screens/timetable_screen/timetable_screen_date_provider.dart';
import 'package:your_schedule/ui/screens/timetable_screen/widgets/grid_entry_layout.dart';
import 'package:your_schedule/ui/screens/timetable_screen/widgets/time_indicator.dart';
import 'package:your_schedule/utils.dart';

class WeekView extends ConsumerStatefulWidget {
  const WeekView({super.key});

  @override
  ConsumerState createState() => _WeekViewState();
}

class _WeekViewState extends ConsumerState<WeekView> {
  late PageController _pageController;
  late Date currentDate;

  @override
  void initState() {
    super.initState();
    currentDate = ref.read(timetableScreenDateProvider);
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
    ref.listen<Date>(timetableScreenDateProvider, (previous, next) {
      var normalizedCurrentDate = Week.fromDate(currentDate).startDate;
      var normalizedNext = Week.fromDate(next).startDate;
      if (normalizedCurrentDate != normalizedNext) {
        _pageController.animateToPage(
          _dateToIndex(normalizedNext),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      }
    });

    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        var oldDate = ref.read(timetableScreenDateProvider);
        var daysRelativeToStartOfWeek = oldDate.differenceInDays(
          Week.fromDate(oldDate).startDate,
        );
        currentDate = _indexToDate(index, daysRelativeToStartOfWeek);
        ref.read(timetableScreenDateProvider.notifier).date = currentDate;
      },
      itemBuilder: (BuildContext context, int index) {
        return _Page(index: index);
      },
    );
  }
}

class _Page extends ConsumerWidget {
  final int index;

  const _Page({required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Date currentDate = _indexToDate(index, 0);
    Week currentWeek = Week.fromDate(currentDate);
    List<List<GridEntry>> days = [];

    var session = ref.read(selectedUntisSessionProvider) as ActiveUntisSession;
    var resource = ref.watch(effectiveTimetableResourceProvider(session));
    var overrides = resource == null
        ? const <String, bool>{}
        : ref.watch(courseOverridesForResourceProvider(resource));
    var timeTable = resource == null
        ? <Date, TimetableDay>{}
        : ref.watch(
            timeTableProvider(session, Week.fromDate(currentDate), resource),
          );
    //Note: Week starts on Saturday to show next week after Friday
    for (var i = 2; i < 7; i++) {
      days.add(
        (timeTable[currentWeek.startDate.addDays(i)]?.gridEntries ?? []).where((
          entry,
        ) {
          var courseKey = entry.courseKey;
          return courseKey == null || (overrides[courseKey] ?? true);
        }).toList(),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 42,
          child: Row(
            children: [
              //Note: Week starts on Saturday to show next week after Friday
              for (var i = 2; i < 7; i++)
                Flexible(
                  child: InkWell(
                    onTap: () {
                      ref.read(timetableScreenDateProvider.notifier).date =
                          currentWeek.startDate.addDays(i);
                      ref
                          .read(viewModeSettingProvider.notifier)
                          .switchViewMode();
                    },
                    child: Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text: currentWeek.startDate
                              .addDays(i)
                              .format(DateFormat('E\n')),
                          style: Theme.of(context).textTheme.bodyLarge,
                          children: [
                            TextSpan(
                              text: currentWeek.startDate
                                  .addDays(i)
                                  .format(DateFormat('d. MMM')),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Row(
                children: List.generate(9, (index) {
                  if (index % 2 == 1) {
                    //Separator
                    return const SizedBox(width: 2);
                  }
                  return Flexible(
                    fit: FlexFit.tight,
                    child: GridEntryLayout(
                      fontSize: 12,
                      entries: days[index ~/ 2],
                    ),
                  );
                }),
              ),
              if (index == _dateToIndex(Date.now())) const TimeIndicator(),
            ],
          ),
        ),
      ],
    );
  }
}

//To allow backwards scrolling, today's index is set to 1 << 30 (Max int32 value / 2)
int _dateToIndex(Date date) {
  return (date.differenceInDays(Week.now().startDate) / 7.0).floor() +
      (1 << 30);
}

Date _indexToDate(int index, int daysRelativeToStartOfWeek) {
  return Week.now().startDate.addDays(
    (index - (1 << 30)) * 7 + daysRelativeToStartOfWeek,
  );
}
