import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/provider/connectivity_provider.dart';
import 'package:your_schedule/core/untis.dart';

part 'homework_provider.g.dart';

@riverpod
class HomeworkOverview extends _$HomeworkOverview {
  @override
  Homework build(UntisSession session) {
    assert(session is ActiveUntisSession, 'Session must be active');
    if (ref.watch(canMakeRequestProvider)) {
      var homework = ref.watch(requestHomeworkProvider(session));
      if (homework.hasValue) {
        return homework.requireValue;
      }
    }
    return ref.watch(cachedHomeworkProvider(session));
  }
}
