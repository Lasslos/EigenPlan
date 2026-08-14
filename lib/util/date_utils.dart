import 'package:flutter/material.dart';
import 'package:your_schedule/util/date.dart';

extension DateUtils on DateTime {
  Date normalized() => Date(this);
}

extension DateUtilsOnString on String {
  DateTime convertUntisDateToDateTime() => DateTime.parse(this);
}

extension TimeOfDayUtils on TimeOfDay {
  Duration difference(TimeOfDay other) {
    return Duration(
      seconds: differenceToMidnight().inSeconds -
          other.differenceToMidnight().inSeconds,
    );
  }

  Duration differenceToMidnight() {
    return Duration(
      hours: hour,
      minutes: minute,
    );
  }

  String toHHMM() => '$hour:$minute';
}
