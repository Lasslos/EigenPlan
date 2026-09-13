import 'package:intl/intl.dart';

class Date implements Comparable<Date> {
  final DateTime _date;

  int get year => _date.year;

  int get month => _date.month;

  int get day => _date.day;

  int get weekday => _date.weekday;

  Date(DateTime date) : _date = DateTime.utc(date.year, date.month, date.day);

  Date.raw(int year, int month, int day) : _date = DateTime.utc(year, month, day);

  Date.now() : this(DateTime.now());

  Date.fromMillisecondsSinceEpoch(int millisecondsSinceEpoch) : this(DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch));

  Date addDays(int days) => Date.raw(year, month, day + days);

  Date addWeeks(int weeks) => Date.raw(year, month, day + weeks * 7);

  Date subtractDays(int days) => Date.raw(year, month, day - days);

  Date subtractWeeks(int weeks) => Date.raw(year, month, day - weeks * 7);

  /// Week starts on **saturday**, as the user is interested in the next week starting from saturday.
  Date startOfWeek() => Date.raw(year, month, day - ((weekday - 6) % 7));

  /// Week starts on **saturday**, as the user is interested in the next week starting from saturday.
  Date endOfWeek() => Date.raw(year, month, day + (5 - weekday) % 7);

  /// leap-second safe difference in days
  int differenceInDays(Date other) {
    /// This is an extremely lazy solution to leap seconds. It just adds one hour to the difference, which is rounded down to the nearest day.
    /// It solves the problem as UTC is supposed to only have one leap second every 18 months, one hour is more than enough to cover one second.
    /// If we don't do this, in the event of a second being removed, the indexes of the days would be off by one, erasing a day.
    ///
    /// Assumptions for this to work:
    /// - .inDays always rounds down.
    Duration difference = _date.difference(other._date);
    if (difference.isNegative) {
      return (difference - const Duration(hours: 1)).inDays;
    } else {
      return (difference + const Duration(hours: 1)).inDays;
    }
  }

  bool isBefore(Date other) => _date.isBefore(other._date);

  int get millisecondsSinceEpoch => _date.millisecondsSinceEpoch;

  @override
  int get hashCode => Object.hash(year, month, day);

  bool isAtSameMomentAs(Date other) {
    return year == other.year && month == other.month && day == other.day;
  }

  @override
  bool operator ==(Object other) {
    if (other is! Date) {
      return false;
    }
    return isAtSameMomentAs(other);
  }

  @override
  int compareTo(Date other) {
    if (year != other.year) {
      return year - other.year;
    }
    if (month != other.month) {
      return month - other.month;
    }
    return day - other.day;
  }

  @override
  String toString() {
    return _date.toString();
  }

  String format(DateFormat format) {
    return format.format(_date);
  }
}

/// German relative-day wording for [date], which is [daysFromNow] days from today (as
/// returned by [Date.differenceInDays]) — "Heute"/"Morgen"/"In N Tagen" ahead,
/// "Gestern"/"Vor N Tagen" in the past, falling back to an absolute "dd.MM.yyyy" date
/// once [daysFromNow] is more than a week out in either direction (`date` is only used
/// for that fallback). The single source of this wording, used everywhere a date is
/// shown relative to today: homework/exam dashboard cards, the homework list, and the
/// exam list's day headers.
String relativeDayLabel(int daysFromNow, DateTime date) {
  return switch (daysFromNow) {
    0 => 'Heute',
    1 => 'Morgen',
    -1 => 'Gestern',
    > 1 && <= 7 => 'In $daysFromNow Tagen',
    < -1 && >= -7 => 'Vor ${-daysFromNow} Tagen',
    _ => DateFormat('dd.MM.yyyy').format(date),
  };
}
