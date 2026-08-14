import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:your_schedule/settings/view_mode_provider.dart';
import 'package:your_schedule/ui/screens/home_screen/home_screen_date_provider.dart';
import 'package:your_schedule/ui/screens/home_screen/widgets/timetable_view.dart';
import 'package:your_schedule/ui/shared/my_drawer.dart';
import 'package:your_schedule/utils.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var viewMode = ref.watch(viewModeSettingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EigenPlan'),
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
