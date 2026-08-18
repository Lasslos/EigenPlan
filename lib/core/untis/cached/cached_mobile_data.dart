import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/shared_preferences.dart';

part 'cached_mobile_data.g.dart';

/// Unlike most `cached*` providers, [MobileData] has no honest "empty" default value
/// (`Tenant` is required) — state is nullable instead, `null` meaning "never fetched".
@Riverpod(keepAlive: true)
class CachedMobileData extends _$CachedMobileData {
  @override
  MobileData? build(UntisSession activeSession) {
    assert(activeSession is ActiveUntisSession, 'Session must be active');
    ActiveUntisSession session = activeSession as ActiveUntisSession;
    if (!sharedPreferences.containsKey('${session.userData.id}.mobileData')) {
      return null;
    }
    return MobileData.fromJson(
      jsonDecode(
        sharedPreferences.getString('${session.userData.id}.mobileData')!,
      ),
    );
  }

  Future<void> setCachedMobileData(MobileData data) async {
    await sharedPreferences.setString(
      '${(activeSession as ActiveUntisSession).userData.id}.mobileData',
      jsonEncode(data.toJson()),
    );
    state = data;
  }
}
