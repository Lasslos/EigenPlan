import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/provider/connectivity_provider.dart';
import 'package:your_schedule/core/provider/filters.dart';
import 'package:your_schedule/core/provider/selected_timetable_resource_provider.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/homework_visibility.dart';

part 'homework_provider.g.dart';

@riverpod
class HomeworkOverview extends _$HomeworkOverview {
  @override
  Homework build(UntisSession session) {
    assert(session is ActiveUntisSession, 'Session must be active');
    final activeSession = session as ActiveUntisSession;

    final Homework homework;
    if (ref.watch(canMakeRequestProvider)) {
      final requested = ref.watch(requestHomeworkProvider(session));
      homework = requested.hasValue ? requested.requireValue : ref.watch(cachedHomeworkProvider(session));
    } else {
      homework = ref.watch(cachedHomeworkProvider(session));
    }

    final resource = ref.watch(effectiveTimetableResourceProvider(session));
    final overrides = resource == null
        ? const <String, bool>{}
        : ref.watch(courseOverridesForResourceProvider(resource));

    return filterHomeworkByVisibility(homework, activeSession.userData, overrides);
  }
}
