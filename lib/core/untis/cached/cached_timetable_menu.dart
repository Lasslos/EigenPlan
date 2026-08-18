import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/shared_preferences.dart';

part 'cached_timetable_menu.g.dart';

/// Unlike most `cached*` providers, [TimetableMenuResponse] has no honest "empty"
/// default value (`myTimetable` is required) — state is nullable instead, `null`
/// meaning "never fetched" (not to be confused with a confirmed 404 "no menu for
/// this account", which the live request layer also represents as `null` but never
/// persists here — nothing to cache in that case).
@Riverpod(keepAlive: true)
class CachedTimetableMenu extends _$CachedTimetableMenu {
  @override
  TimetableMenuResponse? build(UntisSession activeSession) {
    assert(activeSession is ActiveUntisSession, 'Session must be active');
    ActiveUntisSession session = activeSession as ActiveUntisSession;
    final json = sharedPreferences.getString(
      '${session.userData.id}.timetableMenu',
    );
    if (json == null) {
      return null;
    }
    return TimetableMenuResponse.fromJson(
      jsonDecode(json) as Map<String, dynamic>,
    );
  }

  Future<void> setCachedTimetableMenu(TimetableMenuResponse? data) async {
    ActiveUntisSession session = activeSession as ActiveUntisSession;
    if (data == null) {
      await sharedPreferences.remove('${session.userData.id}.timetableMenu');
      state = null;
      return;
    }
    await sharedPreferences.setString(
      '${session.userData.id}.timetableMenu',
      jsonEncode(data.toJson()),
    );
    state = data;
  }
}
