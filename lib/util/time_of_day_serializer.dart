import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

class TimeOfDaySerializer implements JsonConverter<TimeOfDay, String> {
  const TimeOfDaySerializer();

  @override
  TimeOfDay fromJson(String json) {
    var time = json.substring(1).split(':');
    return TimeOfDay(
      hour: int.parse(time[0]),
      minute: int.parse(time[1]),
    );
  }

  @override
  String toJson(TimeOfDay object) {
    return 'T${object.hour}:${object.minute}';
  }
}
