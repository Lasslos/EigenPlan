import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/util/shared_preferences.dart';

part 'grid_cell_height_provider.g.dart';

@riverpod
class GridCellHeightSetting extends _$GridCellHeightSetting {
  @override
  int build() {
    int gridCellHeight = sharedPreferences.getInt('gridCellHeight') ?? 82;
    return gridCellHeight;
  }

  Future<void> setGridCellHeight(int gridCellHeight) async {
    state = gridCellHeight;
    await sharedPreferences.setInt('gridCellHeight', gridCellHeight);
  }
}
