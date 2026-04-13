import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/shared_preferences.dart';

part 'cached_specified_message.g.dart';

@Riverpod(keepAlive: true)
class CachedSpecifiedMessage extends _$CachedSpecifiedMessage {
  @override
  SpecifiedMessage? build(UntisSession activeSession, int messageId) {
    assert(activeSession is ActiveUntisSession, "Session must be active");
    ActiveUntisSession session = activeSession as ActiveUntisSession;
    if (!sharedPreferences.containsKey("${session.userData.id}.message.$messageId")) {
      return null;
    }
    return SpecifiedMessage.fromJson(
      jsonDecode(sharedPreferences.getString("${session.userData.id}.message.$messageId")!),
    );
  }

  Future<void> setCachedSpecifiedMessage(SpecifiedMessage message) async {
    await sharedPreferences.setString(
      "${(activeSession as ActiveUntisSession).userData.id}.message.$messageId",
      jsonEncode(message.toJson()),
    );
    state = message;
  }
}
