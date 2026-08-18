import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/provider/connectivity_provider.dart';
import 'package:your_schedule/core/untis.dart';

part 'timetable_menu_provider.g.dart';

@riverpod
class TimetableMenu extends _$TimetableMenu {
  @override
  TimetableMenuResponse? build(UntisSession session) {
    assert(session is ActiveUntisSession, 'Session must be active');
    if (ref.watch(canMakeRequestProvider)) {
      var menu = ref.watch(requestTimetableMenuProvider(session));
      if (menu.hasValue) {
        return menu.requireValue;
      }
    }
    return ref.watch(cachedTimetableMenuProvider(session));
  }
}
