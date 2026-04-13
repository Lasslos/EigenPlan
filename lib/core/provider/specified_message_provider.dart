import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/provider/connectivity_provider.dart';
import 'package:your_schedule/core/untis.dart';

part 'specified_message_provider.g.dart';

@riverpod
class MessageDetail extends _$MessageDetail {
  @override
  SpecifiedMessage? build(UntisSession session, int messageId) {
    assert(session is ActiveUntisSession, "Session must be active");
    if (ref.watch(canMakeRequestProvider)) {
      var message = ref.watch(requestSpecifiedMessageProvider(session, messageId));
      if (message.hasValue) {
        return message.requireValue;
      }
    }
    return ref.watch(cachedSpecifiedMessageProvider(session, messageId));
  }
}
