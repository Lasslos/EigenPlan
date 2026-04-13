import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/provider/connectivity_provider.dart';
import 'package:your_schedule/core/untis.dart';

part 'messages_provider.g.dart';

@Riverpod(keepAlive: true)
class InboxMessages extends _$InboxMessages {
  @override
  Messages build(UntisSession session) {
    assert(session is ActiveUntisSession, "Session must be active");
    if (ref.watch(canMakeRequestProvider)) {
      var messages = ref.watch(requestMessagesProvider(session));
      if (messages.hasValue) {
        return messages.requireValue;
      }
    }
    return ref.watch(cachedMessagesProvider(session));
  }
}
