import 'package:flutter/foundation.dart';
import 'package:your_schedule/util/date.dart';

/// Week starts on **saturday**, as the user is interested in the next week starting from saturday.
@immutable
class Week {
  final Date startDate;
  final Date endDate;

  ///Erstellt ein Wochenobjekt, das die Woche enthält, in der das übergebene Datum liegt
  Week.fromDate(Date momentInWeek)
      : startDate = momentInWeek.startOfWeek(),
        endDate = momentInWeek.endOfWeek();

  Week.now() : this.fromDate(Date.now());

  Week.relative(int relative)
      : startDate = Date.now().startOfWeek().addWeeks(relative),
        endDate = Date.now().endOfWeek().addWeeks(relative);

  List<Date> get daysInWeek => [for (int i = 0; i < 7; i++) startDate.addDays(i)];

  @override
  int get hashCode => Object.hash(startDate, endDate);

  @override
  bool operator ==(Object other) {
    if (other is! Week) {
      return false;
    }
    return startDate.isAtSameMomentAs(other.startDate) &&
        endDate.isAtSameMomentAs(other.endDate);
  }

  @override
  String toString() {
    return '${startDate.toString().substring(0, 10)} bis ${endDate.toString().substring(0, 10)}';
  }
}
