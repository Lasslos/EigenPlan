import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/shared_preferences.dart';

part 'cached_messages.g.dart';

@Riverpod(keepAlive: true)
class CachedMessages extends _$CachedMessages {
  @override
  Messages build(UntisSession activeSession) {
    assert(activeSession is ActiveUntisSession, "Session must be active");
    ActiveUntisSession session = activeSession as ActiveUntisSession;
    if (!sharedPreferences.containsKey("${session.userData.id}.messages")) {
      return const Messages(incomingMessages: [], readConfirmationMessages: []);
    }
    return Messages.fromJson(
      jsonDecode(sharedPreferences.getString("${session.userData.id}.messages")!),
    );
  }

  Future<void> setCachedMessages(Messages messages) async {
    await sharedPreferences.setString(
      "${(activeSession as ActiveUntisSession).userData.id}.messages",
      jsonEncode(messages.toJson()),
    );
    state = messages;
  }
}
