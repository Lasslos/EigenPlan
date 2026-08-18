import 'package:flutter/material.dart';
import 'package:your_schedule/ui/screens/dashboard_screen/dashboard_screen.dart';
import 'package:your_schedule/ui/screens/settings_screen/settings_screen.dart';
import 'package:your_schedule/ui/screens/timetable_screen/timetable_screen.dart';

/// The app's persistent shell — a bottom [NavigationBar] over three tabs. Each tab
/// keeps its own `Scaffold`/`AppBar` (nested `Scaffold`s are fine here); this outer
/// one only supplies the tab bar itself.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _tabs = <Widget>[
    DashboardScreen(),
    TimetableScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Start',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Stundenplan',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Einstellungen',
          ),
        ],
      ),
    );
  }
}
