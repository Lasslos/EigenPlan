import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/util/shared_preferences.dart';

part 'view_mode_provider.g.dart';

enum ViewMode {
  week('Wochenansicht', Icons.calendar_view_week),
  day('Tagesansicht', Icons.calendar_view_day);

  final String readableName;
  final IconData icon;

  const ViewMode(this.readableName, this.icon);

  ///Der gegenteilige ViewMode
  ViewMode operator -() {
    return ViewMode.values[(index - 1).abs()];
  }
}

@riverpod
class ViewModeSetting extends _$ViewModeSetting {
  @override
  ViewMode build() {
    int viewModeInt = sharedPreferences.getInt('viewMode') ?? 1;
    return ViewMode.values[viewModeInt];
  }

  Future<void> switchViewMode() async {
    state = -state;
    await sharedPreferences.setInt('viewMode', state.index);
  }
}
