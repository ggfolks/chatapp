import 'package:intl/intl.dart';

class RelativeDateFormatter {

  factory RelativeDateFormatter () {
    final now = DateTime.now();
    final today = now.subtract(new Duration(hours: now.hour, minutes: now.minute,
                                            seconds: now.second, milliseconds: now.millisecond,
                                            microseconds: now.microsecond));
    final yesterday = today.subtract(new Duration(days: 1));
    return RelativeDateFormatter._(now, today, yesterday);
  }

  RelativeDateFormatter._ ([this.now, this.today, this.yesterday]);

  final yearMonthDayFmt = new DateFormat.yMMMd();
  final monthDayFmt = new DateFormat.MMMd();
  final hourMinFmt = new DateFormat.jm();

  final DateTime now;
  final DateTime today;
  final DateTime yesterday;

  String formatHeader (DateTime date) {
    return (today.isBefore(date) ? "Today" :
            (yesterday.isBefore(date) ? "Yesterday" :
             (today.year == date.year ? monthDayFmt.format(date) :
              yearMonthDayFmt.format(date))));
  }

  String formatLatest (DateTime date) {
    // TODO: could do days of week for the past week... fiddly
    return today.isBefore(date) ? hourMinFmt.format(date) : monthDayFmt.format(date);
  }
}

bool sameDate (DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
