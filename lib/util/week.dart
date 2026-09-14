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

  /// [relative] weeks from whichever week [reference] falls in — the same thing as
  /// [Week.relative], but anchored on a date the caller controls. Widgets use this with
  /// `todayProvider` so that week-keyed providers follow the date over midnight instead of
  /// staying pinned to whenever the widget last rebuilt.
  Week.relativeTo(Date reference, int relative) : this.fromDate(reference.addWeeks(relative));

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
