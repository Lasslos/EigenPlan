import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:your_schedule/utils.dart';

part 'timetable_screen_date_provider.g.dart';

@riverpod
class TimetableScreenDate extends _$TimetableScreenDate {
  @override
  Date build() {
    return Date.now();
  }

  set date(Date date) {
    state = date;
  }
}
