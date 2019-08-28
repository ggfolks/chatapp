import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'data.dart';
import 'stores.dart';
import 'message_view.dart';

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

  final DateTime now;
  final DateTime today;
  final DateTime yesterday;

  String format (DateTime date) {
    return (today.isBefore(date) ? "Today" :
            (yesterday.isBefore(date) ? "Yesterday" :
             (today.year == date.year ? monthDayFmt.format(date) :
              yearMonthDayFmt.format(date))));
  }
}

bool sameDate (DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class DateHeader extends StatelessWidget {
  const DateHeader ([this.date]);

  final String date;

  @override
  Widget build (BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
      child: Row(
        children: [
          Text(date, style: Theme.of(ctx).textTheme.title)
        ],
      )
    );
  }
}

bool shouldAggregate (Message earlier, Message later) {
  return (earlier.authorId == later.authorId &&
          later.sentTime.difference(earlier.sentTime).inMinutes < 5);
}

class ChannelPage extends StatelessWidget {
  const ChannelPage ([this.profiles, this.channel]);

  final ProfilesStore profiles;
  final ChannelStore channel;

  @override
  Widget build (BuildContext ctx) {
    // TODO: fetch messages on demand, infini-scroll through them...
    final List<Message> messages = List.from(channel.messages.values)
                                       ..sort((a, b) => a.sentTime.compareTo(b.sentTime));
    final rows = List();

    // intersperse date headers (Today, Yesterday, then Month, Day, Year localized)
    List<Message> row = null;
    if (messages.length > 0) {
      DateTime headerTime = null;
      for (var ii = 1; ii < messages.length; ii += 1) {
        final msg = messages[ii];
        if (headerTime == null || !sameDate(headerTime, msg.sentTime)) {
          headerTime = msg.sentTime;
          rows.add(headerTime);
          row = null;
        }
        if (row == null || !shouldAggregate(row.last, msg)) {
          row = List();
          rows.add(row);
        }
        row.add(msg);
      }
    }

    final formatter = new RelativeDateFormatter();

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(),
      child: Observer(
        builder: (ctx) => ListView.builder(
          itemCount: rows.length,
          itemBuilder: (ctx, index) {
            final row = rows[index];
            return (row is DateTime) ? DateHeader(formatter.format(row)) :
              MessageView(profiles, row);
          }
        )
      )
    );
  }
}
