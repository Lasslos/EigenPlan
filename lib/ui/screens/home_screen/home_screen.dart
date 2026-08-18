import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:your_schedule/core/provider/selected_timetable_resource_provider.dart';
import 'package:your_schedule/settings/view_mode_provider.dart';
import 'package:your_schedule/ui/screens/home_screen/home_screen_date_provider.dart';
import 'package:your_schedule/ui/screens/home_screen/widgets/timetable_view.dart';
import 'package:your_schedule/ui/screens/timetable_picker_screen/timetable_picker_screen.dart';
import 'package:your_schedule/ui/shared/my_drawer.dart';
import 'package:your_schedule/utils.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var viewMode = ref.watch(viewModeSettingProvider);
    var selectedResource = ref.watch(selectedTimetableResourceProvider);

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TimetablePickerScreen(),
              ),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  selectedResource?.displayName ?? 'EigenPlan',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              ref.read(homeScreenDateProvider.notifier).date = Date.now();
            },
            tooltip: 'Zur jetzigen Woche springen',
          ),
          IconButton(
            onPressed: () {
              ref.read(viewModeSettingProvider.notifier).switchViewMode();
            },
            icon: Icon((-viewMode).icon),
            tooltip: 'Zu ${(-viewMode).readableName} wechseln',
          ),
        ],
      ),
      drawer: const MyDrawer(),
      body: const TimeTableView(),
    );
  }
}
