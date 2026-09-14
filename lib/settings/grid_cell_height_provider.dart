import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/util/shared_preferences.dart';

part 'grid_cell_height_provider.g.dart';

/// Height in logical pixels of one median-length period in the timetable grid — see
/// `timegrid_widget.dart`, where every other period is scaled off this value.
const int gridCellHeightDefault = 82;

/// The bounds are deliberately wide: at the minimum a period is a bare colored sliver
/// with its text clipped away — useful for taking in a whole week at a glance — and at
/// the maximum barely two periods fit on a phone screen. Both are enforced on read
/// *and* write, so a value persisted by an older build is repaired rather than carried
/// forward.
const int gridCellHeightMin = 30;
const int gridCellHeightMax = 200;

@riverpod
class GridCellHeightSetting extends _$GridCellHeightSetting {
  @override
  int build() =>
      _clamp(sharedPreferences.getInt('gridCellHeight') ?? gridCellHeightDefault);

  Future<void> setGridCellHeight(int gridCellHeight) async {
    int value = _clamp(gridCellHeight);
    state = value;
    await sharedPreferences.setInt('gridCellHeight', value);
  }

  static int _clamp(int value) =>
      value.clamp(gridCellHeightMin, gridCellHeightMax);
}
