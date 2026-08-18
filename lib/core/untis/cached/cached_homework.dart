import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/shared_preferences.dart';

part 'cached_homework.g.dart';

@Riverpod(keepAlive: true)
class CachedHomework extends _$CachedHomework {
  @override
  Homework build(UntisSession activeSession) {
    assert(activeSession is ActiveUntisSession, 'Session must be active');
    ActiveUntisSession session = activeSession as ActiveUntisSession;
    if (!sharedPreferences.containsKey('${session.userData.id}.homework')) {
      return const Homework([], {});
    }
    return Homework.fromJson(
      jsonDecode(
        sharedPreferences.getString('${session.userData.id}.homework')!,
      ),
    );
  }

  Future<void> setCachedHomework(Homework homework) async {
    await sharedPreferences.setString(
      '${(activeSession as ActiveUntisSession).userData.id}.homework',
      jsonEncode(homework.toJson()),
    );
    state = homework;
  }
}
